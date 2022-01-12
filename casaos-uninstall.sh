#!/bin/bash
#
#           CasaOS Uninstaller Script
#
#   GitHub: https://github.com/IceWhaleTech/CasaOS
#   Issues: https://github.com/IceWhaleTech/CasaOS/issues
#   Requires: bash, mv, rm, tr, type, grep, sed, curl/wget, tar
#
#   This script uninstalls CasaOS to your path.
#   Usage:
#
#   	$ curl -fsSL https://get.icewhale.io/uninstall.sh | bash
#   	  or
#   	$ wget -qO- https://get.icewhale.io/uninstall.sh | bash
#
#   In automated environments, you may want to run as root.
#   If using curl, we recommend using the -fsSL flags.
#
#   This should work on Mac, Linux, and BSD systems. Please
#   open an issue if you notice any bugs.
#

clear

###############################################################################
# Golbals                                                                     #
###############################################################################

UNSTALL_DOCKER=false
REMOVE_CASAOS_FILES=false
REMOVE_CASAOS_CONTAINERS=false

readonly TITLE="CasaOS Uninstaller"

readonly CASA_PATH=/casaOS/server

readonly casa_bin="casaos"
install_path="/usr/local/bin"
service_path=/usr/lib/systemd/system/casaos.service
if [ ! -d "/usr/lib/systemd/system" ]; then
    service_path=/lib/systemd/system/casaos.service
    if [ ! -d "/lib/systemd/system" ]; then
        service_path=/etc/systemd/system/casaos.service
    fi
fi

###############################################################################
# Helpers                                                                     #
###############################################################################

#######################################
# Check and install whiptail function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################

install_whiptail() {

    if [ -x "$(command -v whiptail)" ]; then
        echo ""
    else
        if [[ -r /etc/os-release ]]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [[ $lsb_dist == "openwrt" ]]; then
            opkg update
            opkg install whiptail
            #exit 1
        elif [[ $lsb_dist == "debian" ]] || [[ $lsb_dist == "ubuntu" ]] || [[ $lsb_dist == "raspbian" ]]; then
            ((EUID)) && sudo_cmd="sudo"
            $sudo_cmd apt -y update
            $sudo_cmd apt -y install whiptail
        elif [[ $lsb_dist == "centos" ]]; then
            yum update
            yum install newt
        fi
    fi
}

#######################################
# Uninstall Docker
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################

uninstall_docker() {
    if [[ $UNSTALL_DOCKER = true ]]; then
        ((EUID)) && sudo_cmd="sudo"
        $sudo_cmd apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras docker-scan-plugin
        $sudo_cmd apt-get autoremove -y --purge docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras docker-scan-plugin

        $sudo_cmd rm -rf /var/lib/docker /etc/docker
        $sudo_cmd rm /etc/apparmor.d/docker
        $sudo_cmd groupdel docker
        $sudo_cmd rm -rf /var/run/docker.sock
    fi
}

#######################################
# Uninstall CasaOS
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################

uninstall_casaos() {
    ((EUID)) && sudo_cmd="sudo"

    #stop and remove casaos service
    remove_serveice $service_path $install_path/casaos

    #remove casa containers
    if [[ $REMOVE_CASAOS_CONTAINERS = true ]]; then
        #stop all casaos‘s containers
        official_containers=$($sudo_cmd docker ps -a -q -f "label=origin=official")
        $sudo_cmd docker stop $official_containers
        $sudo_cmd docker rm $official_containers

        custom_containers=$($sudo_cmd docker ps -a -q -f "label=origin=custom")
        $sudo_cmd docker stop $custom_containers
        $sudo_cmd docker rm $custom_containers

        system_containers=$($sudo_cmd docker ps -a -q -f "label=origin=system")
        $sudo_cmd docker stop $system_containers
        $sudo_cmd docker rm $system_containers

        #remove all unuse images
        $sudo_cmd docker image prune -f

    fi

    #remove casa files
    if [[ $REMOVE_CASAOS_FILES = true ]]; then
        $sudo_cmd rm -fr /casaOS
    fi

}

#######################################
# Custom printing function
# Globals:
#   None
# Arguments:
#   $1 0:OK   1:FAILED
#   message
# Returns:
#   None
#######################################

show() {
    local color=("$@") output grey green red reset
    if [[ -t 0 || -t 1 ]]; then
        output='\e[0m\r\e[J' grey='\e[90m' green='\e[32m' red='\e[31m' reset='\e[0m'
    fi
    local left="${grey}[$reset" right="$grey]$reset"
    local ok="$left$green  OK  $right " failed="$left${red}FAILED$right " info="$left$green INFO $right "
    # Print color array from index $1
    Print() {
        [[ $1 == 1 ]]
        for ((i = $1; i < ${#color[@]}; i++)); do
            output+=${color[$i]}
        done
        echo -ne "$output$reset"
    }

    if (($1 == 0)); then
        output+=$ok
        color+=('\n')
        Print 1

    elif (($1 == 1)); then
        output+=$failed
        color+=('\n')
        Print 1

    elif (($1 == 2)); then
        output+=$info
        color+=('\n')
        Print 1
    fi
}

#######################################
# Custom remove casaos function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
remove_directory() {
    ((EUID)) && sudo_cmd="sudo"
    $sudo_cmd rm -fr /casaOS
}

#######################################
# Custom remove data directory function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
remove_DATA_directory() {
    ((EUID)) && sudo_cmd="sudo"
    $sudo_cmd rm -fr /DATA
}

#######################################
# Custom remove casaos function
# Globals:
#   None
# Arguments:
#   $1 0:service path   1:casaos path
# Returns:
#   None
#######################################
remove_serveice() {
    ((EUID)) && sudo_cmd="sudo"
    $sudo_cmd systemctl disable casaos
    if [ -f $service_path ]; then
        show 2 "Try stop CasaOS system service."
        $sudo_cmd systemctl stop casaos.service # Stop before generation
    fi
    $sudo_cmd rm $1
    $sudo_cmd rm $2
}

install_whiptail

if (whiptail --title "${TITLE}" --yesno --defaultno "Do you want uninstall docker?" 10 60); then
    UNSTALL_DOCKER=true
else
    if (whiptail --title "${TITLE}" --yesno --defaultno "Do you want remove all containers of CasaOS?" 10 60); then
        REMOVE_CASAOS_CONTAINERS=true
    fi
fi

if (whiptail --title "${TITLE}" --yesno --defaultno "Do you want remove all files of CasaOS?" 10 60); then
    REMOVE_CASAOS_FILES=true
fi

uninstall_docker

uninstall_casaos

whiptail --title "${TITLE}" --msgbox " Uninstall succeed! \n The '/DATA' directory and docker need to be uninstalled manually." 10 60
