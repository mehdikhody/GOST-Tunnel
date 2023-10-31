#!/bin/bash

if [ $(basename $(pwd)) == "GOST-Tunnel" ]; then
    ENV_MODE="development"
else
    ENV_MODE="production"
fi

GOST_LOCATION="/usr/local/bin/gost"
GOST_SERVICE="/etc/systemd/system/gost.service"
GTCTL_LOCATION="/usr/local/bin/gtctl"
INSTALLER="https://raw.githubusercontent.com/mehdikhody/GOST-Tunnel/master/install.sh"

Plain='\033[0m'
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'

BBlack='\033[1;30m'
BRed='\033[1;31m'
BGreen='\033[1;32m'
BYellow='\033[1;33m'
BBlue='\033[1;34m'
BPurple='\033[1;35m'
BCyan='\033[1;36m'
BWhite='\033[1;37m'

UBlack='\033[4;30m'
URed='\033[4;31m'
UGreen='\033[4;32m'
UYellow='\033[4;33m'
UBlue='\033[4;34m'
UPurple='\033[4;35m'
UCyan='\033[4;36m'
UWhite='\033[4;37m'

On_Black='\033[40m'
On_Red='\033[41m'
On_Green='\033[42m'
On_Yellow='\033[43m'
On_Blue='\033[44m'
On_Purple='\033[45m'
On_Cyan='\033[46m'
On_White='\033[47m'

IBlack='\033[0;90m'
IRed='\033[0;91m'
IGreen='\033[0;92m'
IYellow='\033[0;93m'
IBlue='\033[0;94m'
IPurple='\033[0;95m'
ICyan='\033[0;96m'
IWhite='\033[0;97m'

BIBlack='\033[1;90m'
BIRed='\033[1;91m'
BIGreen='\033[1;92m'
BIYellow='\033[1;93m'
BIBlue='\033[1;94m'
BIPurple='\033[1;95m'
BICyan='\033[1;96m'
BIWhite='\033[1;97m'

On_IBlack='\033[0;100m'
On_IRed='\033[0;101m'
On_IGreen='\033[0;102m'
On_IYellow='\033[0;103m'
On_IBlue='\033[0;104m'
On_IPurple='\033[0;105m'
On_ICyan='\033[0;106m'
On_IWhite='\033[0;107m'

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

if [ $ENV_MODE == "development" ]; then
    warning "Running in development mode"
    log
fi

if [ ! -f /etc/os-release ]; then
    panic "This script must be run on a supported OS"
fi

if [ "$EUID" -ne 0 ]; then
    panic "This script must be run as root"
fi

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
    os_release="arch"
    ;;
*)
    panic "This script must be run on a supported OS"
    ;;
esac

if [ ! -f $GOST_LOCATION ]; then
    warning "Gost is not installed"
fi

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

if [ "$1" == "info" ]; then
    if [ ! -f $GOST_SERVICE ]; then
        panic "gost service file not found"
    fi

    info "Current config info:"
    service=$(cat $GOST_SERVICE)
    Hostname=$(echo $service | cut -d ':' -f 3 | cut -d '/' -f 2)
    Ports=$(echo $service | grep -Eo ':[0-9\.]+' | awk '!seen[$0]++' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\:]*//g')

    # remove port 2222 from ports
    Ports=$(echo $Ports | sed 's/2222//g')

    pair "Hostname" "$Hostname"
    pair "Ports" "$Ports"

    log
    exit 0
fi

if [ "$1" == "start" ]; then
    if [ -f $GOST_SERVICE ]; then
        systemctl start gost.service
        systemctl daemon-reload
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
        systemctl daemon-reload
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
        systemctl daemon-reload
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
        systemctl daemon-reload
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

    # remove port 2222 from ports
    Ports=$(echo $Ports | sed 's/2222//g')

    if [ -f $GOST_SERVICE ]; then
        systemctl stop gost.service
        systemctl daemon-reload
    fi

    if [ -f $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
    fi

    if [ $ENV_MODE == "production" ]; then
        bash <(curl -Ls $INSTALLER) $Hostname $Ports
    else
        bash install.sh $Hostname $Ports
    fi

    log
    exit 0
fi
