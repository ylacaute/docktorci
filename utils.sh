#!/bin/bash



UNSET="UNSET"

###############################################################################
# COLOR DEFINITION
###############################################################################

# Reset color
RCol='\e[0m'

# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';



###############################################################################
# NICE UNICODE CHARACTER (WITH COLOR)
###############################################################################
check="${BGre}\U1d00c${RCol}"
cross="${BRed}\Ud7${RCol}"
star="${Cya}\U2605${RCol}"
warn="${BYel}\U26a0${RCol}"



###############################################################################
# COMMON FUNCTIONS
###############################################################################

# Display an error message and exit the script if an exitCode has been given
error() {
  local exitMessage=${1}
  local exitCode=${2}

  >&2 echo -e ${Red}${exitMessage}${RCol}
  exitIfCodeNotEmpty ${exitCode}
}

exitIfCodeNotEmpty() {
  local exitCode=${1}

  if [[ "${exitCode}" != "" ]]; then
     exit ${exitCode}
  fi
}

check() {
  echo -e " ${check} ${1}"
}

fail() {
  echo -e " ${cross} ${1}"
}

warn() {
  echo -e " ${warn} ${Yel}${1}${RCol}"
}

info() {
  echo -e "${Cya}${1}${RCol}"
}

command() {
  echo -e " ${star} ${BWhi}COMMAND: ${1}${RCol}"
}

# Exit if the user given in argument doesn't exist
verifyUserExist() {
  local user=${1}
  local exitCode=${2}

  id -u ${user} > /dev/null 2>&1
  if [[ ${?} -eq 0 ]]; then
    check "User '${user}' exists (UID=$(id -u ${user}), GID=$(id -u ${user}))"
  else
    fail "User '${user}' doesn't exist on this system, aborting" 1
    exitIfCodeNotEmpty ${exitCode}
  fi
}

printArray() {
  local -n array
  array=$1
  prefix=$2

  for key in "${!array[@]}"; do
    if [[ "${array[$key]}" == "" ]]; then
      keyColor=${BBla}
    else
      keyColor=${Bla}
    fi
    echo -e " ${prefix} ${keyColor}$key: ${RCol}${array[$key]}"
  done
}

echoTitle() {
  echo -e "${Red}${1}${RCol}"
}


# Return the absolute path of this script
getScriptDirectory() {
  local source="${BASH_SOURCE[0]}"
  local dir
  # resolve source until the file is no longer a symlink
  while [ -h "${source}" ]; do
    dir="$( cd -P "$( dirname "${source}" )" && pwd )"
    source="$(readlink "${source}")"
    # if source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ ${source} != /* ]] && source="${dir}/${source}"
  done
  dir="$( cd -P "$( dirname "${source}" )" && pwd )"
  echo "${dir}"
}


getMainIp() {
  hostname -I | cut -d' ' -f1
}

verifyDirectoryExist() {
  local path=${1}
  if [ -d "${path}" ]; then
    # Control will enter here if $DIRECTORY exists.
    check "Jenkins home directory exists: ${path}"
    return 0
  else
    warn "Jenkins home directory doesn't exist"
    return 1
  fi
}


###############################################################################
# DOCKER UTILS
###############################################################################

# Return "true" if the image name exist, "false" otherwise
verifyDockerImageExist() {
  local image=${1}
  docker images | grep ${image} > /dev/null 2>&1
  if [[ ${?} -eq 0 ]]; then
    check "Docker image '${image}' exists."
    return 0
  else
    warn "Docker image '${image}' doesn't exist" 1
    return 1
  fi
}

deleteDockerImage() {
  local image=${1}

  info "Deleting '${image}' image..."
  docker images | grep ${image} > /dev/null 2>&1
  if [[ ${?} -eq 0 ]]; then
    set -e
    docker rmi ${image} -f
    set +e
  fi
  check "Docker image '${image}' deleted"
}

deleteRunningContainer() {
  local image=${1}

  containerId=$(docker ps -a | grep "${image}" | awk '{print $1}')
  echo "containerId to delete : ${containerId} "
  if [[ ${containerId} != "" ]]; then
    docker rm containerId
  fi
  check "Docker container from image '${image}' deleted"
}

usageIfNoArgument() {
  if [[ ${#} -eq 0 ]]; then
    usage
  fi
}

