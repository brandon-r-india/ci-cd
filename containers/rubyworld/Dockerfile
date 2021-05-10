FROM ubuntu:20.04 as seedling1
CMD ["/bin/bash"]

RUN apt-get -qq update \
   && apt-get -qq install \
      curl \
      wget \
      unzip \
      vim

RUN echo 'export HISTTIMEFORMAT="%F	%T	"\n\
'\
>> /etc/bash.bashrc

ARG DOCKER_ENV=default
RUN   echo 'if [ -d ${HOME}/_assets/bash_history/ ]; then export HISTFILE="${HOME}/_assets/bash_history/history.'$DOCKER_ENV'"; fi\
'\
>> /etc/bash.bashrc


FROM seedling1 as seedling
RUN echo 'alias ls="ls -Altr --color=auto"\n\
export PS1="${debian_chroot:+($debian_chroot)}\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;31m\]\h:\[\033[0;37m\]\w\[\033[0m\]\$ " \n\
'\
>> /root/.bashrc

RUN apt-get -qq clean


FROM seedling as seed1

### GEN EDS- yarrgh ###
RUN apt-get -qq update \
   && apt-get -qq install -y \
   gnupg2 \
   iputils-ping \
   software-properties-common \
   apt-transport-https \
   ca-certificates \
   gnupg-agent

RUN echo '\n\
### FUNCTIONS ###\n\
function showcolors { for bg in `seq 0 9`; do for fg in `seq 0 9`; do echo -n "`expr $fg` `expr $bg`: " && color `expr $fg` `expr $bg` "Tyler & Corey"; echo; done; done }\n\
alias colors=showcolors\n\
function color  { echo -n "$(tput setaf $1;tput setab $2)${3}$(tput sgr 0) "; }\n\
function green  { color 4 2 "${*}"; }\n\
function yellow { color 0 3 "${*}"; }\n\
function red    { color 9 1 "${*}"; }\n\
function blue   { color 6 4 "${*}"; }\n\
function cyan   { color 9 6 "${*}"; }\n\
function grey   { color 0 7 "${*}"; }\n\
function pass   { echo; echo "$(green PASS: ${*})"; echo; }\n\
function warn   { echo; echo "$(yellow PASS: ${*})"; echo; }\n\
function fail   { echo; echo "$(red FAIL: ${*})"; echo; }\n\
function info   { echo; echo "$(grey INFO: ${*})"; echo; }\n\
green $(grep "DISTRIB_DESCRIPTION" /etc/lsb-release) && echo\n\
blue "python:"; python --version\n\
blue "pip: "; pip --version\
'\
>> /etc/bash.bashrc

RUN apt-get -qq clean

FROM seed1 as seed2
RUN apt-get -qq install -y \
python \
python3-pip \
&& apt-get -qq clean

FROM seed2 as seed
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
&& update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1



FROM seed as top

FROM top as git
RUN apt-get -qq update \
&& apt-get -qq install \
git \
&& apt-get clean

RUN apt-get -qq install \
sudo


FROM git as user
ARG gituser=$gituser
RUN useradd -ms /bin/bash -U $gituser \
&& echo "ALL ALL=(ALL) NOPASSWD: ALL"\
>>/etc/sudoers


FROM user as security
ARG THISUSER=$gituser
ARG HOMEPATH=/home
ARG LOCALHOMESAFE=$LOCALHOMESAFE

# THESE SHOULD NOT *need* TO CHANGE
ARG SAFEPATH=\\$HOMEPATH
ARG USERHOME=$HOMEPATH/$THISUSER
ARG SAFEHOME=$SAFEPATH\\/$THISUSER
ENV GIT_SSH=$USERHOME/bin/git-ssh
ARG GIT_CONFIG=$USERHOME/.gitconfig
ARG KNOWN_HOSTS=$USERHOME/.ssh/known_hosts
ARG GIT_IGNORE_GLOBAL=$USERHOME/.gitignore_global
COPY assets.docker/git-ssh $GIT_SSH
COPY assets.docker/.gitconfig $GIT_CONFIG
COPY assets.docker/known_hosts $KNOWN_HOSTS
COPY assets.docker/.gitignore_global $GIT_IGNORE_GLOBAL

ARG SSH_PRIVATE_KEY_PATH=$USERHOME/.ssh
ARG SSH_PRIVATE_KEY
ARG SSH_PRIVATE_KEY_STREAM
RUN echo "${SSH_PRIVATE_KEY_STREAM}" > $SSH_PRIVATE_KEY_PATH/$SSH_PRIVATE_KEY

RUN chmod 700 $USERHOME/.ssh \
&& chmod 755 $USERHOME/bin \
&& chmod 755 $GIT_SSH \
&& chmod 600 $KNOWN_HOSTS \
&& chmod 644 $GIT_CONFIG \
&& chmod 644 $GIT_IGNORE_GLOBAL \
&& sed -i 's/'$LOCALHOMESAFE'/'$SAFEHOME'/' $GIT_CONFIG \
&& chmod 600 $SSH_PRIVATE_KEY_PATH/$SSH_PRIVATE_KEY \
&& chown -R $THISUSER:$THISUSER $USERHOME


ARG GITTOKEN=$USERHOME/.ssh/GITTOKEN
ENV GITTOKEN=$USERHOME/.ssh/GITTOKEN
COPY assets.docker/GITTOKEN $GITTOKEN
ARG HEROKUTOKEN=$USERHOME/.ssh/HEROKUTOKEN
ENV HEROKUTOKEN=$USERHOME/.ssh/HEROKUTOKEN
COPY assets.docker/HEROKUTOKEN $HEROKUTOKEN
ENV GITUSER=$THISUSER
ENV GITLOGIN=$THISUSER@gmail.com
RUN chown $THISUSER:$THISUSER $GITTOKEN

#echo 'export GITTOKEN=$(cat $GITTOKEN)' >>$USERHOME/.bashrc
USER $THISUSER

FROM security as nodeinstall
RUN git clone https://github.com/nvm-sh/nvm.git ~/.nvm

FROM nodeinstall as nodeinstall0
### NVM *must have* NVM_DIR
ENV NVM_DIR=$USERHOME/.nvm
ENV NVM_HOME=$NVM_DIR
RUN echo $([ -s $NVM_DIR/nvm.sh ] && . $NVM_DIR/nvm.sh && [ -s $NVM_DIR/bash_completion ] && . $NVM_DIR/bash_completion && nvm install --lts)


FROM nodeinstall0 as rvminstall
#RUN apt-get -qq update \
#&& apt-get -qq install \
#ruby-full \
#&& apt-get clean

RUN sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
&& curl -sSL https://get.rvm.io | sudo bash -s stable --ruby \
&& echo 'source /usr/local/rvm/scripts/rvm\n\
'\
>>$USERHOME/.bashrc \
&& echo 'rvm_silence_path_mismatch_check_flag=1\n\
'\
>>$USERHOME/.rvmrc

FROM rvminstall as rvmconfig
RUN /usr/local/rvm/bin/rvm get stable --autolibs=enable \
& sudo usermod -a -G rvm $THISUSER


FROM rvmconfig as rvmgemupdate
RUN /usr/local/rvm/bin/rvm \
&& echo "gem: --no-document" >> ~/.gemrc \
&& PATH="/usr/local/rvm/rubies/default/bin:$PATH" /usr/local/rvm/rubies/default/bin/gem update --system


FROM rvmgemupdate as rvmruby
RUN /usr/local/rvm/bin/rvm install ruby

FROM rvmruby as rvmrails
RUN /usr/local/rvm/rubies/default/bin/gem install rails

FROM rvmrails as sqlite
RUN sudo apt-get -qq install \
sqlite3 \
&& sudo apt-get clean

FROM sqlite as tzdata
RUN sudo ln -fs /usr/share/zoneinfo/CST6CDT /etc/localtime \
&& sudo DEBIAN_FRONTEND=noninteractive \
apt-get install -y --no-install-recommends \
tzdata

#RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install \
#postgresql postgresql-contrib libpq-dev \
#&& cp -p /var/lib/postgresql/10/main/postgresql.auto.conf /var/lib/postgresql/10/main/postgresql.conf \
#&& echo 'export postgre_data_directory=/var/lib/postgresql/10/main' >>/etc/bash.bashrc
#ENV postgre_data_directory='/var/lib/postgresql/10/main'

#/usr/lib/postgresql/10/bin/postgres
#/etc/postgresql/10/main/postgresql.conf
#su - postgres

FROM tzdata as bashrc
ARG DEFAULT_RUBY_VER=$DEFAULT_RUBY_VER
ARG DEFAULT_RAILS_VER=$DEFAULT_RAILS_VER

run echo ${DEFAULT_RUBY_VER} \
&& echo ${DEFAULT_RUBY_VER}

RUN echo '### NODE ###\n\
cyan "Updating nvm:" && echo $(cd .nvm && git pull)\n\
if  ! command -v nvm >/dev/null; then\n\
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm\n\
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion\n\
fi\n\
#echo $PATH\n\
function nodever() {\n\
  if [ ! -z $1 ]; then\n\
    nvm install ${1} >/dev/null 2>&1 && nvm use ${_} > /dev/null 2>&1\\\n\
      && nvm alias default ${_} > /dev/null 2>&1; blue "Node:"; node -v; else\n\
    yellow "Use nodever to install or switch node versions:" && echo -e "\n usage: nodever [ver]"; blue "Node:"; node -v && blue "nvm:"; nvm -v; fi;\n\
}\n\
nodever\n\
'\
>>$USERHOME/.bashrc

RUN echo '### YARN (NEEDS NVM) ###\n\
  if ! command -v yarn >/dev/null 2>&1; then grey "Getting yarn: " && npm install --global yarn >/dev/null; fi\n\
'\
>>$USERHOME/.bashrc


RUN echo '### RUBY RAILS ###\n\
export DEFAULT_RUBY_VER='$DEFAULT_RUBY_VER'\n\
export DEFAULT_RAILS_VER='$DEFAULT_RAILS_VER'\n\
function rubyver() {\n\
  if [ $# -eq 0 ]; then\n\
    yellow "Use rubyver to switch ruby & rails:" && echo -e "\\n usage: rubyver ruby-[X.Y.Z] [RAILSVER($DEFAULT_RAILS_VER)]"\n\
#    return ${LINENO}\n\
  fi\n\
  local RUBY_VER=${1} && local RAILS_VER=${2}\n\
  if [[ ${RAILS_VER} == ${DEFAULT_RAILS_VER} ]]; then RAILS_VER="";else RAILS_VER="-v ${RAILS_VER}";fi\n\
  if [ ! -z $1 ]; then\n\
    if [[ ! ${RUBY_VER} == $(rvm current) ]]; then\n\
      cyan "getting ruby:" && echo -n "${RUBY_VER} " && rvm install ${RUBY_VER} 2>/dev/null\\\n\
        && rvm --default use ${RUBY_VER} &&\n\
      cyan "getting rails:" && echo ${RAILS} && gem install rails ${RAILS_VER} 2>/dev/null\n\
      cyan "getting bundler" && gem install bundler\n\
    fi\n\
  fi\n\
  blue "Ruby:"; echo $(rvm current)\n\
  blue "Gem:"; gem -v\n\
  blue "Rails:"; rails -v\n\
  blue "Bundler:"; bundler -v\n\
  blue "YARN:"; yarn -v\n\
  blue "SQLite3:"; sqlite3 --version\n\
}\n\
\
rubyver \
  $(if [[ ! ${RUBY_VERSION} == ${DEFAULT_RUBY_VER} ]];then echo ${DEFAULT_RUBY_VER} ${DEFAULT_RAILS_VER};fi; exit)\n\
export HEROKUHOME=/usr/local/heroku/bin\n\
if [ ! -d $HEROKUHOME ] && [ -d ~/.nvm ]\n\
  then cyan "Getting heroku" && echo\n\
    source <(curl -sL https://cdn.learnenough.com/heroku_install) 2>/dev/null\n\
  else if ! command -v heroku;then export PATH=$PATH:$HEROKUHOME;fi\n\
fi\n\
blue "Heroku:"; heroku --version\n\
#grey "Ruby versions with:" && echo rvm list known\n\
#grey "install ruby with:" && echo rvm install ruby-[RUBY_VER] \&\& rvm --default use ruby-[RUBY_VER]\n\
#grey "install rails with:" && echo gem install rails -v [RAILS_VER]\n\
\n\
'\
>>$USERHOME/.bashrc

#RUN echo '### SET PERMISSIONS ###\n\
#chown '$THISUSER':'$THISUSER' '$USERHOME'/*\n\
#'\
#>>$USERHOME/.bashrc

ENV DOCKER_ENV=ruby
RUN echo '### SHARED HISTORY ###\n\
if [ -d ${HOME}/public.assets/bash_history/ ]; then export HISTFILE="${HOME}/public.assets/bash_history/history.${DOCKER_ENV}"; fi && green "Shared bash history at:" && echo ${HISTFILE}\n\
'\
>>$USERHOME/.bashrc

RUN echo '\n\
export PS1="\[\033[1;34m\]\u\[\033[0m\]@\[\033[1;31m\]\h:\[\033[0;37m\]\w\[\033[0m\]$ "\n\
alias ls="ls -Altr --color=auto"\n\
'\
>>$USERHOME/.bashrc


WORKDIR $USERHOME
EXPOSE 3000
RUN mkdir $USERHOME/code-store
VOLUME $USERHOME/code-store

FROM bashrc as vimrc
ARG line="set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab autoindent"
ARG line="$line\nset number"
ARG line="$line\nset nocompatible"
ARG line="$line\nsyntax on"
ARG line="$line\ncolo pablo"
ARG line="$line\nset cursorline"
ARG line="$line\nhi CursorLine   cterm=NONE ctermbg=237 ctermfg=NONE"
ARG line="$line\nhi CursorLineNr   cterm=NONE ctermbg=36 ctermfg=NONE"
RUN echo "$line" >$USERHOME/.vimrc

FROM vimrc as nmap
RUN sudo apt-get -qq install \
nmap \
&& sudo apt-get clean

RUN echo '\n\
nmap --top-ports 20 sbsystemsinc.com\n\
'\
>>$USERHOME/.bashrc
