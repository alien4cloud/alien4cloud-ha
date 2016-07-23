#!/bin/bash -e

# Try to guess the Operating System distribution
# The guessing algorithm is:
#   1- use lsb_release retrieve the distribution name (should normally be present it's listed as requirement of VM images in installation guide)
#   2- If lsb_release is not present check if yum is present. If yes assume that we are running Centos
#   3- Otherwise check if apt-get is present. If yes assume that we are running Ubuntu
#   4- Otherwise give-up and return "unknown"
#
# Any way the returned string is in lower case.
# This function prints the result to the std output so you should use the following form to retrieve it:
# os_dist="$(get_os_distribution)"
get_os_distribution () {
  rname="unknown"
  if  [[ "$(which lsb_release)" != "" ]]
    then
    rname=$(lsb_release -si | tr [:upper:] [:lower:])
  else
    if [[ "$(which yum)" != "" ]]
      then
      # assuming we are on Centos
      rname="centos"
    elif [[ "$(which apt-get)" != "" ]]
      then
      # assuming we are on Ubuntu
      rname="ubuntu"
    fi
  fi
  echo ${rname}
}

install_packages() {
  packages_to_install="$*"
  echo "Installing packages ${packages_to_install}"
  case "$(get_os_distribution)" in
    "ubuntu" | "debian" | "mint")
    LOCK="/tmp/lockaptget"

    while true; do
      if mkdir "${LOCK}" &>/dev/null; then
        echo "take apt lock"
        echo "$$>${LOCK}/pid"
        break;
      fi
      echo "waiting apt lock to be released..."
      sleep 2
    done
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
      echo "$NAME waiting for other software managers to finish..."
      sleep 2
    done
    sudo apt-get -y update > /dev/null 2>&1
    sudo apt-get -y install ${packages_to_install} > /dev/null 2>&1
    rm -rf "${LOCK}"
    echo "released apt lock"
    ;;
    "centos" | "redhat" | "fedora")
    sudo yum install -y install ${packages_to_install}
    ;;
  esac
}

// check that this env var is not empty
require_env () {
  VAR_NAME=$1
  if [ ! "${!VAR_NAME}" ]; then
    echo "Required env var <$VAR_NAME> not found !"
    echo "Required env var <$VAR_NAME> not found !" >&2; exit 1;
  else
    echo "The value for required var <$VAR_NAME> is: ${!VAR_NAME}"
  fi
}

// check that the csv list of env vars are not empty
require_envs () {
  VAR_LIST=$1
  IFS=',';
  for VAR_NAME in $VAR_LIST;
  do
    require_env ${VAR_NAME}
  done
}

# eval the config file and replace the listed env vars
# will not work if VAR_NAME or VAR_VALUE contains '@' (but will if they contain '/' !)
eval_conf_file () {
  SRC_FILE=$1
  DEST_FILE=$2
  VAR_LIST=$3

  sudo cp $SRC_FILE $DEST_FILE
  if [ ! -z "$VAR_LIST" ]; then
    for VAR_NAME in $(echo ${VAR_LIST} | tr ',' ' ')
    do
      VAR_VALUE="${!VAR_NAME}"
      sudo sed -i -e "s@%${VAR_NAME}%@${VAR_VALUE}@g" $DEST_FILE
    done
  fi
  echo "Content of $DEST_FILE"
  sudo cat $DEST_FILE
}

# check dependencies (list of dependencies)
require_bin () {
  BIN_LIST=$1
  IFS=',';
  for BIN_NAME in $BIN_LIST;
  do
    command -v ${BIN_NAME} >/dev/null 2>&1 || { echo "I require <${BIN_NAME}> but it's not installed.  Aborting." >&2; exit 1; }
  done
}

install_dependencies() {
  PACKAGE_NAMES=$1
  PACKAGES_TO_INSTALL=""
  IFS=',';
  for PACKAGE_NAME in $PACKAGE_NAMES;
  do
    if [ command -v ${BIN_NAME} >/dev/null 2>&1 ]; then
      echo "${BIN_NAME} was found, will not install it"
    else
      echo "${BIN_NAME} was not found, I will install it"
      PACKAGES_TO_INSTALL="${PACKAGES_TO_INSTALL} ${BIN_NAME}"
    fi
  done
  if [ ! "${PACKAGES_TO_INSTALL}" ]; then
    echo "I finally will install: ${PACKAGES_TO_INSTALL}"
    install_packages ${PACKAGES_TO_INSTALL}
  fi
}
