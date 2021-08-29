def setup() {
  # check if fasd is installed
  if (( ! ${+commands[fasd]} )); then
    return 1
  fi

  local _fasd_cache_path="${CACHE_HOME}/fasd-init-cache-${SHORT_HOST}-${ZSH_VERSION}.zsh"

  if [[ "$commands[fasd]" -nt "$_fasd_cache_path" || ! -s "$_fasd_cache_path" ]]; then
    fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install >| "$_fasd_cache_path"
  fi

  source "$_fasd_cache_path"

  if (( $+commands[fzf] )); then
    jj() {
      local _jump_dir
      _jump_dir="$(fasd -Rdl "$1" | fzf -1 -0 --no-sort +m)" && cd "${_jump_dir}" || return 1
    }
  else
    alias jj='zz'
  fi

  alias v='f -e "$EDITOR"'
  alias o='a -e xdg-open'
  alias j='z'
}

def indicate_error() {
  print "[gigish] fasd command not found, install it or disable fasd plugin" >&2
}

setup || indicate_error

unset -f setup indicate_error
