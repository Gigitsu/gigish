#
# Sets history options and defines history aliases.
#
# Authors:
#   Gigitsu <luigi.clemente@gsquare.it>
#

#
# Functions
#

function ggz_history {
  local clear list
  zparseopts -E c=clear l=list

  if [[ -n "$clear" ]]; then
    # if -c provided, clobber the history file
    echo -n >| "$HISTFILE"
    fc -p "$HISTFILE"
    echo >&2 History file deleted.
  elif [[ -n "$list" ]]; then
    # if -l provided, run as if calling `fc' directly
    builtin fc "$@"
  else
    # unless a number is provided, show all history events (starting from 1)
    [[ ${@[-1]-} = *[0-9]* ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
  fi
}

#
# Options
#

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing non-existent history.

#
# Variables
#

[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history" # The path to the history file.
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000 # The maximum number of events to save in the internal history.
[ "$SAVEHIST" -lt 10000 ] && SAVEHIST=10000 # The maximum number of events to save in the history file.

#
# Aliases
#

# Lists the ten most used commands.
alias history-stat="history 0 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"

# Timestamp format
case ${HIST_STAMPS-} in
  "mm/dd/yyyy") alias history='ggz_history -f' ;;
  "dd.mm.yyyy") alias history='ggz_history -E' ;;
  "yyyy-mm-dd") alias history='ggz_history -i' ;;
  "") alias history='ggz_history' ;;
  *) alias history="ggz_history -t '$HIST_STAMPS'" ;;
esac
