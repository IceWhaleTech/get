#!/usr/bin/bash
#
#           CasaOS Installer Script
#
#   GitHub: https://github.com/IceWhaleTech/CasaOS
#   Issues: https://github.com/IceWhaleTech/CasaOS/issues
#   Requires: bash, mv, rm, tr, grep, sed, curl/wget, tar, smartmontools, parted, ntfs-3g, net-tools
#
#   This script installs CasaOS to your system.
#   Usage:
#
#   	$ curl -fsSL https://get.casaos.io | bash
#   	  or
#   	$ wget -qO- https://get.casaos.io | bash
#
#   In automated environments, you may want to run as root.
#   If using curl, we recommend using the -fsSL flags.
#
#   This only work on  Linux systems. Please
#   open an issue if you notice any bugs.
#



echo '
   _____                 ____   _____ 
  / ____|               / __ \ / ____|
 | |     __ _ ___  __ _| |  | | (___  
 | |    / _` / __|/ _` | |  | |\___ \ 
 | |___| (_| \__ \ (_| | |__| |____) |
  \_____\__,_|___/\__,_|\____/|_____/ 
                                      
   --- Made by IceWhale with YOU ---
'

set -e

###############################################################################
# GOLBALS                                                                     #
###############################################################################

((EUID)) && sudo_cmd="sudo"

readonly TITLE="CasaOS Installer"

# SYSTEM REQUIREMENTS
readonly MINIMUM_DISK_SIZE_GB="5"
readonly MINIMUM_MEMORY="400"
readonly MINIMUM_DOCER_VERSION="20"
readonly SUPPORTED_DIST=('debian' 'ubuntu' 'raspbian')
readonly CASA_DEPANDS_PACKAGE=('curl' 'smartmontools' 'parted' 'ntfs-3g' 'net-tools' 'whiptail' 'udevil' 'samba' 'cifs-utils')
readonly CASA_DEPANDS_COMMAND=('curl' 'smartctl' 'parted' 'ntfs-3g' 'netstat' 'whiptail' 'udevil' 'samba' 'mount.cifs')

# SYSTEM INFO
readonly PHYSICAL_MEMORY=$(LC_ALL=C free -m | awk '/Mem:/ { print $2 }')
readonly FREE_DISK_BYTES=$(LC_ALL=C df -P / | tail -n 1 | awk '{print $4}')
readonly FREE_DISK_GB=$((${FREE_DISK_BYTES} / 1024 / 1024))
readonly LSB_DIST="$(. /etc/os-release && echo "$ID")"
readonly UNAME_M="$(uname -m)"
readonly UNAME_U="$(uname -s)"
readonly NET_GETTER="curl -fsSLk"

readonly CASA_VERSION_URL="https://api.casaos.io/casaos-api/version"
readonly CASA_UNINSTALL_URL="https://raw.githubusercontent.com/IceWhaleTech/get/main/uninstall.sh"
readonly CASA_UNINSTALL_PATH=/usr/bin/casaos-uninstall

# REQUIREMENTS CONF PATH
# Udevil
readonly UDEVIL_CONF_PATH=/etc/udevil/udevil.conf

# COLORS
readonly COLOUR_RESET='\e[0m'
readonly aCOLOUR=(
    '\e[38;5;154m' # green  	| Lines, bullets and separators
    '\e[1m'        # Bold white	| Main descriptions
    '\e[90m'       # Grey		| Credits
    '\e[91m'       # Red		| Update notifications Alert
    '\e[33m'       # Yellow		| Emphasis
)


# CASAOS VARIABLES
TARGET_ARCH=""
TARGET_DISTRO="debian"
TARGET_OS="linux"
CASA_TAG="v0.3.6"
TMP_ROOT=/tmp/casaos-installer


# PACKAGE LIST OF CASAOS



CASA_SERVICES=(
    "casaos-gateway.service"
    "casaos-user-service.service"
    "casaos.service"
)

trap 'onCtrlC' INT
onCtrlC() {
    echo -e "${COLOUR_RESET}"
    exit 1
}


upgradePath="/var/log/casaos"
upgradeFile="/var/log/casaos/upgrade.log"

if [ -f "$upgradePath" ]; then
    ${sudo_cmd} rm "$upgradePath"
fi

if [ ! -d "$upgradePath" ]; then
    ${sudo_cmd} mkdir -p "$upgradePath"
fi

if [ ! -f "$upgradeFile" ]; then
    ${sudo_cmd} touch "$upgradeFile"
fi

###############################################################################
# Helpers                                                                     #
###############################################################################

#######################################
# Custom printing function
# Globals:
#   None
# Arguments:
#   $1 0:OK   1:FAILED  2:INFO  3:NOTICE
#   message
# Returns:
#   None
#######################################

Show() {
    # OK
    if (($1 == 0)); then
    	echo -e "- OK $2" | ${sudo_cmd} tee -a /var/log/casaos/upgrade.log
    # FAILED
    elif (($1 == 1)); then
     	echo -e "- FAILED $2" | ${sudo_cmd} tee -a /var/log/casaos/upgrade.log
	exit 1
    # INFO
    elif (($1 == 2)); then
    	echo -e "- INFO $2" | ${sudo_cmd} tee -a /var/log/casaos/upgrade.log
    # NOTICE
    elif (($1 == 3)); then
    	echo -e "- NOTICE $2" | ${sudo_cmd} tee -a /var/log/casaos/upgrade.log
    fi
}

Warn() {
    echo -e "${aCOLOUR[3]}$1$COLOUR_RESET"
}

GreyStart() {
    echo -e "${aCOLOUR[2]}\c"
}

ColorReset() {
    echo -e "$COLOUR_RESET\c"
}

# Check file exists
exist_file() {
    if [ -e "$1" ]; then
        return 1
    else
        return 2
    fi
}

###############################################################################
# FUNCTIONS                                                                   #
###############################################################################

# 1 Check Arch
Check_Arch() {
    case $UNAME_M in
    *aarch64*)
        TARGET_ARCH="arm64"
        ;;
    *64*)
        TARGET_ARCH="amd64"
        ;;
    *armv7*)
        TARGET_ARCH="arm-7"
        ;;
    *)
        Show 1 "Aborted, unsupported or unknown architecture: $UNAME_M"
        exit 1
        ;;
    esac
    Show 0 "Your hardware architecture is : $UNAME_M"
    CASA_PACKAGES=(
    "https://github.com/LinkLeong/casaos-alpha/releases/download/${CASA_TAG}/linux-${TARGET_ARCH}-casaos-${CASA_TAG}.tar.gz"
	"https://github.com/IceWhaleTech/CasaOS-Gateway/releases/download/v0.3.6-alpha7/linux-${TARGET_ARCH}-casaos-gateway-v0.3.6-alpha7.tar.gz"
        "https://github.com/IceWhaleTech/CasaOS-UserService/releases/download/${CASA_TAG}/linux-${TARGET_ARCH}-casaos-user-service-${CASA_TAG}.tar.gz"
	"https://github.com/zhanghengxin/CasaOS-UI/releases/download/${CASA_TAG}/linux-all-casaos-${CASA_TAG}.tar.gz"
)
}

# 2 Check Distribution
Check_Distribution() {
    sType=0
    notice=""
    case $LSB_DIST in
    *debian*)
        TARGET_DISTRO="debian"
        ;;
    *ubuntu*)
        TARGET_DISTRO="ubuntu"
        ;;
    *raspbian*)
        TARGET_DISTRO="raspbian"
        ;;
    *openwrt*)
        Show 1 "Aborted, OpenWrt cannot be installed using this script, please visit ${CASA_OPENWRT_DOCS}."
        exit 1
        ;;
    *alpine*)
        Show 1 "Aborted, Alpine installation is not yet supported."
        exit 1
        ;;
    *)
        sType=1
        notice="We have not tested it on this system and it may fail to install."
        ;;
    esac
    Show $sType "Your Linux Distribution is : $LSB_DIST $notice"
    if [[ $sType == 1 ]]; then
        if (whiptail --title "${TITLE}" --yesno --defaultno "Your Linux Distribution is : $LSB_DIST $notice. Continue installation?" 10 60); then
            Show 0 "Distribution check has been ignored."
        else
            Show 1 "Already exited the installation."
            exit 1
        fi
    fi
}

# 3 Check OS
Check_OS() {
    if [[ $UNAME_U == *Linux* ]]; then
        TARGET_OS="linux"
        Show 0 "Your System is : $UNAME_U"
    else
        TARGET_OS 1 "This script is only for Linux."
        exit 1
    fi
}

# 4 Check Memory
Check_Memory() {
    if [[ "${PHYSICAL_MEMORY}" -lt "${MINIMUM_MEMORY}" ]]; then
        Show 1 "requires atleast 1GB physical memory."
        exit 1
    fi
    Show 0 "Memory capacity check passed."
}

# 5 Check Disk
Check_Disk() {
    if [[ "${FREE_DISK_GB}" -lt "${MINIMUM_DISK_SIZE_GB}" ]]; then
        if (whiptail --title "${TITLE}" --yesno --defaultno "Recommended free disk space is greater than \e[33m${MINIMUM_DISK_SIZE_GB}GB\e[0m, Current free disk space is \e[33m${FREE_DISK_GB}GB.Continue installation?" 10 60); then
            Show 0 "Disk capacity check has been ignored."
        else
            Show 1 "Already exited the installation."
            exit 1
        fi
    else
        Show 0 "Disk capacity check passed."
    fi
}

# Check Port Use
Check_Port() {
    TCPListeningnum=$(${sudo_cmd} netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l)
    UDPListeningnum=$(${sudo_cmd} netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l)
    ((Listeningnum = TCPListeningnum + UDPListeningnum))
    if [[ $Listeningnum == 0 ]]; then
        echo "0"
    else
        echo "1"
    fi
}

# Update package

Update_Package_Resource() {
    GreyStart
    if [ -x "$(command -v apk)" ]; then
        ${sudo_cmd} apk update
    elif [ -x "$(command -v apt-get)" ]; then
        ${sudo_cmd} apt-get update
    elif [ -x "$(command -v dnf)" ]; then
        ${sudo_cmd} dnf check-update
    elif [ -x "$(command -v zypper)" ]; then
        ${sudo_cmd} zypper update
    elif [ -x "$(command -v yum)" ]; then
        ${sudo_cmd} yum update
    fi
    ColorReset
}

# Install depends package
Install_Depends() {
    for ((i = 0; i < ${#CASA_DEPANDS_COMMAND[@]}; i++)); do
        cmd=${CASA_DEPANDS_COMMAND[i]}
        if [[ ! -x "$(command -v $cmd)" ]]; then
            packagesNeeded=${CASA_DEPANDS_PACKAGE[i]}
            Show 2 "Install the necessary dependencies: $packagesNeeded "
            GreyStart
            if [ -x "$(command -v apk)" ]; then
                ${sudo_cmd} apk add --no-cache $packagesNeeded
            elif [ -x "$(command -v apt-get)" ]; then
                ${sudo_cmd} apt-get -y -q install $packagesNeeded --no-upgrade
            elif [ -x "$(command -v dnf)" ]; then
                ${sudo_cmd} dnf install $packagesNeeded
            elif [ -x "$(command -v zypper)" ]; then
                ${sudo_cmd} zypper install $packagesNeeded
            elif [ -x "$(command -v yum)" ]; then
                ${sudo_cmd} yum install $packagesNeeded
            elif [ -x "$(command -v pacman)" ]; then
                ${sudo_cmd} pacman -S $packagesNeeded
            elif [ -x "$(command -v paru)" ]; then
                ${sudo_cmd} paru -S $packagesNeeded
            else
                Show 1 "Package manager not found. You must manually install: $packagesNeeded"
            fi
            ColorReset
        fi
    done
}

Check_Dependency_Installation() {
    for ((i = 0; i < ${#CASA_DEPANDS_COMMAND[@]}; i++)); do
        cmd=${CASA_DEPANDS_COMMAND[i]}
        if [[ ! -x "$(command -v $cmd)" ]]; then
            packagesNeeded=${CASA_DEPANDS_PACKAGE[i]}
            Show 1 "Dependency \e[33m$packagesNeeded \e[0m installation failed, please try again manually!"
            exit 1
        fi
    done
}


#Configuration Addons
Configuration_Addons() {
    Show 2 "Configuration CasaOS Addons"
    #Remove old udev rules
    if [[ -f $PREFIX/etc/udev/rules.d/11-usb-mount.rules ]]; then
        ${sudo_cmd} rm -rf $PREFIX/etc/udev/rules.d/11-usb-mount.rules
    fi

    if [[ -f $PREFIX/etc/systemd/system/usb-mount@.service ]]; then
        ${sudo_cmd} rm -rf $PREFIX/etc/systemd/system/usb-mount@.service
    fi

    #Udevil
    if [[ -f $PREFIX${UDEVIL_CONF_PATH} ]]; then

        #Change udevil mount dir to /DATA
        ${sudo_cmd} sed -i 's/allowed_media_dirs = \/media\/$USER, \/run\/media\/$USER/allowed_media_dirs = \/DATA, \/DATA\/$USER/g' $PREFIX${UDEVIL_CONF_PATH}

        # GreyStart
        # Add a devmon user
        USERNAME=devmon
        id ${USERNAME} &>/dev/null || {
            ${sudo_cmd} useradd -M -u 300 ${USERNAME}
            ${sudo_cmd} usermod -L ${USERNAME}
        }

        # Add and start Devmon service
        GreyStart
        ${sudo_cmd} systemctl enable devmon@devmon
        ${sudo_cmd} systemctl start devmon@devmon
        ColorReset
        # ColorReset
    fi
}

# Download And Install CasaOS
DownloadAndInstallCasaOS() {
    # Get the latest version of CasaOS
    if [[ ! -n "$version" ]]; then
        CASA_TAG="v$(${NET_GETTER} ${CASA_VERSION_URL})"
    elif [[ $version == "pre" ]]; then
        CASA_TAG="$(${NET_GETTER} ${CASA_RELEASE_API} | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g' | sed -n '1p')"
    else
        CASA_TAG="$version"
    fi

    if [ -z "${BUILD_DIR}" ]; then

        ${sudo_cmd} mkdir -p ${TMP_ROOT} || Show 1 "Failed to create temporary directory"
        TMP_DIR=$(mktemp -d -p ${TMP_ROOT} || Show 1 "Failed to create temporary directory")

        pushd "${TMP_DIR}"

        for PACKAGE in "${CASA_PACKAGES[@]}"; do
            Show 2 "Downloading ${PACKAGE}..."
          
            ${sudo_cmd} curl -sLO "${PACKAGE}" || Show 1 "Failed to download package"
            
        done

        for PACKAGE_FILE in linux-*-casaos-*.tar.gz; do
            Show 2 "Extracting ${PACKAGE_FILE}..."
            ${sudo_cmd} tar zxf "${PACKAGE_FILE}" || Show 1 "Failed to extract package"
        done

        BUILD_DIR=$(realpath -e "${TMP_DIR}"/build || Show 1 "Failed to find build directory")

        popd
    fi

    # for SERVICE in "${CASA_SERVICES[@]}"; do
    #     Show 2 "Stopping ${SERVICE}..."

    #   systemctl stop "${SERVICE}" || Show 3 "Service ${SERVICE} does not exist."

    # done

    MIGRATION_SCRIPT_DIR=$(realpath -e "${BUILD_DIR}"/scripts/migration/script.d || Show 1 "Failed to find migration script directory")

    for MIGRATION_SCRIPT in "${MIGRATION_SCRIPT_DIR}"/*.sh; do
        Show 2 "Running ${MIGRATION_SCRIPT}..."

        ${sudo_cmd} bash "${MIGRATION_SCRIPT}" || Show 1 "Failed to run migration script"

    done

    Show 2 "Installing CasaOS..."
    SYSROOT_DIR=$(realpath -e "${BUILD_DIR}"/sysroot || Show 1 "Failed to find sysroot directory")

    # Generate manifest for uninstallation
    MANIFEST_FILE=${BUILD_DIR}/sysroot/var/lib/casaos/manifest
    ${sudo_cmd} touch "${MANIFEST_FILE}" || Show 1 "Failed to create manifest file"

    
    find "${SYSROOT_DIR}" -type f | ${sudo_cmd} cut -c ${#SYSROOT_DIR}- | ${sudo_cmd} cut -c 2- | ${sudo_cmd} tee "${MANIFEST_FILE}" || Show 1 "Failed to create manifest file"

    ${sudo_cmd} cp -rf "${SYSROOT_DIR}"/* / >> /dev/null || Show 1 "Failed to install CasaOS"

    SETUP_SCRIPT_DIR=$(realpath -e "${BUILD_DIR}"/scripts/setup/script.d || Show 1 "Failed to find setup script directory")

    for SETUP_SCRIPT in "${SETUP_SCRIPT_DIR}"/*.sh; do
        Show 2 "Running ${SETUP_SCRIPT}..."
        ${sudo_cmd} bash "${SETUP_SCRIPT}" || Show 1 "Failed to run setup script"
    done
    
    #Download Uninstall Script
    if [[ -f $PREFIX/tmp/casaos-uninstall ]]; then
        ${sudo_cmd} rm -rf $PREFIX/tmp/casaos-uninstall
    fi
    ${sudo_cmd} curl -fsSLk "$CASA_UNINSTALL_URL" >"$PREFIX/tmp/casaos-uninstall"
    ${sudo_cmd} cp -rvf "$PREFIX/tmp/casaos-uninstall" $CASA_UNINSTALL_PATH
    if [[ $? -ne 0 ]]; then
        Show 1 "Download uninstall script failed, Please check if your internet connection is working and retry."
        exit 1
    fi
    ${sudo_cmd} chmod +x $CASA_UNINSTALL_PATH
    
    ## Special markings

    Show 0 "CasaOS upgrade successfully"
   for SERVICE in "${CASA_SERVICES[@]}"; do
        Show 2 "restart ${SERVICE}..."

        ${sudo_cmd} systemctl restart "${SERVICE}" || Show 3 "Service ${SERVICE} does not exist."

    done

    
}

###############################################################################
# Main                                                                        #
###############################################################################

#Usage
usage() {
    cat <<-EOF
		Usage: get.sh [options]
		Valid options are:
		    -v <version>            Specify version to install For example: get.sh -v v0.2.3 | get.sh -v pre | get.sh
		    -p <builddir>           Specify build directory
		    -h                      Show this help message and exit
	EOF
    exit $1
}

while getopts ":v:p:h" arg; do
    case "$arg" in
    v)
        version=$OPTARG
        ;;
    p)
        BUILD_DIR=$OPTARG
        ;;
    h)
        usage 0
        ;;
    esac
done

# Step 1：Check ARCH
Check_Arch

# Step 2: Check OS
Check_OS

# Step 3: Check Distribution
Check_Distribution

# Step 4: Check System 
Check_Memory

# Step 5: Install Depends
# Update_Package_Resource
Install_Depends
Check_Dependency_Installation

# Step 7: Configuration Addon
Configuration_Addons

# Step 8: Download And Install CasaOS
DownloadAndInstallCasaOS
