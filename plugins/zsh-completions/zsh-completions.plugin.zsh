function setup_using_base_dir() {
  local _zsh_completions_path _brew_dir

  zstyle -s :ggz:plugins:zsh_completions path _zsh_completions_path

  if [[ -z "${_zsh_completions_path}" ]] && (( ${+commands[brew]} )) && _brew_dir="$(brew --prefix zsh-completions 2>/dev/null)"; then
    if [[ -d "${_brew_dir}" ]]; then
      _zsh_completions_path="${_brew_dir}/share/zsh-completions"
    fi
  fi

  if [[ ! -d "${_zsh_completions_path}" ]]; then
    return 1
  fi

  # Setup zsh-completions functions directory
  fpath+=$_zsh_completions_path
}

function indicate_error() {
  print "[gigish] zsh-completions plugin: Cannot find zsh-completions installation directory.\n" \
        "Please add or fix \`zstyle :ggz:plugins:zsh_completions path /path/to/zsh-completions/install/dir\` in your .zshrc" >&2
}

# Indicate to user that zsh-completions installation not found if nothing worked
setup_using_base_dir || indicate_error

unset -f setup_using_base_dir indicate_error
