#!/usr/bin/env bash
W="$(cd $(dirname $(readlink -f "$0"))/ && pwd)"
vv() { echo "$@">&2;"$@"; }
dvv() { if [[ -n "${DEBUG-}" ]];then echo "$@">&2;fi;"$@"; }
reset
out2="$( cd "$W/.." && pwd)"
out="$(dirname $out2)/$(basename $out2)_pre"
venv=${venv:-$HOME/tools/cookiecutter/activate}
if [ -e "$venv/bin/activate" ];then . "$venv/bin/activate";fi
set -e
if [[ -n "$1" ]] && [ -e $1 ];then
    COOKIECUTTER="$1"
    shift
fi
# $1 maybe a dir or an argument
u=${COOKIECUTTER-}
if [[ -z "$u" ]];then
    u="$HOME/.cookiecutters/cookiecutter-simplecompose"
    if [ ! -e "$u" ];then
        u="https://github.com/corpusops/$(basename $u).git"
    else
        cd "$u"
        git fetch origin
        git pull --rebase
    fi
fi
if [ -e "$out" ];then vv rm -rf "$out";fi
vv cookiecutter --no-input -o "$out" -f "$u" \
    name="imaptools" \
    author="kiorky" \
    email="freesoftware@makina-corpus.com" \
    git_ns="corpusops" \
    lname="imaptools" \
    eggname="imaptools" \
    infra_domain="cryptelium.net" \
    simple_docker_image="corpusops/docker-imaptools" \
    py_ver="3.8" \
    network="172.38.0.0" \
    with_sudo="y" \
    main_branch="main" \
    with_logging="y" \
    restart_policy="unless-stopped" \
    with_db="" \
    with_pyapp="" \
    with_mailcatcher="" \
    with_node="" \
    with_docker_git="y" \
    with_githubactions="y" \
    node_version="lts/*" \
    git_server="github.com" \
    git_project_server="github.com" \
    git_project="docker-imaptools" \
    git_scheme="https" \
    git_user="" \
    git_project_url="https://github.com/corpusops/docker-imaptools" \
    out_dir="." \
    docker_registry="" \
    app_type="simplecompose" \
    ck_type="simplecompose" \
    docker_image="corpusops/imaptools" \
    db_image="corpusops/postgres:13" \
    release_mode="docker" \
    corpusops_image="corpusops/ubuntu-bare:20.04" \
    base_image="corpusops/ubuntu-bare:20.04" \
     "$@"


# to finish template loop
# sync the gen in a second folder for intermediate regenerations
dvv rsync -aA \
    $(if [[ -n $DEBUG ]];then echo "-v";fi )\
    --include local/regen.sh \
    --exclude "local/*" --exclude lib \
    $( if [ -e ${out2}/.git ];then echo "--exclude .git";fi; ) \
    "$out/" "${out2}/"
if [ -e "$out/lib" ];then
dvv rsync -aA \
    $(if [[ -n $DEBUG ]];then echo "-v";fi )\
    "$out/lib/" "${out2}/lib/"
fi

( cd "$out2" && git add -f local/regen.sh || /bin/true)
dvv cp -f "$out/local/regen.sh" "$out2/local"

add_submodules() {
    cd "$out"
    while read submodl;do
        submodu="$(echo $submodl|awk '{print $2}')"
        submodp="$(echo $submodl|awk '{print $1}')"
        cd "$out2"
        if [ ! -e "$submodp" ];then
            git submodule add -f "$submodu" "$submodp"
        fi
        cd "$out"
    done < <(\
        git submodule foreach -q 'echo $path `git config --get remote.origin.url`'
    )
    cd "$W"
}
( add_submodules )
if [[ -z ${NO_RM-} ]];then dvv rm -rf "${out}";fi
echo "Your project is generated in: $out2" >&2
echo "Please note that you can generate with the local/regen.sh file" >&2
# vim:set et sts=4 ts=4 tw=80:
