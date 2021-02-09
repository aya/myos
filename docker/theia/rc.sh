# verify that default functions are loaded
type force >/dev/null 2>&1 || . /etc/profile.d/rc_functions.sh 2>/dev/null

# test current shell flags
case $- in
  # if we are in an interactive shell
  *i*)
    # load user defined stuffs from ~/.rc.d
    for user_func in "${HOME}"/.rc.d/*; do
        # read files only
        [ -f "${user_func}" ] && func_name=$(basename "${user_func}") || continue
        func_args=$(cat "${user_func}")
        # at this stage, func_name can start with numbers to allow ordering function calls with file names starting with numbers
        # func_name must start with a letter, remove all other characters at the beginning of func_name until a letter is found
        while [ "${func_name}" != "" ] && [ "${func_name#[a-z]}" = "${func_name}" ]; do
            # remove first char of func_name
            func_name="${func_name#?}"
        done
        # call user function with args passed from the content of the user_func file
        [ -n "${func_name}" ] && ${func_name} ${func_args} 2>/dev/null
    done
    # load user defined stuffs from RC_* env vars
    IFS=$'\n'; for func_line in $(env 2>/dev/null |awk '$0 ~ /^RC_/ {print tolower(substr($0,4))}'); do
        func_name="${func_line%%=*}"
        func_args="${func_line#*=}"
        [ "${func_args}" = "false" ] && continue
        [ "${func_args}" = "true" ] && unset func_args
        # at this stage, func_name can start with numbers to allow ordering function calls with file names starting with numbers
        # func_name must start with a letter, remove all other characters at the beginning of func_name until a letter is found
        while [ "${func_name}" != "" ] && [ "${func_name#[a-z]}" = "${func_name}" ]; do
            # remove first char of func_name
            func_name="${func_name#?}"
        done
        # call user function with args passed from the value of the env var
        [ -n "${func_name}" ] && ${func_name} ${func_args} 2>/dev/null
    done
    unset IFS
  ;;
esac
