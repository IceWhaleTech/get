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

echo '
  ________                  .___ __________               
 /  _____/  ____   ____   __| _/ \______   \___.__. ____  
/   \  ___ /  _ \ /  _ \ / __ |   |    |  _<   |  |/ __ \ 
\    \_\  (  <_> |  <_> ) /_/ |   |    |   \\___  \  ___/ 
 \______  /\____/ \____/\____ |   |______  // ____|\___  >
        \/                   \/          \/ \/         \/ 

'

###############################################################################
# Golbals                                                                     #
###############################################################################
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
remove_serveice(){
   ((EUID)) && sudo_cmd="sudo"
    $sudo_cmd  systemctl disable casaos
    if [ -f $service_path ]; then
        show 2 "Try stop CasaOS system service."
        $sudo_cmd systemctl stop casaos.service # Stop before generation
    fi
    $sudo_cmd rm $1
    $sudo_cmd rm $2
}

#######################################
# Custom Get Distribution function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   string
#######################################
get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

#######################################
# Custom uninstall docker function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   string
#######################################
unistall_docker(){
     ((EUID)) && sudo_cmd="sudo"
    lsb_dist=$( get_distribution )
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

    $sudo_cmd systemctl disable docker
    $sudo_cmd systemctl stop docker

    case "$lsb_dist" in

		ubuntu)
			$sudo_cmd apt-get purge docker-ce
            $sudo_cmd rm -rf /var/lib/docker
		;;

		debian|raspbian)
			$sudo_cmd apt-get purge docker-ce
		;;

		centos|rhel|sles)
			yum remove docker-ce
            rm -rf /var/lib/docker
		;;

		*)
			
		;;

	esac

}

# delete casaos serveice and casaos
remove_serveice $service_path $install_path/casaos

# delete casaos directory
remove_directory

show 0 "Uninstall succeed! \n The '/DATA' directory and docker need to be uninstalled manually "

