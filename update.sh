#!/bin/bash
###
 # @Author:  LinkLeong link@icewhale.com
 # @Date: 2022-06-30 10:08:33
 # @LastEditors: a624669980@163.com a624669980@163.com
 # @LastEditTime: 2022-07-08 15:20:58
 # @FilePath: /get/updata.sh
 # @Description:
### 

((EUID)) && sudo_cmd="sudo"

# SYSTEM INFO
readonly UNAME_M="$(uname -m)"

# CasaOS PATHS
readonly CASA_REPO=LinkLeong/casaos-alpha
readonly CASA_UNZIP_TEMP_FOLDER=/tmp/casaos
readonly CASA_BIN=casaos
readonly CASA_BIN_PATH=/usr/bin/casaos
readonly CASA_CONF_PATH=/etc/casaos.conf
readonly CASA_SERVICE_PATH=/etc/systemd/system/casaos.service
readonly CASA_HELPER_PATH=/usr/share/casaos/shell/
readonly CASA_USER_CONF_PATH=/var/lib/casaos/conf/
readonly CASA_DB_PATH=/var/lib/casaos/db/
readonly CASA_TEMP_PATH=/var/lib/casaos/temp/
readonly CASA_LOGS_PATH=/var/log/casaos/
readonly CASA_PACKAGE_EXT=".tar.gz"
readonly CASA_RELEASE_API="https://api.github.com/repos/${CASA_REPO}/releases"
readonly CASA_OPENWRT_DOCS="https://github.com/IceWhaleTech/CasaOS-OpenWrt"
readonly CASA_UNINSTALL_URL="https://raw.githubusercontent.com/IceWhaleTech/get/main/casaos-uninstall"
readonly CASA_UNINSTALL_PATH=/usr/bin/casaos-uninstall
readonly CASA_DEPANDS_PACKAGE=('curl' 'smartmontools' 'parted' 'ntfs-3g' 'net-tools' 'whiptail' 'udevil' 'samba' 'cifs-utils')
readonly CASA_DEPANDS_COMMAND=('curl' 'smartctl' 'parted' 'ntfs-3g' 'netstat' 'whiptail' 'udevil' 'samba' 'mount.cifs')
# DEPANDS CONF PATH
readonly UDEVIL_CONF_PATH=/etc/udevil/udevil.conf

readonly COLOUR_RESET='\e[0m'


Target_Arch=""
Target_Distro="debian"
Target_OS="linux"
Casa_Tag=""


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
        echo "- OK $2" >> /var/log/casaos/upgrade.log
    # FAILED
    elif (($1 == 1)); then
        echo "- FAILED $2" >> /var/log/casaos/upgrade.log
    # INFO
    elif (($1 == 2)); then
        echo "- INFO $2" >> /var/log/casaos/upgrade.log
    # NOTICE
    elif (($1 == 3)); then
        echo "- NOTICE $2" >> /var/log/casaos/upgrade.log
    fi
}

# 1 Check Arch
Check_Arch() {
    case $UNAME_M in
    *aarch64*)
        Target_Arch="arm64"
        ;;
    *64*)
        Target_Arch="amd64"
        ;;
    *armv7*)
        Target_Arch="arm-7"
        ;;
    *)
        Show 1 "Aborted, unsupported or unknown architecture: $UNAME_M"
        exit 1
        ;;
    esac
    Show 0 "Your hardware architecture is : $UNAME_M"
}

# Install depends package
Install_Depends() {
    for ((i = 0; i < ${#CASA_DEPANDS_COMMAND[@]}; i++)); do
        cmd=${CASA_DEPANDS_COMMAND[i]}
        if [[ ! -x "$(command -v $cmd)" ]]; then
            packagesNeeded=${CASA_DEPANDS_PACKAGE[i]}
            Show 2 "Install the necessary dependencies: \e[33m$packagesNeeded \e[0m"
            echo -e "${aCOLOUR[2]}\c"
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
                Show 1 "Package manager not found. You must manually install: \e[33m$packagesNeeded \e[0m"
            fi
            echo -e "${COLOUR_RESET}\c"
        fi
    done
}

#Configuration Addons
Configuration_Addons() {
    Show 2 "Configuration CasaOS Addons"

    #Udevil
    if [[ -f $PREFIX${UDEVIL_CONF_PATH} ]]; then
        
        #Change udevil mount dir to /DATA
        ${sudo_cmd} sed -i 's/allowed_media_dirs = \/media\/$USER, \/run\/media\/$USER/allowed_media_dirs = \/DATA, \/DATA\/$USER/g' $PREFIX${UDEVIL_CONF_PATH}
        
        # Add a devmon user
        ${sudo_cmd} useradd -M -u 300 devmon
        ${sudo_cmd} usermod -L devmon

        # Add and start Devmon service
        ${sudo_cmd} systemctl enable devmon@devmon
        ${sudo_cmd} systemctl start devmon@devmon
    fi
}

#Download CasaOS Package
Download_CasaOS() {
    Show 2 "Downloading CasaOS for ${Target_OS}/${Target_Arch}..."
    Net_Getter="curl -fsSLk"
    Casa_Package="${Target_OS}-${Target_Arch}-casaos${CASA_PACKAGE_EXT}"
    if [[ ! -n "$version" ]]; then
        Casa_Tag="$(${Net_Getter} ${CASA_RELEASE_API}/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')"
    elif [[ $version == "pre" ]]; then
        Casa_Tag="$(${net_getter} ${CASA_RELEASE_API} | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g' | sed -n '1p')"
    else
        Casa_Tag="$version"
    fi
    Casa_Package_URL="https://github.com/${CASA_REPO}/releases/download/${Casa_Tag}/${Casa_Package}"
    echo
    # Remove Temp File
    ${sudo_cmd} rm -rf "$PREFIX/tmp/${Casa_Package}"
    # Download Package
    ${Net_Getter} "${Casa_Package_URL}" >"$PREFIX/tmp/${Casa_Package}"
    if [[ $? -ne 0 ]]; then
        Show 1 "Download failed, Please check if your internet connection is working and retry."
        exit 1
    else
        Show 0 "Download successful!"
    fi
    #Extract CasaOS Package
    Show 2 "Extracting..."
    case "${Casa_Package}" in
    *.zip) ${sudo_cmd} unzip -o "$PREFIX/tmp/${Casa_Package}" -d "$PREFIX/tmp/" ;;
    *.tar.gz) ${sudo_cmd} tar -xzf "$PREFIX/tmp/${Casa_Package}" -C "$PREFIX/tmp/" ;;
    esac
    #Setting Executable Permissions
    ${sudo_cmd} chmod +x "$PREFIX${CASA_UNZIP_TEMP_FOLDER}/${CASA_BIN}"

    #Download Uninstall Script

    ${sudo_cmd} ${Net_Getter} "$CASA_UNINSTALL_URL" >"$PREFIX/tmp/casaos-uninstall"
    ${sudo_cmd} cp -rf "$PREFIX/tmp/casaos-uninstall" $CASA_UNINSTALL_PATH
    if [[ $? -ne 0 ]]; then
        Show 1 "Download uninstall script failed, Please check if your internet connection is working and retry."
        exit 1
    fi
    ${sudo_cmd} chmod +x $CASA_UNINSTALL_PATH

}


#Clean Temp Files
Clean_Temp_Files() {
    Show 0 "Clean..."
    ${sudo_cmd} rm -rf "$PREFIX${CASA_UNZIP_TEMP_FOLDER}"
    sync
}

#Install CasaOS
Install_CasaOS() {
    Show 2 "Installing..."

    # Install Bin
    ${sudo_cmd} mv -f $PREFIX${CASA_UNZIP_TEMP_FOLDER}/${CASA_BIN} ${CASA_BIN_PATH}

    # Install Helper
    if [[ -d ${CASA_HELPER_PATH} ]]; then
        ${sudo_cmd} rm -rf ${CASA_HELPER_PATH}*
    fi
    ${sudo_cmd} cp -rf $PREFIX${CASA_UNZIP_TEMP_FOLDER}/shell/* ${CASA_HELPER_PATH}
    #Setting Executable Permissions
    ${sudo_cmd} chmod +x $PREFIX${CASA_HELPER_PATH}*

    # Install Conf
    if [[ ! -f ${CASA_CONF_PATH} ]]; then
        if [[ -f $PREFIX${CASA_UNZIP_TEMP_FOLDER}/conf/conf.ini.sample ]]; then
            ${sudo_cmd} mv -f $PREFIX${CASA_UNZIP_TEMP_FOLDER}/conf/conf.ini.sample ${CASA_CONF_PATH}
        else
            ${sudo_cmd} mv -f $PREFIX${CASA_UNZIP_TEMP_FOLDER}/conf/conf.conf.sample ${CASA_CONF_PATH}
        fi

    fi
    sync

    if [[ ! -x "$(command -v ${CASA_BIN})" ]]; then
        Show 1 "Installation failed, please try again."
        exit 1
    else
        Show 0 "CasaOS Successfully installed."
    fi
}

# Start CasaOS
Start_CasaOS() {
    
    Show 2 "Start CasaOS service."
    $sudo_cmd systemctl restart ${CASA_BIN}

    if [[ ! $(systemctl is-active ${CASA_BIN}) == "active" ]]; then
        Show 1 "Failed to start, please try again."
        exit 1
    else
        Show 0 "CasaOS upgrade successfully"
    fi
}

Check_Arch

Download_CasaOS

# Step 8: Install Addon
Install_Depends
# Step 8.1: Configuration Addon
Configuration_Addons
# Step 9: Install CasaOS
Install_CasaOS

Clean_Temp_Files

# Step 11: Start CasaOS
Start_CasaOS
