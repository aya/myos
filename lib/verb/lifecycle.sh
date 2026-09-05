#shellcheck shell=sh
# bootstrap, install, clean, attach, build: what surrounds `up`.

# bootstrap: what a project needs before its first up: the .env rendered
# from the .env.dist of the stacks, the networks, the images to build
myos_verb_bootstrap() {
  myos_verb_env_update
  myos_networks_ensure
  myos_images; [ -n "$R" ] && myos_verb_build
  return 0
}

# up runs the bootstrap the first time (no .env yet) or on --bootstrap
myos_up_needs_bootstrap() {
  [ -n "${MYOS_BOOTSTRAP:-}" ] && return 0
  myos_env_file; [ -f "$R" ] && return 1
  myos_env_dists; _nb_ifs=$IFS; IFS=$NL; set -f
  for _nb_f in $R; do [ -f "$_nb_f" ] && { IFS=$_nb_ifs; set +f; return 0; }; done
  IFS=$_nb_ifs; set +f; return 1
}

# build [IMAGE]: the images of the stack directories (docker/<image>/Dockerfile,
# docker/<image>/<variant>/Dockerfile as image:variant), else compose build
myos_verb_build() {
  myos_images; _bd_all=$R
  _bd_want=${MYOS_IMAGE:-$_bd_all}
  if [ -z "$_bd_want" ]; then myos_compose build; return $?; fi
  myos_var DOCKER_REPOSITORY; _bd_repo=$R
  myos_var DOCKER_IMAGE_TAG; _bd_tag=$R
  for _bd_i in $_bd_want; do
    _bd_name=${_bd_i%%:*}; _bd_var=; case $_bd_i in *:*) _bd_var=${_bd_i#*:} ;; esac
    myos_image_dir "$_bd_name"; _bd_dir=$R
    [ -n "$_bd_dir" ] || myos_die 1 "no docker/$_bd_name/Dockerfile in the directories of $MYOS_STACK"
    for _bd_f in "$_bd_dir/docker/$_bd_name${_bd_var:+/$_bd_var}/Dockerfile" $( [ -z "$_bd_var" ] && ls "$_bd_dir/docker/$_bd_name"/*/Dockerfile 2>/dev/null ); do
      [ -f "$_bd_f" ] || continue
      _bd_rel=${_bd_f#"$_bd_dir"/}; _bd_rel=${_bd_rel%/Dockerfile}
      _bd_t=$_bd_tag; case $_bd_rel in docker/"$_bd_name"/*) _bd_t=${_bd_rel#docker/"$_bd_name"/} ;; esac
      myos_run docker build --build-arg "DOCKER_BUILD_DIR=$_bd_rel" --build-arg "UID=$(id -u)" --build-arg "GID=$(id -g)" \
        --tag "$_bd_repo/$_bd_name:$_bd_t" -f "$_bd_f" "$_bd_dir" || return 1
    done
  done
}
myos_image_dir() { # IMAGE -> R: the stack directory holding docker/IMAGE/Dockerfile
  R=; _id_ifs=$IFS; IFS=$NL; set -f
  for _id_d in $MYOS_STACK_DIRS $MYOS_WORKDIR; do [ -f "$_id_d/docker/$1/Dockerfile" ] && R=$_id_d; done
  IFS=$_id_ifs; set +f
}

# install [URL [DIR]]: clone a project and bootstrap it
myos_verb_install() {
  if [ -n "$MYOS_ARGS" ]; then
    set -- $MYOS_ARGS
    _in_dir=${2:-$(basename "${1%.git}")}
    myos_run git clone --quiet "$1" "$_in_dir" || return 1
    MYOS_WORKDIR=$(cd "$_in_dir" && pwd -P)
  fi
  myos_verb_bootstrap
}

# clean: down with images and volumes; a host stack needs --yes
myos_verb_clean() {
  if [ "$MYOS_STACK_SCOPE" = host ] && [ -z "${MYOS_YES:-}" ]; then
    myos_die 2 "clean would remove the volumes of the host stack $MYOS_STACK: run it with --yes"
  fi
  myos_compose down --rmi all --volumes
}

# attach: the terminal of the container of SERVICE
myos_verb_attach() {
  myos_run docker attach "$MYOS_PROJECT-${MYOS_SERVICE:-$MYOS_STACK_NAME}-1"
}
