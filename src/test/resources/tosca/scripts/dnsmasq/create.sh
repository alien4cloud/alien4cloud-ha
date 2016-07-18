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

install_dnsmasq () {
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
                sudo apt-get install -y dnsmasq > /dev/null 2>&1
                echo -e "\nIGNORE_RESOLVCONF=yes\n" | sudo tee -a /etc/default/dnsmasq > /dev/null 2>&1

	        	rm -rf "${LOCK}"
				echo "released apt lock"                
                ;;
             "centos" | "redhat" | "fedora")
                sudo yum install -y dnsmasq > /dev/null
                sudo chkconfig dnsmasq on
                ;;
        esac
}

install_dnsmasq
