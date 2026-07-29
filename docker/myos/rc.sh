# shellcheck shell=sh
# file rc.sh: Call user defined functions
## author: Yann "aya" Autissier
## license: GPL
## version: 20260730

case $- in
  # if this is an interactive shell
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
            # an empty file means no args at all, do not pass an empty string
            if command -v "${func_name}" >/dev/null 2>&1; then
                if [ -n "${func_args}" ]; then
                    "${func_name}" "${func_args}"
                else
                    "${func_name}"
                fi
            fi
        fi
    done
    # load user stuff from RC_* env vars
    IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}"; for line in $(printenv 2>/dev/null |awk '$0 ~ /^RC_[0-9A-Z_]*=/' |sort); do
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
        # RC_FOO=true means no args at all, do not pass an empty string
        if command -v "${func_name}" >/dev/null 2>&1; then
            if [ -n "${func_args:-}" ]; then
                "${func_name}" "${func_args}"
            else
                "${func_name}"
            fi
        fi
    done
    unset IFS
  ;;
esac

# vim:ts=2:sw=2:sts=2:et
