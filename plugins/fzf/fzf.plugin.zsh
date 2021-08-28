
function setup_using_base_dir() {
  local _fzf_base_path _fzf_shell_path _fzf_disable_key_bindings _fzf_disable_auto_completion _brew_dir

  zstyle -s :ggz:plugins:fzf path _fzf_base_path
  zstyle -b :ggz:plugins:fzf disable_key_bindings _fzf_disable_key_bindings
  zstyle -b :ggz:plugins:fzf disable_auto_completion _fzf_disable_auto_completion

  if [[ -z "${_fzf_base_path}" ]] && (( ${+commands[brew]} )) && _brew_dir="$(brew --prefix fzf 2>/dev/null)"; then
    if [[ -d "${_brew_dir}" ]]; then
      _fzf_base_path="${_brew_dir}"
    fi
  fi

  if [[ -d "${_fzf_base_path}" ]]; then
    _fzf_shell_path="${_fzf_base_path}/shell"

    # Fix fzf shell directory for Arch Linux, NixOS or Void Linux packages
    if [[ ! -d "${_fzf_shell_path}" ]]; then
      _fzf_shell_path="${_fzf_base_path}"
    fi

    # Setup fzf binary path
    if ! (( ${+commands[fzf]} )) && [[ ! "$PATH" == *$_fzf_base_path/bin* ]]; then
      export PATH="$PATH:$_fzf_base_path/bin"
    fi


    # Key bindings
    if [[ ! "${_fzf_disable_key_bindings}" == yes ]]; then
      source "${_fzf_shell_path}/key-bindings.zsh"
    fi

    # Auto-completion
    if [[ ! "${_fzf_disable_auto_completion}" == yes ]]; then
      [[ $- == *i* ]] && source "${_fzf_shell_path}/completion.zsh" 2> /dev/null
    fi
  else
      return 1
  fi
}

function indicate_error() {
    print "[gigish] fzf plugin: Cannot find fzf installation directory.\n"\
          "Please add or fix \`zstyle :ggz:plugins:fzf path /path/to/fzf/install/dir\` in your .zshrc" >&2
}

# Indicate to user that fzf installation not found if nothing worked
setup_using_base_dir || indicate_error

unset -f setup_using_base_dir indicate_error

if (( $+commands[rg] )); then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs -g "!{node_modules,.git}"'
  export FZF_CTRL_T_COMMAND='rg --files --hidden --follow -g "!{node_modules,.git}"'
fi

export FZF_DEFAULT_OPTS='--height 96% --reverse'
export FZF_CTRL_T_OPTS="$FZF_DEFAULT_OPTS --preview \"cat {}\""
