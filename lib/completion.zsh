#
# Configure completion
#
# Authors
#   Gigitsu <luigi.clemente@gsquare.it>
#

# Human-readably notifying the user of these insecurities.
function handle_completion_insecurities() {
  # List of the absolute paths of all unique insecure directories, split on
  # newline from compaudit()'s output resembling:
  #
  #     There are insecure directories:
  #     /usr/share/zsh/site-functions
  #     /usr/share/zsh/5.0.6/functions
  #     /usr/share/zsh
  #     /usr/share/zsh/5.0.6
  #
  # Since the ignorable first line is printed to stderr and thus not captured,
  # stderr is squelched to prevent this output from leaking to the user.
  local -aU insecure_dirs
  insecure_dirs=( ${(f@):-"$(compaudit 2>/dev/null)"} )

  # If no such directories exist, get us out of here.
  [[ -z "${insecure_dirs}" ]] && return

  # List ownership and permissions of all insecure directories.
  warn "Insecure completion-dependent directories detected:"

  ls -ld "${(@)insecure_dirs}"

  warn 'For safety, we will not load completions from these directories until\n'
  warn 'you fix their permissions and ownership and restart zsh.\n'
  warn 'See the above list for directories with group or other writability.\n'
  warn '\n'
  warn 'To fix your permissions you can do so by disabling\n'
  warn 'the write permission of "group" and "others" and making sure that the\n'
  warn 'owner of these directories is either root or your current user.\n'
  warn 'The following command may help:\n'
  warn '    compaudit | xargs chmod g-w,o-w\n'
}

# Load and initialize the completion system ignoring insecure directories with a
# cache time of 20 hours, so it should almost always regenerate the first time a
# shell is opened each day.
local zcompdump_revision zcompdump_refresh zcompdump_path zcompdump_fpath

autoload -Uz compaudit compinit

# Construct zcompdump Gigish metadata
zcompdump_revision="#ggsh revision: $(builtin cd -q "$ZSH"; git rev-parse HEAD 2>/dev/null)"
zcompdump_path="${CACHE_HOME}/zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
zcompdump_fpath="#ggsh fpath: $fpath"


# Delete the zcompdump file if Gigish zcompdump metadata changed
# forcing dump recreation
if ! command grep -q -Fx "$zcompdump_revision" "$zcompdump_path" 2>/dev/null || \
   ! command grep -q -Fx "$zcompdump_fpath" "$zcompdump_path" 2>/dev/null; then
  debug "Deleting zcompdump"
  command rm -f "$zcompdump_path"
  zcompdump_refresh=1
fi

# If completion insecurities exist, warn the user
handle_completion_insecurities

# On slow systems, checking the cached .zcompdump file to see if it must be
# regenerated adds a noticable delay to zsh startup.  This little hack restricts
# it to once a day.
#
# The globbing is a little complicated here:
# - '#q' is an explicit glob qualifier that makes globbing work within zsh's [[ ]] construct.
# - 'N' makes the glob pattern evaluate to nothing when it doesn't match (rather than throw a globbing error)
# - 'mh-20' matches files (or directories or whatever) modified in the last 20 hours.
if [[ $zcompdump_path(#qNmh-20) ]]; then
  # The -C flag bypasses both the check for rebuilding the dump file and the
  # usual call to compaudit and it implies -i flag
  compinit -C -d "$zcompdump_path"
else
  debug "Recomputing zcompdump"
  mkdir -p "$zcompdump_path:h"
  compinit -i -d "$zcompdump_path"
  # Keep $zcompdump_path younger than cache time even if it isn't regenerated.
  touch "$zcompdump_path"
fi

# Append zcompdump metadata if missing
if (( $zcompdump_refresh )); then
  # Use `tee` in case the $zcompdump_path filename is invalid, to silence the error
  # See https://github.com/ohmyzsh/ohmyzsh/commit/dd1a7269#commitcomment-39003489
  echo "\n$zcompdump_revision\n$zcompdump_fpath" | tee -a "$zcompdump_path" &>/dev/null
fi

# Execute code that does not affect the current session in the background.
{
  # Compile the completion dump to increase startup speed.
  if [[ -s "$zcompdump_path" && (! -s "${zcompdump}.zwc" || "$zcompdump_path" -nt "${zcompdump_path}.zwc") ]]; then
    zcompile "$zcompdump_path"
  fi
} &!

## options

setopt COMPLETE_IN_WORD     # Complete from both ends of a word.
setopt ALWAYS_TO_END        # Move cursor to the end of a completed word.
setopt PATH_DIRS            # Perform path search even on command names with slashes.
setopt AUTO_MENU            # Show completion menu on a successive tab press.
setopt AUTO_LIST            # Automatically list choices on ambiguous completion.
setopt AUTO_PARAM_SLASH     # If completed parameter is a directory, add a trailing slash.
setopt EXTENDED_GLOB        # Needed for file modification glob modifiers with compinit.

unsetopt MENU_COMPLETE      # Do not autoselect the first completion entry.
unsetopt FLOW_CONTROL       # Disable start/stop characters in shell editor.

# Standard style used by default for 'list-colors'
LS_COLORS=${LS_COLORS:-'di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:'}

# styles

# Defaults.
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# Use caching to make completion for commands such as dpkg and apt usable.
zstyle ':completion::*' use-cache on
zstyle ':completion::*' cache-path "${CACHE_HOME}/zcompcache"

# case insensitive (all), partial-word, and then substring completion.
if [[ "$CASE_SENSITIVE_COMPLETION" = true ]]; then
  zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  setopt CASE_GLOB
else
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  unsetopt CASE_GLOB
fi
unset CASE_SENSITIVE_COMPLETION

# Group matches and describe.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase the number of errors based on the length of the typed word. But make
# sure to cap (at 7) the max-errors to avoid hanging.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Directories
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true # Complete . and .. special directories

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Environment Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Populate hostname completion. But allow ignoring custom entries from static
# */etc/hosts* which might be uninteresting.
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2> /dev/null))"}%%(\#${ETC_HOST_IGNORED_COMPLETION:+|${(j:|:)~_etc_host_ignores}})*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
  dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
  mailman mailnull mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Media Players
zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'

# Mutt
if [[ -s "$HOME/.mutt/aliases" ]]; then
  zstyle ':completion:*:*:mutt:*' menu yes select
  zstyle ':completion:*:mutt:*' users ${${${(f)"$(<"$HOME/.mutt/aliases")"}#alias[[:space:]]}%%[[:space:]]*}
fi

# SSH/SCP/RSYNC
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# automatically load bash completion functions
# autoload -U +X bashcompinit && bashcompinit

unset -f handle_completion_insecurities
