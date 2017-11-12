#!/bin/bash

VERSION="DocktorCI version v0.1.0"
PROG="dockerCI.sh"

declare -A ENV

# Image names (which are also docker-compose service names)
ENV[JENKINS_OFFICIAL]="jenkins-official"
ENV[JENKINS_MASTER]="jenkins-master"
ENV[JENKINS_SLAVE]="jenkins-slave"
ENV[JENKINS_SLAVE_DOCKER]="jenkins-slave-docker"

# Home of master and slave (not necessary on the same host)
ENV[JENKINS_HOME]="/home/jenkins/master"
ENV[JENKINS_SLAVE_HOME]="/home/jenkins/slave"

# General configuration
ENV[JENKINS_LOGS]="/var/log/jenkins"
ENV[SECRET_DIR]="/home/jenkins/.secrets"
ENV[JENKINS_UID]=
ENV[JENKINS_GID]=
ENV[SLAVE_HOST]=

# Pretty display of the env array
displayComposeEnv() {
  printArray ENV " ${star} "
}

# Import generic script functions
. utils.sh


###############################################################################
# USAGE
###############################################################################
usageTitle() {
  echo -en "\n${Red}${1}${RCol}"
}
usage() {
  local message=${1}
  if [[ "${message}" != "" ]]; then
    echo "USAGE: ${PROG} ${message}"
    exit 1
  fi
  echo ${VERSION}
  usageTitle "SYNOPSIS"
  echo -e "
         This script allow you to ease the control of all docker-compose commands.
         You can control your jenkins master and slave (build time and run time)."
  usageTitle "SYNOPSIS"
  echo -e "
         ${Red}docktor.sh ${Cya}[OPTIONS]${RCol} ${Red}COMMAND${RCol} ${Blu}[ARG]${RCol}"
  usageTitle "OPTIONS"
  echo -e "
         ${Cya}-r${RCol},${Cya}--rebuild ${RCol}[${Cya}all${RCol}]
         Force to rebuild docker image (slave or master depending the main command).
         It deletes containers and images if exist.
         If you specify ${Cya}all${RCol} argument, it will also rebuild the parent image, which
         take much more time to rebuild.

         ${Cya}-s${RCol},${Cya}--slave-host ${Gre}145.239.78.98${RCol}
         Specify a slave host (ip) for the jenkins master configuration"

  usageTitle "COMMAND"
  echo -e "
         ${Red}start ${RCol}[${Blu}slave${RCol}|${Blu}master${RCol}]
         Start the slave or master depending the argument. Docker images are build
         if they doesn't not already exist."
  echo -e "
         ${Red}stop${RCol}
         Stop all running container (slave or master). Behind the hood it do a
         docker-compose down so it shut down everything. We can't just stop a service
         because of a docker-compose bug.
         More info: ${Blu}https://github.com/docker/compose/issues/1113${RCol}"
  echo -e "
         ${Red}clean${RCol}
         Remove everything (containers and images)"
  echo
  exit 0
}

###############################################################################
# DOCKER-COMPOSE BUILD AND START COMMANDS
###############################################################################
doBuild() {
  local service=${1}

  set -e
  info "Building '${service}'..."
  displayComposeEnv
  JENKINS_UID=${ENV[JENKINS_UID]}\
  JENKINS_GID=${ENV[JENKINS_GID]}\
  JENKINS_HOME=${ENV[JENKINS_HOME]}\
  JENKINS_LOGS=${ENV[JENKINS_LOGS]}\
  SECRET_DIR=${ENV[SECRET_DIR]}\
  SLAVE_HOST=${ENV[SLAVE_HOST]}\
  JENKINS_SLAVE_HOME=${ENV[JENKINS_SLAVE_HOME]}\
  docker-compose build ${service}
  set +e
}

doStart() {
  local service=${1}

  info "Starting ${service} in daemon mode"
  command "jenkins -c \"docker-compose up -d ${service}\""
  displayComposeEnv
  set -e
  JENKINS_UID=${ENV[JENKINS_UID]}\
  JENKINS_GID=${ENV[JENKINS_GID]}\
  JENKINS_HOME=${ENV[JENKINS_HOME]}\
  JENKINS_LOGS=${ENV[JENKINS_LOGS]}\
  SECRET_DIR=${ENV[SECRET_DIR]}\
  SLAVE_HOST=${ENV[SLAVE_HOST]}\
  JENKINS_SLAVE_HOME=${ENV[JENKINS_SLAVE_HOME]}\
  docker-compose up -d ${service}
  set +e
}

###############################################################################
# START MASTER PROCESS
###############################################################################
startMaster() {
  local rebuild=${1}
  local rebuildAll=${2}
  local jenkinsOfficial=${ENV[JENKINS_OFFICIAL]}
  local jenkinsMaster=${ENV[JENKINS_MASTER]}
  local jenkinsHome=${ENV[JENKINS_HOME]}
  local jenkinsLogs=${ENV[JENKINS_LOGS]}
  local secretDir=${ENV[SECRET_DIR]}

  if [[ "${rebuildAll}" == "true" ]]; then
    deleteDockerImage ${jenkinsOfficial}
  fi
  if [[ "${rebuild}" == "true" ]]; then
    deleteDockerImage ${jenkinsMaster}
  fi
  verifyDockerImageExist ${jenkinsOfficial}
  if [[ $? -ne 0 ]]; then
    doBuild ${jenkinsOfficial}
  fi
  verifyDockerImageExist ${jenkinsMaster}
  if [[ $? -ne 0 ]]; then
    doBuild ${jenkinsMaster}
  fi

  verifyDirectoryExist "${jenkinsHome}"
  if [[ $? -ne 0 ]]; then
    set -e
    mkdir -p ${jenkinsHome} && chown jenkins:jenkins ${jenkinsHome}
    set +e
    check "Jenkins home directory '${jenkinsHome}' created successfully"
  fi

  verifyDirectoryExist "${jenkinsLogs}"
  if [[ $? -ne 0 ]]; then
    set -e
    mkdir -p ${jenkinsLogs} && chown jenkins:jenkins ${jenkinsLogs}
    set +e
    check "Jenkins log directory '${jenkinsLogs}' created successfully"
  fi

  verifyDirectoryExist "${secretDir}"
  if [[ $? -ne 0 ]]; then
    fail "Secrets directory '${secretDir}' doesn't exist."
    error "You must create this directory with all secrets inside in order to continue" 1
  fi

  doStart ${jenkinsMaster}
}

###############################################################################
# START SLAVE PROCESS
###############################################################################
startSlave() {
  local rebuild=${1}
  local rebuildAll=${2}
  local slave=${ENV[JENKINS_SLAVE]}
  local slaveDocker=${ENV[JENKINS_SLAVE_DOCKER]}
  local slaveHome=${ENV[JENKINS_SLAVE_HOME]}
  local authKeyDir="${slaveHome}/.ssh"
  local authKey="${authKeyDir}/authorized_keys"
  local pubKey="${ENV[SECRET_DIR]}/jenkins/slave/id_rsa.pub"

  if [[ "${rebuildAll}" == "true" ]]; then
    deleteDockerImage ${slave}
  fi
  if [[ "${rebuild}" == "true" ]]; then
    deleteDockerImage ${slaveDocker}
  fi
  verifyDockerImageExist ${slave}
  if [[ $? -ne 0 ]]; then
    doBuild ${slave}
  fi
  verifyDockerImageExist ${slaveDocker}
  if [[ $? -ne 0 ]]; then
    doBuild ${slaveDocker}
  fi

  verifyDirectoryExist ${slaveHome}
  if [[ $? -ne 0 ]]; then
    set -e
    mkdir -p ${slaveHome}
    chown jenkins:jenkins ${slaveHome}
    set +e
    check "Jenkins slave home directory '${slaveHome}' created successfully"
  fi

  verifyFileExist ${authKey}
  if [[ $? -ne 0 ]]; then
    verifyFileExist ${pubKey}
    if [[ $? -ne 0 ]]; then
      error "No public key found in '${pubKey}', unable to create authorized_keys for slave." 1
    fi
    set -e
    mkdir -p ${authKeyDir}
    cp ${pubKey} ${authKey}
    chmod 700 ${authKeyDir} && chmod 600 ${authKey}
    chown -R jenkins:jenkins ${authKeyDir}
    set +e
    check "SSH Public key of master successfully copied in '${authKey}'"
  fi

  doStart ${slaveDocker}
}

###############################################################################
# STOP EVERYTHING RUNNING
###############################################################################
stop() {
  info "Stopping jenkins running on this host..."
  set -e
  JENKINS_UID=${ENV[JENKINS_UID]}\
  JENKINS_GID=${ENV[JENKINS_GID]}\
  JENKINS_HOME=${ENV[JENKINS_HOME]}\
  JENKINS_LOGS=${ENV[JENKINS_LOGS]}\
  SECRET_DIR=${ENV[SECRET_DIR]}\
  SLAVE_HOST=${ENV[SLAVE_HOST]}\
  JENKINS_SLAVE_HOME=${ENV[JENKINS_SLAVE_HOME]}\
  docker-compose down
  set +e
}

###############################################################################
# STOP EVERYTHING RUNNING AND REMOVE ALL CONTAINERS AND IMAGES
###############################################################################
clean() {
  stop
  info "Removing all images on this host..."
  deleteDockerImage ${ENV[JENKINS_SLAVE]}
  deleteDockerImage ${ENV[JENKINS_SLAVE_DOCKER]}
  deleteDockerImage ${ENV[JENKINS_OFFICIAL]}
  deleteDockerImage ${ENV[JENKINS_MASTER]}
}

###############################################################################
# MAIN - PROCESS ARGS
###############################################################################
exitIfActionAlreadyDefined() {
  local previsouAction=${1}
  local currentAction=${2}
  if [[ "${previsouAction}" != "${UNSET}" ]]; then
    error "Invalid ${currentAction} argument: command already defined." 1
  fi
}
main() {
  local action=${UNSET}
  local target=${UNSET}
  local slaveHost=${UNSET}
  local rebuild="false"
  local rebuildAll="false"

  # Display usage if no argument
  usageIfNoArgument ${@}

  # Parse command line
  while true ; do
    case "${1}" in

      -h|--help)
        usage;;

      start)
        exitIfActionAlreadyDefined ${action} ${1}
        action=${1}
        target=${2}
        if [[ "${target}" != "master" && "${target}" != "slave" ]]; then
          error "Invalid ${action} argument '${target}'"
          usage "${action} [master|slave]"
        fi
        shift 2;;

      stop)
        exitIfActionAlreadyDefined ${action} ${1}
        action=${1}
        shift 1;;

      -s|--slave-host)
        slaveHost=${2}
        shift 2;;

      -r|--rebuild)
        rebuild="true"
        if [[ "${2}" == "all" ]]; then
          rebuildAll="true"
          shift 1
        fi
        shift 1;;

      clean)
        exitIfActionAlreadyDefined ${action} ${1}
        action=${1}
        shift 1;;

      "")
        break;;

      *)
        error "Invalid argument '${1}'"
        usage;;
    esac
  done

  # Exit if the user jenkins does not exist
  verifyUserExist "jenkins" 1
  ENV[JENKINS_UID]=$(id -u jenkins)
  ENV[JENKINS_GID]=$(id -g jenkins)

  # Display user if no action set
  if [[ "${action}" == "${UNSET}" ]]; then
    usage
  fi

  # Display the status of the optional --slave-host option
  if [[ "${slaveHost}" == "${UNSET}" ]]; then
    slaveHost=$(getMainIp)
    warn "No option --slave-host detected"
    check "Using local IP as slave host: ${slaveHost}"
  else
    check "Using '${slaveHost}' as slave host"
  fi
  ENV[SLAVE_HOST]=${slaveHost}

  # Do actions
  if [[ "${rebuild}" == "true" ]]; then
    stop
  fi
  if [[ "${action}" == "start" ]]; then
    if [[ "${target}" == "master" ]]; then
      startMaster ${rebuild} ${rebuildAll}
    else
      startSlave ${rebuild} ${rebuildAll}
    fi

  elif [[ "${action}" == "clean" ]]; then
    clean
  else
    stop
  fi
}

main ${@}
