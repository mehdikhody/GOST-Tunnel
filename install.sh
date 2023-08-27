#!/bin/bash

if [ $(basename $(pwd)) == "GOST-Tunnel" ]; then
    ENV_MODE="development"
else
    ENV_MODE="production"
fi

GOST_VERSION="2.11.5"
GOST_GITHUB="https://github.com/ginuerzh/gost/releases/download"
GOST_LOCATION="/usr/local/bin/gost"
GOST_SERVICE="/etc/systemd/system/gost.service"

GTCTL_GITHUB="https://raw.githubusercontent.com/mehdikhody/GOST-Tunnel/master/gtctl.sh"
GTCTL_LOCATION="/usr/local/bin/gtctl"
INSTALLER_FILE="install.sh"

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

    if [ $ENV_MODE == "production" ]; then
        if [ -f $INSTALLER_FILE ]; then
            rm -f $INSTALLER_FILE
        fi
    fi

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

log
pair "OS" "$os_release $os_version"
pair "CPU Arch" $arhc
log

log "Installing dependencies ..."

case $os_release in
centos | fedora)
    yum install -y -q wget curl gzip tar
    ;;
arch)
    pacman -S --noconfirm --needed wget curl gzip tar
    ;;
*)
    apt install -y -qq wget curl gzip tar
    ;;
esac

success "Dependencies installed successfully"
log

if [ -f $GOST_LOCATION ]; then
    warning "gost is already installed"

    if [ ! -x $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
        panic "gost binary is not executable"
    fi

    curr_version=$(gost -V | awk '{print $2}')
    if [ $curr_version != $GOST_VERSION ]; then
        panic "gost version mismatch. [Expected: $GOST_VERSION, Found: $curr_version]]"
    fi

    log
else

    log "Downloading gost ..."
    package_name="gost-linux-$arhc-$GOST_VERSION.gz"
    package_url="$GOST_GITHUB/v$GOST_VERSION/$package_name"

    wget -qO- $package_name $package_url | gzip -d >$GOST_LOCATION
    chmod +x $GOST_LOCATION
    rm -f $package_name

    if [ ! -f $GOST_LOCATION ]; then
        panic "gost installation failed"
    fi

    success "gost installed successfully"
    log
fi

log "Installing Gost Tunnel Control (gtctl) ..."

log "Downloading gtctl ..."

if [ $ENV_MODE == "production" ]; then
    wget -qO $GTCTL_LOCATION $GTCTL_GITHUB
    chmod +x $GTCTL_LOCATION
else
    cp gtctl.sh $GTCTL_LOCATION
    chmod +x $GTCTL_LOCATION
fi

if [ ! -f $GTCTL_LOCATION ]; then
    panic "gtctl installation failed"
fi

success "gtctl installed successfully"
log

while true; do

    if [ ! -z $1 ]; then
        hostname=$1
    else
        input "Etern your targeted Hostname: " hostname
    fi

    if [ -z $hostname ]; then
        error "Hostname cannot be empty"
        log

        if [ ! -z $1 ]; then
            exit 1
        fi

        continue
    fi

    if ! ping -c 1 $hostname &>/dev/null; then
        panic "Host is unreachable"
    fi

    ping_ms=$(ping -c 1 $hostname | awk -F '/' 'END {print $5}')

    pair "Hostname" $hostname
    pair "Ping" "$ping_ms ms"
    log

    break
done

while true; do

    if [ ! -z $2 ]; then
        ports=""
        for port in $@; do
            if ! [[ $port =~ ^[0-9]+$ ]]; then
                continue
            fi

            if [ ! -z "$ports" ]; then
                ports+=" "
            fi

            ports+="$port"
        done
    else
        input "Enter the ports to forward (space separated): " ports
    fi

    if [ -z "$ports" ]; then
        error "Ports cannot be empty"
        log

        if [ ! -z $2 ]; then
            exit 1
        fi

        continue
    fi

    if [ ! -z $2 ]; then
        pair "Ports" "$ports"
        log
    fi

    break
done

log "Creating systemd service ..."

gost_args=""
for port in $ports; do
    if [ ! -z "$gost_args" ]; then
        gost_args+=" "
    fi

    gost_args+="-L=tcp://:$port/$hostname:$port"
done

cat >$GOST_SERVICE <<EOF
[Unit]
Description=Gost Tunnel
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=$GOST_LOCATION $gost_args

[Install]
WantedBy=multi-user.target
EOF

log "Enabling and starting gost service ..."
systemctl daemon-reload
systemctl enable gost.service
systemctl start gost.service

success "gost service started successfully"
log

log
$GTCTL_LOCATION help
log

if [ $ENV_MODE == "production" ]; then
    if [ -f $INSTALLER_FILE ]; then
        rm -f $INSTALLER_FILE
    fi
fi
