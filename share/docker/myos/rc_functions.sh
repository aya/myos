# shellcheck shell=sh
# file rc_functions.sh: Define shell functions
## author: Yann "aya" Autissier
## license: GPL
## version: 20260730

# function force: Run a command sine die
force() {
  if [ $# -gt 0 ]; then
    while true; do
      "$@"
      sleep 1
    done
  fi
}

# function force8: Run a command sine die if not already running
force8() {
  if [ $# -gt 0 ]; then
    while true; do
      # awk expression to match $@
      [ "$(ps wwx -o args 2>/dev/null |awk -v field="${PS_X_FIELD:-1}" '
        BEGIN { nargs=split("'"$*"'",args); }
        # first field matched
        $field == args[1] {
          matched=1;
          # match following fields
          for (i=1;i<=NF-field;i++) {
            if ($(i+field) == args[i+1]) { matched++; }
          };
          # all fields matched
          if (matched == nargs) { found++; }
        }
        END { print found+0; }'
      )" = 0 ] && "$@"
      sleep 1
    done
  fi
}

# function lang_set; Export default LANG
lang_set() {
  export $(awk -F'=' '$1 == "LANG"' /etc/default/locale 2>/dev/null) >/dev/null
}

# function load_average; Print the current load average
load_average() {
  uptime 2>/dev/null |awk '{printf "%.1f\n", $(NF-2)}'
}

# function process_count: Print number of "processes"/"running processes"/"D-state"
process_count() {
  ps ax -o stat 2>/dev/null |awk '
    $1 ~ /R/ {process_running++};
    $1 ~ /D/ {process_dstate++};
    END { print NR-1"/"process_running+0"/"process_dstate+0; }'
}

# function prompt_set: Export custom PROMPT_COMMAND
prompt_set() {
  # zsh: PROMPT_COMMAND is bash-only, set the terminal title from a precmd hook
  if [ -n "${ZSH_VERSION:-}" ]; then
    _prompt_precmd() {
      local __ret=$? dcs st host
      case "${TERM}" in
        screen*) dcs=$'\ek'; st=$'\e\\';;
        *)       dcs=$'\e]0;'; st=$'\a';;
      esac
      host="${HOSTNAME:-${HOST}}"
      if [ -n "${STY}" ]; then
        printf '%s%s%s' "${dcs}" "${PWD##*/}" "${st}"
      else
        printf '%s%s@%s:%s%s' "${dcs}" "${USER}" "${host%%.*}" "${PWD##*/}" "${st}"
      fi
      return ${__ret}
    }
    autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook precmd _prompt_precmd
    return
  fi
  case "${TERM}" in
    screen*)
      ESCAPE_CODE_DCS="\033k"
      ESCAPE_CODE_ST="\033\\"
      ;;
    linux*|xterm*|rxvt*)
      ESCAPE_CODE_DCS="\033]0;"
      ESCAPE_CODE_ST="\007"
      ;;
    *)
      ;;
  esac
  # in a screen
  if [ -n "${STY}" ]; then
    export PROMPT_COMMAND='printf\
     "${ESCAPE_CODE_DCS:-\033]0;}%s${ESCAPE_CODE_ST:-\007}"\
     "${PWD##*/}"'
  else
    export PROMPT_COMMAND='printf\
     "${ESCAPE_CODE_DCS:-\033]0;}%s@%s:%s${ESCAPE_CODE_ST:-\007}"\
     "${USER}"\
     "${HOSTNAME%%.*}"\
     "${PWD##*/}"'
  fi
  unset ESCAPE_CODE_DCS ESCAPE_CODE_ST
}

# function ps1_set: Export custom PS1
ps1_set() {
  # zsh: bash prompt escapes (\[ \]) and "$0" shell detection do not apply;
  # rebuild PROMPT from a precmd hook using zsh's %{ %} non-printing markers
  if [ -n "${ZSH_VERSION:-}" ]; then
    _ps1_precmd() {
      local __ret=$?
      local dgray=$'%{\e[1;30m%}' red=$'%{\e[01;31m%}' green=$'%{\e[01;32m%}' \
            brown=$'%{\e[0;33m%}' yellow=$'%{\e[01;33m%}' blue=$'%{\e[01;34m%}' \
            cyan=$'%{\e[0;36m%}' gray=$'%{\e[0;37m%}' reset=$'%{\e[0m%}'
      local scol ucol hcol count user host wd git end sym uid h br
      uid="$(id -u)"
      # exit status: blue on success, yellow on 1, red otherwise
      case "${__ret}" in
        0) scol="${blue}";;
        1) scol="${yellow}";;
        *) scol="${red}";;
      esac
      count="${dgray}[${scol}${__ret}"
      type process_count >/dev/null 2>&1 \
        && count="${count}${dgray}|${blue}$(process_count 2>/dev/null)"
      type user_count >/dev/null 2>&1 \
        && count="${count}${dgray}|${blue}$(user_count 2>/dev/null)"
      type load_average >/dev/null 2>&1 \
        && count="${count}${dgray}|${blue}$(load_average 2>/dev/null)"
      count="${count}${dgray}]${reset}"
      # user: red for root, brown otherwise
      [ "${uid}" = 0 ] && ucol="${red}" || ucol="${brown}"
      user="${ucol}$(id -nu):${uid}${reset}"
      # hostname: red on prod, yellow if ENV set, green otherwise
      h="$(hostname |sed 's/\..*//')"
      case "${ENV}${h}" in
        *[Pp][Rr][Oo][Dd]*|*[Pp][Rr][Dd]*) hcol="${red}";;
        *) [ -n "${ENV}" ] && hcol="${yellow}" || hcol="${green}";;
      esac
      host="${hcol}${h}${reset}"
      # workdir with ~ for $HOME
      wd="${gray}$(pwd |sed 's|^'"${HOME}"'\(/.*\)*$|~\1|')${reset}"
      # git branch
      if type __git_ps1 >/dev/null 2>&1; then
        git="$(__git_ps1 ' (%s)' 2>/dev/null)"
      else
        br="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
        [ -n "${br}" ] && git=" (${br})"
      fi
      git="${cyan}${git}${reset}"
      # tail: # for root, $ otherwise
      [ "${uid}" = 0 ] && sym='#' || sym='$'
      end="${dgray}${sym}${reset}"
      PROMPT="${count}${user}${dgray}@${host}${dgray}:${wd}${git}${end} "
    }
    autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook precmd _ps1_precmd
    return
  fi
  case "$0" in
    *sh)
      COLOR_DGRAY="\[\033[1;30m\]"
      COLOR_RED="\[\033[01;31m\]"
      COLOR_GREEN="\[\033[01;32m\]"
      COLOR_BROWN="\[\033[0;33m\]"
      COLOR_YELLOW="\[\033[01;33m\]"
      COLOR_BLUE="\[\033[01;34m\]"
      COLOR_CYAN="\[\033[0;36m\]"
      COLOR_GRAY="\[\033[0;37m\]"
      COLOR_RESET="\[\033[0m\]"
      ;;
    *)
      ;;
  esac

  PS1_STATUS="\$?"
  PS1_COUNT="${COLOR_DGRAY}[\`
    case \"$PS1_STATUS\" in
      0)
        printf \"${COLOR_BLUE}${PS1_STATUS}\";;
      1)
        printf \"${COLOR_YELLOW}${PS1_STATUS}\";;
      *)
        printf \"${COLOR_RED}${PS1_STATUS}\";;
    esac
    type process_count >/dev/null 2>&1 && printf\
     \"${COLOR_DGRAY}|${COLOR_BLUE}%s\"\
     \"\$(process_count 2>/dev/null)\"
    type user_count >/dev/null 2>&1 && printf\
     \"${PS1_COUNT}${COLOR_DGRAY}|${COLOR_BLUE}%s\"\
     \"\$(user_count 2>/dev/null)\"
    type load_average >/dev/null 2>&1 && printf\
     \"${PS1_COUNT}${COLOR_DGRAY}|${COLOR_BLUE}%s\"\
     \"\$(load_average 2>/dev/null)\"
  \`${COLOR_DGRAY}]${COLOR_RESET}"
  PS1_END="${COLOR_DGRAY}\$(
    if [ \"\$(id -u)\" = 0 ]; then
      printf \"#\";
    else
      printf \"\$\";
    fi
  )${COLOR_RESET}"
  PS1_GIT="\$(
    if type __git_ps1 >/dev/null 2>&1; then
      printf \"\$(__git_ps1 2>/dev/null \" (%s)\")\"
    else
      printf \"\$(BRANCH=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null);\
              [ -n \"\${BRANCH}\" ] && printf \" (\${BRANCH})\")\"
    fi
  )"
  PS1_GIT="${COLOR_CYAN}${PS1_GIT}${COLOR_RESET}"
  PS1_HOSTNAME_COLOR="\`case \"\${ENV}${HOSTNAME%%.*}\" in
    *[Pp][Rr][0Oo][Dd]*|*[Pp][Rr][Dd]*)
      printf \"${COLOR_RED}\";;
    *)
      if [ -n \"\${ENV}\" ]; then
        printf \"${COLOR_YELLOW}\";
      else
        printf \"${COLOR_GREEN}\";
      fi;;
  esac\`"
  PS1_HOSTNAME="${PS1_HOSTNAME_COLOR}\$(hostname |sed 's/\..*//')${COLOR_RESET}"
  PS1_USER_COLOR="\$(
    if [ \"\$(id -u)\" = 0 ]; then
      printf \"${COLOR_RED}\";
    else
      printf \"${COLOR_BROWN}\";
    fi
  )"
  PS1_USER="${PS1_USER_COLOR}\$(id -nu):\$(id -u)${COLOR_RESET}"
  PS1_WORKDIR="${COLOR_GRAY}\$(
    pwd |sed 's|^'\${HOME}'\(/.*\)*$|~\1|'
  )${COLOR_RESET}"
  PS1="${PS1_COUNT}${PS1_USER}${COLOR_DGRAY}@${PS1_HOSTNAME}"
  PS1="${PS1}${COLOR_DGRAY}:${PS1_WORKDIR}${PS1_GIT}${PS1_END} "
  export 'PS1'
  unset PS1_COUNT PS1_END PS1_GIT PS1_HOSTNAME PS1_HOSTNAME_COLOR\
        PS1_USER PS1_USER_COLOR PS1_STATUS PS1_WORKDIR
}

# function screen_attach: Attach existing screen session or Create a new one
screen_attach() {
  command -v screen >/dev/null 2>&1 || return
  SCREEN_SESSION="$(id -nu)@$(hostname |sed 's/\..*//')"
  if [ -z "${STY}" ]; then
    # attach screen in tmux window 0 only ;)
    [ -n "${TMUX}" ] \
     && [ "$(tmux list-window 2>/dev/null |awk '$NF == "(active)" {print $1}'\
      |sed 's/:$//')" != "0" ] \
     && return
    printf 'Attaching screen.' && sleep 1\
     && printf '.' && sleep 1\
     && printf '.' && sleep 1
    exec screen -xRR -S "${SCREEN_SESSION}"
  fi
  unset SCREEN_SESSION
}

# function screen_detach: Detach current screen session
screen_detach() {
  screen -d
}

# function ssh_add: Load all private keys in ~/.ssh/ to ssh agent
ssh_add() {
  command -v ssh-agent >/dev/null 2>&1 && command -v ssh-add >/dev/null 2>&1 || return
  # zsh: emulate bash handling of unmatched globs (scoped to this function via localoptions)
  [ -n "${ZSH_VERSION:-}" ] && setopt localoptions nonomatch
  SSH_AGENT_DIR="/tmp/ssh-$(id -u)"
  SSH_AGENT_SOCK="${SSH_AGENT_DIR}/agent@$(hostname |sed 's/\..*//')"
  # launch a new agent
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    [ ! -d "${SSH_AGENT_DIR}" ] \
     && mkdir -p "${SSH_AGENT_DIR}" 2>/dev/null\
     && chmod 0700 "${SSH_AGENT_DIR}"
    # search for an already running agent
    if ps wwx -o args |awk '$1 ~ "ssh-agent$" && $3 == "'"${SSH_AGENT_SOCK}"'"' |wc -l |grep -q 0; then
      rm -f "${SSH_AGENT_SOCK}"
      ssh-agent -a "${SSH_AGENT_SOCK}" >/dev/null 2>&1
    fi
  fi
  # attach to agent
  export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-${SSH_AGENT_SOCK}}"
  # list private keys to add
  # shellcheck disable=SC2068
  for dir in ${@:-${HOME}/.ssh}; do
    if [ "${SSH_ADD_RECURSIVE:-}" = true ]; then
      GREP_RECURSIVE_FLAG="r"
    else
      GREP_RECURSIVE_CHAR="*"
    fi
    SSH_PRIVATE_KEYS="${SSH_PRIVATE_KEYS:-} ${dir}/id_ed25519 ${dir}/id_rsa $(grep -l${GREP_RECURSIVE_FLAG:-} 'PRIVATE KEY' "${dir}/"${GREP_RECURSIVE_CHAR:-} 2>/dev/null |grep -vwE "${dir}/id_(rsa|ed25519)")"
  done
  # split on spaces/newlines via tr, portable across bash (IFS split) and zsh (no word split)
  printf '%s' "${SSH_PRIVATE_KEYS}" |tr ' ' '\n' |while read -r file; do
    [ -r "${file}" ] || continue
    # fingerprint is empty when ssh-keygen cannot read the key (legacy PEM without .pub):
    # in that case add it instead of matching the empty pattern against every agent line
    fingerprint="$(ssh-keygen -lf "${file}" 2>/dev/null |awk '{print $2}')"
    [ -n "${fingerprint}" ] && ssh-add -l 2>/dev/null |grep -qF "${fingerprint}" && continue
    # add private key to agent
    ssh-add "${file}"
  done
  unset GREP_RECURSIVE_CHAR GREP_RECURSIVE_FLAG SSH_AGENT_DIR SSH_AGENT_SOCK SSH_PRIVATE_KEYS
}

# function ssh_del: removes all private keys in ~/.ssh/ from ssh agent
ssh_del() {
  command -v ssh-add >/dev/null 2>&1 || return
  # zsh: emulate bash handling of unmatched globs (scoped to this function via localoptions)
  [ -n "${ZSH_VERSION:-}" ] && setopt localoptions nonomatch
  # attach to agent
  if [ -z "${SSH_AUTH_SOCK}" ]; then
    return
  fi
  # list private keys to del
  # shellcheck disable=SC2068
  for dir in ${@:-${HOME}/.ssh}; do
    if [ "${SSH_DEL_RECURSIVE:-}" = true ]; then
      GREP_RECURSIVE_FLAG="r"
    else
      GREP_RECURSIVE_CHAR="*"
    fi
    SSH_PRIVATE_KEYS="${SSH_PRIVATE_KEYS:-} ${dir}/id_ed25519 ${dir}/id_rsa $(grep -l${GREP_RECURSIVE_FLAG:-} 'PRIVATE KEY' "${dir}/"${GREP_RECURSIVE_CHAR:-} 2>/dev/null |grep -vwE "${dir}/id_(rsa|ed25519)")"
  done
  # split on spaces/newlines via tr, portable across bash (IFS split) and zsh (no word split)
  printf '%s' "${SSH_PRIVATE_KEYS}" |tr ' ' '\n' |while read -r file; do
    [ -r "${file}" ] || continue
    # skip keys we cannot fingerprint, an empty pattern would match any agent line
    fingerprint="$(ssh-keygen -lf "${file}" 2>/dev/null |awk '{print $2}')"
    [ -n "${fingerprint}" ] || continue
    # remove private key from agent
    ssh-add -l 2>/dev/null |grep -qF "${fingerprint}" && ssh-add -d "${file}"
  done
  unset GREP_RECURSIVE_CHAR GREP_RECURSIVE_FLAG SSH_PRIVATE_KEYS
}

# function tmux_attach: Attach existing tmux session or Create a new one
tmux_attach() {
  command -v tmux >/dev/null 2>&1 || return
  TMUX_SESSION="$(id -nu)@$(hostname |sed 's/\..*//')"
  # do not attach tmux in screen ;)
  if [ -z "${TMUX}" -a -z "${STY}" ]; then
    printf 'Attaching tmux.' && sleep 1\
     && printf '.' && sleep 1\
     && printf '.' && sleep 1
    exec tmux -L"${TMUX_SESSION}" new-session -A -s"${TMUX_SESSION}"
  fi
  unset TMUX_SESSION
}

# function tmux_detach: Detach current tmux session
tmux_detach() {
  tmux detach
}

# function user_count: Print number of "users sessions"/"users"/"logged users"
user_count() {
  ps ax -o pid,user,tty,comm 2>/dev/null |awk '
    $3 ~ /^(pts\/|tty[sS]?|[0-9]+,)[0-9]+$/ && $4 != "getty" { users_sessions++; logged[$2]++; };
    $1 ~ /^[0-9]+$/ { count[$2]++; }
    END {
      for (uc in count) { c = c" "uc; }; users_count=split(c,v," ");
      for (ul in logged) { l = l" "ul; }; users_logged=split(l,v," ");
      print users_sessions+0"/"users_count+0"/"users_logged+0;
    }'
}
