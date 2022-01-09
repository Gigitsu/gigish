# Wrap everything in an anonymous function to keep local variables.
# This works for sources file as well.
# You still need to unset functions.

function() {
  #### Common functions ####
  __style_log() {
    [ $# -gt 0 ] || return
    IFS=";" printf "\033[%sm" $*
  }

  __mark_log() {
    echo $@ | sed 's/^/[gigish] /'
  }

  debug() {
    printf "$(__style_log 34)$(__mark_log $1)$(__style_log 0)\n" "${@:2}" >&2
  }

  info() {
    printf "$(__mark_log $1)\n" "${@:2}" >&2
  }

  warn() {
    printf "$(__style_log 33)$(__mark_log $1)$(__style_log 0)\n" "${@:2}" >&2
  }

  error() {
    printf "$(__style_log 31)$(__mark_log $1)$(__style_log 0)\n" "${@:2}" >&2
  }

  die() {
    error "$@"; exit 1
  }

  # Check for the minimum supported version.
  local min_zsh_version='4.3.11'
  if ! autoload -Uz is-at-least || ! is-at-least "$min_zsh_version"; then
    die "Old shell detected, minimum required version: %s" "$min_zsh_version"
  fi

  # This logic comes from an old version of zim. Essentially, bracketed-paste was
  # added as a requirement of url-quote-magic in 5.1, but in 5.1.1 bracketed
  # paste had a regression. Additionally, 5.2 added bracketed-paste-url-magic
  # which is generally better than url-quote-magic so we load that when possible.
  autoload -Uz is-at-least
  if [[ ${ZSH_VERSION} != 5.1.1 && ${TERM} != "dumb" ]]; then
    if is-at-least 5.2; then
      autoload -Uz bracketed-paste-url-magic
      zle -N bracketed-paste bracketed-paste-url-magic
    elif is-at-least 5.1; then
      autoload -Uz bracketed-paste-magic
      zle -N bracketed-paste bracketed-paste-magic
    fi
    autoload -Uz url-quote-magic
    zle -N self-insert url-quote-magic
  fi

  # If GIGISH is not defined, use the current script's directory.
  [[ -z "$GIGISH" ]] && export GIGISH="${${(%):-%x}:a:h}"

  CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/gigish"

  # Figure out the SHORT hostname
  if [[ "$OSTYPE" = darwin* ]]; then
    # macOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
    SHORT_HOST="$(scutil --get ComputerName 2>/dev/null)" || SHORT_HOST="${HOST/.*/}"
  else
    SHORT_HOST="${HOST/.*/}"
  fi

  if zstyle -t ':ggz:environment:termcap' color; then
    export LESS_TERMCAP_mb=$'\E[01;31m'      # Begins blinking.
    export LESS_TERMCAP_md=$'\E[01;31m'      # Begins bold.
    export LESS_TERMCAP_me=$'\E[0m'          # Ends mode.
    export LESS_TERMCAP_se=$'\E[0m'          # Ends standout-mode.
    export LESS_TERMCAP_so=$'\E[00;47;30m'   # Begins standout-mode.
    export LESS_TERMCAP_ue=$'\E[0m'          # Ends underline.
    export LESS_TERMCAP_us=$'\E[01;32m'      # Begins underline.
  fi

  setopt COMBINING_CHARS      # Combine zero-length punctuation characters (accents)
                              # with the base character.
  setopt INTERACTIVE_COMMENTS # Enable comments in interactive shell.
  setopt RC_QUOTES            # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.
  unsetopt MAIL_WARNING       # Don't print a warning message if a mail file has been accessed.

  # Allow mapping Ctrl+S and Ctrl+Q shortcuts
  [[ -r ${TTY:-} && -w ${TTY:-} && $+commands[stty] == 1 ]] && stty -ixon <$TTY >$TTY

  setopt LONG_LIST_JOBS     # List jobs in the long format by default.
  setopt AUTO_RESUME        # Attempt to resume existing job before creating a new process.
  setopt NOTIFY             # Report status of background jobs immediately.
  unsetopt HUP              # Don't kill jobs on shell exit.
  unsetopt BG_NICE          # Don't run all background jobs at a lower priority.
  unsetopt CHECK_JOBS       # Don't report on jobs when shell exit.

  # delete all key bindings before load plugins and configurations
  bindkey -d

  # Load all of the plugins that were defined in ~/.zshrc
  local plugin
  for plugin ($plugins); do
    if [ -f $GIGISH/plugins/$plugin/$plugin.plugin.zsh ]; then
      source $GIGISH/plugins/$plugin/$plugin.plugin.zsh
    fi
  done

  # Load all of the config files in gigish lib directory that end in .zsh
  local config_file
  for config_file ($GIGISH/lib/*.zsh); do
    source $config_file
  done

  # Add themes setup functions to fpath
  fpath+=${GIGISH}/themes

  # Load and execute the prompt theming system.
  autoload -Uz promptinit ; promptinit

  # Load the prompt theme.
  if [[ "$TERM" == (dumb|linux|*bsd*) ]] || [[ -z $PROMPT_THEME ]]; then
    warn 'Terminal does not support theming or no theme is specified'
    warn 'To disable this message set theme to "off"'
    prompt 'off'
  else
    prompt "$PROMPT_THEME"
  fi

  unset -f __style_log __mark_log debug info warn error die
}
