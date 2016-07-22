#!/bin/bash -e

echo "Installing Alien4Cloud"


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

# install unzip if not found
command -v unzip >/dev/null 2>&1 || { install_packages "unzip"; }

# check dependencies
command -v unzip >/dev/null 2>&1 || { echo "I require unzip but it's not installed.  Aborting." >&2; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "I require wget but it's not installed.  Aborting." >&2; exit 1; }
command -v jar >/dev/null 2>&1 || { echo "I require jar but it's not installed.  Aborting." >&2; exit 1; }

# create user
sudo useradd alien4cloud

# create log folder
echo "Make log dir"
if [ ! -d /var/log/alien4cloud ]; then
  sudo mkdir -p /var/log/alien4cloud
fi

echo "Make etc dir"
if [ ! -d /etc/alien4cloud ]; then
  sudo mkdir -p /etc/alien4cloud
fi

echo "Make tmp dir"
if [ ! -d /tmp/alien4cloud ]; then
	sudo mkdir -p /tmp/alien4cloud
fi

# create application folder
echo "Make opt dir"
if [ ! -d /opt/alien4cloud ]; then
  sudo mkdir -p /opt/alien4cloud
fi

# create data folder
echo "Make data dir $DATA_DIR"
if [ ! -d $DATA_DIR ]; then
  sudo mkdir -p $DATA_DIR
fi

# copy files
echo "Download webapp from ${APPLICATION_URL}"
sudo wget --quiet -O /tmp/alien4cloud/alien.war "${APPLICATION_URL}"
sudo cp /tmp/alien4cloud/alien.war /opt/alien4cloud/alien.war

# add config
echo "Adding config files"
sudo unzip -qo /tmp/alien4cloud/alien.war -d /tmp/alien4cloud/
sudo jar -xf /tmp/alien4cloud/WEB-INF/lib/alien4cloud-rest-api-$ALIEN_VERSION.jar alien4cloud-config.yml
sudo mv alien4cloud-config.yml /etc/alien4cloud/
sudo cp /tmp/alien4cloud/WEB-INF/classes/log4j.properties /etc/alien4cloud/
sudo rm -rf /tmp/alien4cloud

# add the appropriate user
echo "Change folder ownership"
sudo chown -R alien4cloud:alien4cloud /var/log/alien4cloud
sudo chown -R alien4cloud:alien4cloud /opt/alien4cloud
sudo chown -R alien4cloud:alien4cloud /etc/alien4cloud

# add init script and start service
echo "Preparing services"
sudo bash -c "sed -e 's/\\\${APP_ARGS}/${APP_ARGS}/' $bin/alien.sh > /etc/init.d/alien"
sudo chmod +x /etc/init.d/alien

sudo update-rc.d alien defaults 95 10
