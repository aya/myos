# ~/.bash_profile: executed by the command interpreter for bash login shell.

[ -f ~/.profile ] && source ~/.profile

# bash-completion
if ! shopt -oq posix && [ -z "${BASH_COMPLETION_VERSINFO-}" ]; then
  if [ ${BASH_VERSINFO[0]} -gt 4 ] \
   || [ ${BASH_VERSINFO[0]} -eq 4 -a ${BASH_VERSINFO[1]} -ge 1 ]; then
    shopt -q progcomp && for file in \
     /{*/local,usr}/share/bash-completion/bash_completion \
     /etc/bash_completion; do
      [ -r "$file" ] && . "$file"
    done
  fi
  if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion" ]; then
    . "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion"
  fi
fi
