# syntax=docker/dockerfile:1.3
ARG BASE_IMAGE=corpusops/ubuntu-bare:20.04
FROM $BASE_IMAGE AS base
USER root
WORKDIR /tmp/install
ARG \
    APP_HOME="" \
    DEV_DEPENDENCIES_PATTERN="^#\s*dev dependencies" \
    GITHUB_PAT="NTA2N2MxYTQzNDgzOGRkYzZkZTczZTZlNjljZTFkNGEzNWZjMWMxOAo=" \
    IMAGE_USER_RUNNER="root" \
    USER_GID="" \
    USER_GROUP="" \
    USER_HOME="/w" \
    USER_NAME="app" \
    USER_UID="1000"
ENV \
    USER_NAME="$USER_NAME" \
    USER_HOME="$USER_HOME" \
    USER_UID="$USER_UID" \
    USER_GID="${USER_GID:-$USER_UID}" \
    USER_GROUP="${USER_GROUP:-$USER_NAME}" \
    APP_HOME="${APP_HOME:-$USER_HOME}" \
    IMAGE_USER_RUNNER="$IMAGE_USER_RUNNER"
ENV \
    PATH="$USER_VENV/bin:/$APP_HOME/node_modules/.bin:$USER_HOME/bin:$APP_HOME/sbin:$APP_HOME/bin:$PATH"

# system dependendencies (pkgs, users, etc)
ADD apt*.txt ./
RUN bash -exc ': \
    \
    && : "install packages" \
    && apt-get update -qq \
    && ( mkdir -pv ${APP_HOME}/{sbin,bin} || true ) \
    && sed -re "/$DEV_DEPENDENCIES_PATTERN/,$ d" apt.txt|grep -vE "^\s*#"|tr "\n" " " > ${APP_HOME}/apt.txt \
    && apt-get install -qq -y $(cat ${APP_HOME}/apt.txt) \
    && apt-get clean all && apt-get autoclean && rm -rf /var/lib/apt/lists/* \
    && cp apt.txt ${APP_HOME}/ \
    '
RUN bash -exc ': \
    && : "install users" \
    && if ! ( getent group $USER_GROUP 2>/dev/null );then groupadd -g $USER_GID $USER_GROUP;fi \
    && if ! ( getent passwd $USER_NAME 2>/dev/null );then useradd -s /bin/bash -d $USER_HOME -m -u $USER_UID -g $USER_UID $USER_NAME;fi \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    '
###
# ADD HERE CUSTOM THINGS TO ADD TO BASEIMAGE WHICH ARE REQUIRED AT BUILDTIMe
###
RUN \
    cd $APP_HOME \
    && cpanm Mail::IMAPClient JSON::WebToken Encode::IMAPUTF7 File/Tail.pm \
    && curl https://imapsync.lamiral.info/dist/imapsync -sSLo sbin/imapsync \
    && chmod +x sbin/imapsync

FROM base AS appsetup
RUN bash -exc ': \
    && : "install dev packages" \
    && cat apt.txt|grep -vE "^\s*#"|tr "\n" " " > ${APP_HOME}/apt.dev.txt \
    && apt-get update -qq \
    && apt-get install -qq -y $(cat ${APP_HOME}/apt.dev.txt) \
    && apt-get clean all && apt-get autoclean && rm -rf /var/lib/apt/lists/* \
    '
WORKDIR $USER_HOME
ADD --chown=${USER_NAME}:${USER_GROUP} bin/  bin/
ADD --chown=${USER_NAME}:${USER_GROUP} sys/  sys/

###
# ADD HERE CUSTOM THINGS TO ADD TO BASEIMAGE WHICH ARE REQUIRED AT BUILDTIMe
###

FROM appsetup AS final
###
# ADD HERE CUSTOM BUILD PROJECT SETUP
###
ADD local/imapfilter imapfilter/
RUN cd imapfilter && make
RUN bash -exc ': \
    && : "fixperms" \
    && while read f;do chown -Rf $USER_NAME $f;done < <( find $USER_HOME $APP_HOME -not -uid ${USER_UID} ) \
    '

FROM base AS runner
RUN --mount=type=bind,from=final,target=/s bash -exc ': \
    && for i in /home/ $APP_HOME/ $USER_HOME/;do rsync -aAH --numeric-ids /s${i} ${i};done \
    && ln -sfv ${APP_HOME}/imapfilter ${USER_HOME}/.imapfilter \
    '
WORKDIR $USER_HOME
# image will drop privileges itself using gosu at the end of the entrypoint
# run settings
USER ${IMAGE_USER_RUNNER}
###
# ADD HERE CUSTOM RUNTIME PROJECT SETUP
###
ADD --chown=${USER_NAME}:${USER_GROUP} .git .git/
CMD []
ENTRYPOINT ["docker-entrypoint.sh"]
