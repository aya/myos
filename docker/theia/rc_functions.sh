# force a command to run and restart it when it exits
force () {
    PS_X_FIELD=1
    if [ $# -gt 0 ]; then
        # awk expression to match $@
        while true; do
            [ $(ps wwx -o args |awk '
                BEGIN {nargs=split("'"$*"'",args)}
                $field == args[1] {
                    matched=1;
                    for (i=1;i<=NF-field;i++) {
                        if ($(i+field) == args[i+1]) {matched++}
                    }
                    if (matched == nargs) {found++}
                }
                END {print found+0}' field="${PS_X_FIELD}") -eq 0 ] \
            && "$@" || sleep 1;
        done
    fi
}

# start an ssh agent and add any private key in ~/.ssh
ssh_agent () {
    command -v ssh-agent >/dev/null 2>&1 && command -v ssh-add >/dev/null 2>&1 || return
    SSH_AGENT_DIR="/tmp/ssh-$(id -u)"
    SSH_AGENT_SOCK="${SSH_AGENT_DIR}/agent@$(hostname |sed 's/\..*//')"
    [ -z "${SSH_AUTH_SOCK}" ] \
     && { [ -d "${SSH_AGENT_DIR}" ] || { mkdir "${SSH_AGENT_DIR}" 2>/dev/null && chmod 0700 "${SSH_AGENT_DIR}"; } } \
     && [ $(ps wwx -o args |awk '$1 == "ssh-agent" && $3 == "'"${SSH_AGENT_SOCK}"'"' |wc -l) -eq 0 ] \
     && rm -f "${SSH_AGENT_SOCK}" \
     && ssh-agent -a "${SSH_AGENT_SOCK}" >/dev/null 2>&1
    export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-${SSH_AGENT_SOCK}}"
    (echo "${HOME}"/.ssh/id_rsa; grep -l 'PRIVATE KEY' "${HOME}"/.ssh/* |grep -vE "^${HOME}/.ssh/id_rsa$") |while read -r file; do
        [ -r "${file}" ] && [ -z "$(ssh-add -l |awk '{print $3}' |grep -E "^${file}$")" ] && ssh-add "${file}"
    done
    unset SSH_AGENT_DIR SSH_AGENT_SOCK
}

# attach an existing screen or create a new one
attach_screen () {
    command -v screen >/dev/null 2>&1 || return
    if [ -z "${STY}" ]; then
        # attach screen in tmux window 0
        [ -n "${TMUX}" ] && [ "$(tmux list-window 2>/dev/null |awk '$NF == "(active)" {print $1}' |sed 's/:$//')" != "0" ] && return
        /bin/echo -n 'Attaching screen.' && sleep 1 && /bin/echo -n '.' && sleep 1 && /bin/echo -n '.' && sleep 1 && screen -xRR -S "$(id -nu)" 2>/dev/null
    fi
}

# attach an existing tmux or create a new one
attach_tmux () {
    command -v tmux >/dev/null 2>&1 || return
    SESSION_NAME="$(id -nu)@$(hostname |sed 's/\..*//')"
    if [ -z "${TMUX}" ]; then
        /bin/echo -n 'Attaching tmux.' && sleep 1 && /bin/echo -n '.' && sleep 1 && /bin/echo -n '.' && sleep 1 && tmux -L"${SESSION_NAME}" -q has-session >/dev/null 2>&1 && tmux -L"${SESSION_NAME}" attach-session -d || tmux -L"${SESSION_NAME}" new-session -s"${SESSION_NAME}"
    fi
}

# echo the "number of running processes"/"total number of processes"/"number of processes in D-state"
process_count () {
    ps ax -o stat 2>/dev/null |awk '$1 ~ /R/ {process_running++}; $1 ~ /D/ {process_dstate++}; END {print process_running+0"/"NR-1"/"process_dstate+0}'
}

# echo the "number of distinct logged in users"/"number of distinct users running processes"/"number of logged in users"
user_count () {
    ps ax -o user,tty,comm 2>/dev/null |awk '$2 !~ /^\?/ && $3 !~ /getty$/ {logged[$1]++; tty[$2]++}; {user[$1]++}; END {for (ul in logged) {sl = sl" "ul;}; users_logged=split(sl,a," ")-1; for (uu in user) {su = su" "uu;}; users_user=split(su,a," ")-1; for (ut in tty) {st = st" "ut;}; users_tty=split(st,a," ")-1; print users_logged"/"users_user"/"users_tty}'
}

# echo the load average
load_average () {
    awk '{print $1}' /proc/loadavg 2>/dev/null || uptime 2>/dev/null |awk '{print $(NF-2)}'
}

# export PS1
custom_ps1 () {
    case "$0" in
      *ash)
        local DGRAY="\[\033[1;30m\]"
        local RED="\[\033[01;31m\]"
        local GREEN="\[\033[01;32m\]"
        local BROWN="\[\033[0;33m\]"
        local YELLOW="\[\033[01;33m\]"
        local BLUE="\[\033[01;34m\]"
        local CYAN="\[\033[0;36m\]"
        local GRAY="\[\033[0;37m\]"
        local NC="\[\033[0m\]"
        ;;
      *)
        ;;
    esac

    local COLOR="\$([ \"\$(id -u)\" = 0 ] && echo \"${RED}\" || echo \"${BROWN}\")"
    local COUNT="${DGRAY}[${BLUE}\$(user_count 2>/dev/null)${DGRAY}|${BLUE}\$(process_count 2>/dev/null)${DGRAY}|${BLUE}\$(load_average 2>/dev/null)${DGRAY}]"
    local END="\$([ \"\$(id -u)\" = 0 ] && echo \"#\" || echo \"\$\")"
    local HOSTNAME="\$(hostname |sed 's/\..*//')"

    type __git_ps1 >/dev/null 2>&1 \
     && local GIT="\$(__git_ps1 2>/dev/null \" (%s)\")" \
     || local GIT="\$(BRANCH=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null); [ -n \"\${BRANCH}\" ] && echo \" (\${BRANCH})\")"

    local USER="\$(id -nu)"
    local WORKDIR="\$(pwd |sed 's|^'\${HOME}'\(/.*\)*$|~\1|')"

    export PS1="${COUNT}${COLOR}${USER}${DGRAY}@${CYAN}${HOSTNAME}${DGRAY}:${GRAY}${WORKDIR}${CYAN}${GIT}${DGRAY}${END}${NC} "
}

# export PROMPT_COMMAND
custom_prompt () {
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
    [ -n "${STY}" ] \
     && export PROMPT_COMMAND='printf "${ESCAPE_CODE_DCS:-\033]0;}%s${ESCAPE_CODE_ST:-\007}" "${PWD##*/}"' \
     || export PROMPT_COMMAND='printf "${ESCAPE_CODE_DCS:-\033]0;}%s@%s:%s${ESCAPE_CODE_ST:-\007}" "${USER}" "${HOSTNAME%%.*}" "${PWD##*/}"'
}
