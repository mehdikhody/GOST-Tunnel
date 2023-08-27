#!/bin/bash

# Variables
ENV_MODE="production" # development or production

GOST_LOCATION="/usr/local/bin/gost"
GOST_SERVICE="/etc/systemd/system/gost.service"
GTCTL_LOCATION="/usr/local/bin/gtctl"
INSTALLER="https://raw.githubusercontent.com/mehdikhody/GOST-Tunnel/master/install.sh"

# Colors
Plain='\033[0m'     # Text Reset
Black='\033[0;30m'  # Black
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m'   # Blue
Purple='\033[0;35m' # Purple
Cyan='\033[0;36m'   # Cyan
White='\033[0;37m'  # White

# Bold
BBlack='\033[1;30m'  # Black
BRed='\033[1;31m'    # Red
BGreen='\033[1;32m'  # Green
BYellow='\033[1;33m' # Yellow
BBlue='\033[1;34m'   # Blue
BPurple='\033[1;35m' # Purple
BCyan='\033[1;36m'   # Cyan
BWhite='\033[1;37m'  # White

# Underline
UBlack='\033[4;30m'  # Black
URed='\033[4;31m'    # Red
UGreen='\033[4;32m'  # Green
UYellow='\033[4;33m' # Yellow
UBlue='\033[4;34m'   # Blue
UPurple='\033[4;35m' # Purple
UCyan='\033[4;36m'   # Cyan
UWhite='\033[4;37m'  # White

# Background
On_Black='\033[40m'  # Black
On_Red='\033[41m'    # Red
On_Green='\033[42m'  # Green
On_Yellow='\033[43m' # Yellow
On_Blue='\033[44m'   # Blue
On_Purple='\033[45m' # Purple
On_Cyan='\033[46m'   # Cyan
On_White='\033[47m'  # White

# High Intensity
IBlack='\033[0;90m'  # Black
IRed='\033[0;91m'    # Red
IGreen='\033[0;92m'  # Green
IYellow='\033[0;93m' # Yellow
IBlue='\033[0;94m'   # Blue
IPurple='\033[0;95m' # Purple
ICyan='\033[0;96m'   # Cyan
IWhite='\033[0;97m'  # White

# Bold High Intensity
BIBlack='\033[1;90m'  # Black
BIRed='\033[1;91m'    # Red
BIGreen='\033[1;92m'  # Green
BIYellow='\033[1;93m' # Yellow
BIBlue='\033[1;94m'   # Blue
BIPurple='\033[1;95m' # Purple
BICyan='\033[1;96m'   # Cyan
BIWhite='\033[1;97m'  # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'  # Black
On_IRed='\033[0;101m'    # Red
On_IGreen='\033[0;102m'  # Green
On_IYellow='\033[0;103m' # Yellow
On_IBlue='\033[0;104m'   # Blue
On_IPurple='\033[0;105m' # Purple
On_ICyan='\033[0;106m'   # Cyan
On_IWhite='\033[0;107m'  # White

# Helper functions

panic() {
    echo -e "${BIRed}Panic: $1${Plain}"
    exit 1
}

error() {
    echo -e "${BIRed}$1${Plain}"
}

warning() {
    echo -e "${BIYellow}$1${Plain}"
}

log() {
    echo -e "${IWhite}$1${Plain}"
}

info() {
    echo -e "${BIBlue}$1${Plain}"
}

success() {
    echo -e "${BIGreen}$1${Plain}"
}

pair() {
    echo -e "${BIBlue}$1: ${IWhite}$2${Plain}"
}

input() {
    echo -e -n "${BIWhite}$1${Plain}"
    read $2
}

# Check if the script is running on a supported OS
if [ ! -f /etc/os-release ]; then
    panic "This script must be run on a supported OS"
fi

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    panic "This script must be run as root"
fi

# Check if the script is running on a supported CPU architecture
case $(uname -m) in
x86_64 | x64 | amd64)
    arhc="amd64"
    ;;
armv8 | arm64 | aarch64)
    arhc="armv8"
    ;;
*)
    panic "This script must be run on a supported CPU architecture"
    ;;
esac

# Check if the script is running on a supported OS
os_release=""

if [ -f /etc/os-release ]; then
    source /etc/os-release
    os_release=$ID
elif [ -f /usr/lib/os-release ]; then
    source /usr/lib/os-release
    os_release=$ID
else
    panic "This script must be run on a supported OS"
fi

# Check if the script is running on a supported OS version
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

case $os_release in
ubuntu)
    if [ $os_version -lt 20 ]; then
        panic "This script must be run on a Ubuntu 20.04 or higher"
    fi
    ;;
centos)
    if [ $os_version -lt 8 ]; then
        panic "This script must be run on a CentOS 8 or higher"
    fi
    ;;
fedora)
    if [ $os_version -lt 36 ]; then
        panic "This script must be run on a Fedora 36 or higher"
    fi
    ;;
debian)
    if [ $os_version -lt 10 ]; then
        panic "This script must be run on a Debian 10 or higher"
    fi
    ;;
arch)
    # Do nothing
    os_release="arch"
    ;;
*)
    panic "This script must be run on a supported OS"
    ;;
esac

if [ ! -f $GOST_LOCATION ]; then
    warning "Gost is not installed"
fi

# Help command
# if $1 was help or no $1
if [ "$1" == "help" ] || [ -z "$1" ]; then
    pair "Usage" "gtctl [command]"
    info ""
    info "Commands:"
    info "  info        ${Plain}Show current config info"
    info "  start       ${Plain}Start gost"
    info "  stop        ${Plain}Stop gost"
    info "  restart     ${Plain}Restart gost"
    info "  status      ${Plain}Show gost status"
    info "  uninstall   ${Plain}Uninstall everything"
    info "  update      ${Plain}Update everything"
    info "  help        ${Plain}Show this help message"

    log
    exit 0
fi

# Info command
if [ "$1" == "info" ]; then
    if [ ! -f $GOST_SERVICE ]; then
        panic "gost service file not found"
    fi

    info "Current config info:"
    # get info out of gost.service file
    service=$(cat $GOST_SERVICE)
    Hostname=$(echo $service | cut -d ':' -f 3 | cut -d '/' -f 2)
    Ports=$(echo $service | grep -Eo ':[0-9\.]+' | awk '!seen[$0]++' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\:]*//g')

    pair "Hostname" "$Hostname"
    pair "Ports" "$Ports"

    log
    exit 0
fi

if [ "$1" == "start" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl start gost.service
        success "gost started successfully"
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "stop" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        success "gost stopped successfully"
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "restart" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl restart gost.service
        success "gost restarted successfully"
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "status" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl status gost.service
    else
        panic "gost service file not found"
    fi

    log
    exit 0
fi

if [ "$1" == "uninstall" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        systemctl disable gost.service
        rm -f $GOST_SERVICE
    fi

    if [ -f $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
    fi

    if [ -f $GTCTL_LOCATION ]; then
        rm -f $GTCTL_LOCATION
    fi

    success "uninstalled successfully"
    log
    exit 0
fi

if [ "$1" == "update" ]; then
    service=$(cat $GOST_SERVICE)
    Hostname=$(echo $service | cut -d ':' -f 3 | cut -d '/' -f 2)
    Ports=$(echo $service | grep -Eo ':[0-9\.]+' | awk '!seen[$0]++' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\:]*//g')

    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        systemctl disable gost.service
        rm -f $GOST_SERVICE
    fi

    if [ -f $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
    fi

    if [ -f $GTCTL_LOCATION ]; then
        rm -f $GTCTL_LOCATION
    fi

    if [ $ENV_MODE == "production" ]; then
        bash <(curl -Ls $INSTALLER) $Hostname $Ports
    else
        bash install.sh $Hostname $Ports
    fi

    log
    exit 0
fi
