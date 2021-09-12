# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# Return if requirements are not found.
if [[ "$TERM" == 'dumb' ]]; then
  return 1
fi

#
# Options
#

setopt BEEP                     # Beep on error in line editor.

#
# Variables
#

# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

#
# External Editor
#

# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line

#
# Custom widgets
#

# Expands .... to ../..
function expand-dots {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+='/..'
  else
    LBUFFER+='.'
  fi
}
zle -N expand-dots

# Prepend sudo
function prepend-sudo {
  if [[ $BUFFER != su(do|)\ * ]]; then
    BUFFER="sudo $BUFFER"
    (( CURSOR += 5))
  fi
}
zle -N prepend-sudo

#
# Bindings
#

bindkey -e

bindkey -s '^[OM'    '^M'
bindkey -s '^[Ok'    '+'
bindkey -s '^[Om'    '-'
bindkey -s '^[Oj'    '*'
bindkey -s '^[Oo'    '/'
bindkey -s '^[OX'    '='
bindkey -s '^[OH'    '^[[H'
bindkey -s '^[OF'    '^[[F'
bindkey -s '^[OA'    '^[[A'
bindkey -s '^[OB'    '^[[B'
bindkey -s '^[OD'    '^[[D'
bindkey -s '^[OC'    '^[[C'
bindkey -s '^[[1~'   '^[[H'
bindkey -s '^[[4~'   '^[[F'
bindkey -s '^[Od'    '^[[1;5D'
bindkey -s '^[Oc'    '^[[1;5C'
bindkey -s '^[^[[D'  '^[[1;3D'
bindkey -s '^[^[[C'  '^[[1;3C'
bindkey -s '^[[7~'   '^[[H'
bindkey -s '^[[8~'   '^[[F'
bindkey -s '^[[3\^'  '^[[3;5~'
bindkey -s '^[^[[3~' '^[[3;3~'
bindkey -s '^[[1;9D' '^[[1;3D'
bindkey -s '^[[1;9C' '^[[1;3C'

bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char
bindkey '^[[3;5~' kill-word
bindkey '^[[3;3~' kill-word
bindkey '^[k'     backward-kill-line
bindkey '^[K'     backward-kill-line
bindkey '^[j'     kill-buffer
bindkey '^[J'     kill-buffer
bindkey '^[/'     redo
bindkey '^[[1;3D' backward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[[1;5C' forward-word

bindkey '.' expand-dots
bindkey -M isearch '.' self-insert

bindkey '^X^E' edit-command-line

bindkey '^X^S' prepend-sudo
