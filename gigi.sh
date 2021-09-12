function check_requirements {
  # Check for the minimum supported version.
  local min_zsh_version='4.3.11'
  if ! autoload -Uz is-at-least || ! is-at-least "$min_zsh_version"; then
    printf "gigish: old shell detected, minimum required: %s\n" "$min_zsh_version" >&2
    return 1
  fi
}

function fix_smart_url {
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
}

function set_environment {
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
  unsetopt BG_NICE          # Don't run all background jobs at a lower priority.
  unsetopt HUP              # Don't kill jobs on shell exit.
  unsetopt CHECK_JOBS       # Don't report on jobs when shell exit.

  # delete all key bindings before load plugins and configurations
  bindkey -d
}

function load_plugins {
  local plugin

  # Load all of the plugins that were defined in ~/.zshrc
  for plugin ($plugins); do
    if [ -f $GIGISH/plugins/$plugin/$plugin.plugin.zsh ]; then
      source $GIGISH/plugins/$plugin/$plugin.plugin.zsh
    fi
  done
}

function load_configurations {
  local config_file

  # Load all of the config files in gigish lib directory that end in .zsh
  for config_file ($GIGISH/lib/*.zsh); do
    source $config_file
  done
}

function load_theme {
  # Add themes setup functions to fpath
  fpath+=${GIGISH}/themes

  # Load and execute the prompt theming system.
  autoload -Uz promptinit ; promptinit

  # Load the prompt theme.
  if [[ "$TERM" == (dumb|linux|*bsd*) ]] || [[ -z $PROMPT_THEME ]]; then
    echo 'prompt off'
    prompt 'off'
  else
    prompt "$PROMPT_THEME"
  fi
}

check_requirements \
  && fix_smart_url \
  && set_environment \
  && load_plugins \
  && load_configurations \
  && load_theme

unset -f \
  check_requirements \
  fix_smart_url \
  set_environment \
  load_plugins \
  load_configurations \
  load_theme
