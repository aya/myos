# shellcheck shell=sh
## rc.sh calls user defined functions
# author: Yann "aya" Autissier
# license: MIT
# updated: 2021/03/04

case $- in
  # if we are in an interactive shell
  *i*)
    # load user stuff from ~/.rc.d/* files
    for file in "${HOME}"/.rc.d/*; do
        # read files only
        if [ -f "${file}" ]; then
            func_name=$(basename "${file}")
            func_args=$(cat "${file}")
            # at this stage, func_name can start with numbers to allow ordering function calls with file names starting with numbers
            # func_name must start with a letter, remove all other characters at the beginning of func_name until a letter is found
            while [ "${func_name}" != "" ] && [ "${func_name#[a-z]}" = "${func_name}" ]; do
                # remove first char of func_name
                func_name="${func_name#?}"
            done
            # call user function with args passed from the content of the file
            command -v "${func_name}" >/dev/null 2>&1 && "${func_name}" "${func_args}"
        fi
    done
    # load user stuff from RC_* env vars
    IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}"; for line in $(printenv 2>/dev/null |awk '$0 ~ /^RC_[1-9A-Z_]*=/'); do
        func_name=$(printf '%s\n' "${line%%=*}" |awk '{print tolower(substr($0,4))}')
        eval func_args=\$"${line%%=*}"
        [ "${func_args}" = "false" ] && continue
        [ "${func_args}" = "true" ] && unset func_args
        # at this stage, func_name can start with numbers to allow ordering function calls with file names starting with numbers
        # func_name must start with a letter, remove all other characters at the beginning of func_name until a letter is found
        while [ "${func_name}" != "" ] && [ "${func_name#[a-z]}" = "${func_name}" ]; do
            # remove first char of func_name
            func_name="${func_name#?}"
        done
        # call user function with args passed from the value of the env var
        command -v "${func_name}" >/dev/null 2>&1 && "${func_name}" "${func_args}"
    done
    unset IFS
  ;;
esac
