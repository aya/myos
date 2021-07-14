# ~/.profile: executed by the command interpreter for login shells.
# set -x

# source ~/.*aliases and ~/.*functions files
for source in aliases functions; do
  for file in "$HOME"/.*"$source"; do
    [ -f "$file" ] || continue
    # remove $HOME/. prefix from file
    file="${file#${HOME}/.}"
    # remove _$source suffix from $file
    command="${file%_$source}"
    # source file if command exists, ie ~/.bash_aliases
    command -v "$command" >/dev/null 2>&1 && . "${HOME}/.$file"
    # remove $source suffix from $file, ie ~/.aliases
    command="${file%$source}"
    # source file if command empty, ie ~/.aliases
    [ -z "$command" ] && . "${HOME}/.$file"
  done
done

# source ~/.*shrc
for file in "$HOME"/.*shrc; do
  [ -f "$file" ] || continue
  # remove $HOME/. prefix from file
  file="${file#${HOME}/.}"
  # source file if match current shell
  [ "$(basename ${SHELL})" = "${file%rc}" ] && . "${HOME}/.$file"
done

# set PATH to include user's bin
for path in /*/local/sbin /*/local/bin /*/local/*/bin "${HOME}"/.*/bin; do
  [ -d "$path" ] || continue
  case ":${PATH}:" in
    *:"$path":*) ;;
    *) export PATH="${path}:$PATH" ;;
  esac
done
