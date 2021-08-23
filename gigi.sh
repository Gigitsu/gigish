
# Check for the minimum supported version.
min_zsh_version='4.3.11'
if ! autoload -Uz is-at-least || ! is-at-least "$min_zsh_version"; then
  printf "gigish: old shell detected, minimum required: %s\n" "$min_zsh_version" >&2
  return 1
fi
unset min_zsh_version

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

# Load all of the plugins that were defined in ~/.zshrc
for plugin ($plugins); do
  if [ -f $GIGISH/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $GIGISH/plugins/$plugin/$plugin.plugin.zsh
  fi
done
unset plugin

# Load all of the config files in gigish lib directory that end in .zsh
for config_file ($GIGISH/lib/*.zsh); do
  source $config_file
done
unset config_file

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
