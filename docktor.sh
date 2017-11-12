#!/bin/bash

VERSION="DocktorCI version v0.1.0"
PROG="dockerCI.sh"

declare -A ENV
ENV[JENKINS_HOME]="/home/jenkins/master"
ENV[JENKINS_LOGS]="/var/log/jenkins"
ENV[JENKINS_OFFICIAL]="jenkins-official"
ENV[JENKINS_MASTER]="jenkins-master"
ENV[JENKINS_SLAVE]="jenkins-slave"
ENV[JENKINS_SLAVE_DOCKER]="jenkins-slave-docker"
ENV[JENKINS_SLAVE_HOME]="/home/jenkins/slave"
ENV[SECRET_DIR]="/home/jenkins/.secrets"
ENV[JENKINS_UID]=
ENV[JENKINS_GID]=
ENV[SLAVE_HOST]=

. utils.sh

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
         ${Cya}-r${RCol},${Cya}--rebuild${RCol}
         Force to rebuild docker images. Delete containers and images if exist.

         ${Cya}-s${RCol},${Cya}--slave-host ${Gre}145.239.78.98${RCol}
         Specify a slave host (ip) for the jenkins master configuration"

  usageTitle "COMMAND"
  echo -e "
         ${Red}start ${RCol}[${Blu}slave${RCol}|${Blu}master${RCol}]
         Start the slave or master depending the argument. Docker images are build
         if they doesn't not already exist."
  echo -e "
         ${Red}stop ${RCol}[${Blu}slave${RCol}|${Blu}master${RCol}]
         Stop a running slave or master depending the argument."

  echo
  exit 0
}

displayComposeEnv() {
  printArray ENV " ${star} "
}

doBuild() {
  local service=${1}

  set -e
  info "Building '${service}'..."
  displayComposeEnv
  JENKINS_UID=${ENV[JENKINS_UID]}\
  JENKINS_GID=${ENV[JENKINS_GID]}\
  JENKINS_HOME=${ENV[JENKINS_HOME]}\
  JENKINS_LOGS=${ENV[JENKINS_LOGS]}\
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
  su jenkins -c "\
    JENKINS_UID=${ENV[JENKINS_UID]}\
    JENKINS_GID=${ENV[JENKINS_GID]}\
    JENKINS_HOME=${ENV[JENKINS_HOME]}\
    JENKINS_LOGS=${ENV[JENKINS_LOGS]}\
    SLAVE_HOST=${ENV[SLAVE_HOST]}\
    JENKINS_SLAVE_HOME=${ENV[JENKINS_SLAVE_HOME]}\
    docker-compose up -d ${service}"
  set +e
}

startMaster() {
  local rebuild=${1}
  local jenkinsOfficial=${ENV[JENKINS_OFFICIAL]}
  local jenkinsMaster=${ENV[JENKINS_MASTER]}
  local jenkinsHome=${ENV[JENKINS_HOME]}
  local jenkinsLogs=${ENV[JENKINS_LOGS]}
  local secretDir=${ENV[SECRET_DIR]}

  if [[ "${rebuild}" == "true" ]]; then
    deleteDockerImage ${jenkinsOfficial}
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

startSlave() {
  local rebuild=${1}
  local slave=${ENV[JENKINS_SLAVE]}
  local slaveDocker=${ENV[JENKINS_SLAVE_DOCKER]}
  local slaveHome=${ENV[JENKINS_SLAVE_HOME]}

  if [[ "${rebuild}" == "true" ]]; then
    deleteDockerImage ${slave}
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

  doStart ${slaveDocker}
}

stop() {
  info "Stopping jenkins running on this host..."
  set -e
  JENKINS_UID=${ENV[JENKINS_UID]}\
  JENKINS_GID=${ENV[JENKINS_GID]}\
  JENKINS_HOME=${ENV[JENKINS_HOME]}\
  JENKINS_LOGS=${ENV[JENKINS_LOGS]}\
  SLAVE_HOST=${ENV[SLAVE_HOST]}\
  JENKINS_SLAVE_HOME=${ENV[JENKINS_SLAVE_HOME]}\
  docker-compose down
  set +e
}

main() {
  local action=${UNSET}
  local target=${UNSET}
  local slaveHost=${UNSET}
  local rebuild="false"

  # Display usage if no argument
  usageIfNoArgument ${@}

  # Parse command line
  while true ; do
    case "${1}" in

      -h|--help)
        usage;;

      start)
        if [[ "${action}" != "${UNSET}" ]]; then
          error "Invalid ${1} argument: command already defined." 1
        fi
        action=${1}
        target=${2}
        if [[ "${target}" != "master" && "${target}" != "slave" ]]; then
          error "Invalid ${action} argument '${target}'"
          usage "${action} [master|slave]"
        fi
        shift 2;;

      stop)
        if [[ "${action}" != "${UNSET}" ]]; then
          error "Invalid ${1} argument: command already defined." 1
        fi
        action=${1}
        shift 1;;

      -s|--slave-host)
        slaveHost=${2}
        shift 2;;

      -r|--rebuild)
        rebuild="true"
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
      startMaster ${rebuild}
    else
      startSlave ${rebuild}
    fi
  else
    stop
  fi
}

main ${@}
