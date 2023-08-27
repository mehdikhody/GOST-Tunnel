#!/bin/bash

# Variables
ENV_MODE="development" # development or production

GOST_VERSION="2.11.5"
GOST_GITHUB="https://github.com/ginuerzh/gost/releases/download"
GOST_LOCATION="/usr/local/bin/gost"
GOST_SERVICE="/etc/systemd/system/gost.service"

GTCTL_GITHUB="https://raw.githubusercontent.com/mehdikhody/GOST-Tunnel/master/gtctl.sh"
GTCTL_LOCATION="/usr/local/bin/gtctl"

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

    if [ $ENV_MODE == "production" ]; then
        rm -f $0
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

# System info
log
pair "OS" "$os_release $os_version"
pair "CPU Arch" $arhc
log

# Install dependencies
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

# Install gost
# Check for existing gost installation
if [ -f $GOST_LOCATION ]; then
    warning "gost is already installed"

    # Check gost binary
    if [ ! -x $GOST_LOCATION ]; then
        rm -f $GOST_LOCATION
        panic "gost binary is not executable"
    fi

    # Check gost version
    curr_version=$(gost -V | awk '{print $2}')
    if [ $curr_version != $GOST_VERSION ]; then
        panic "gost version mismatch. [Expected: $GOST_VERSION, Found: $curr_version]]"
    fi

    log
else
    # Download gost
    log "Downloading gost ..."
    package_name="gost-linux-$arhc-$GOST_VERSION.gz"
    package_url="$GOST_GITHUB/v$GOST_VERSION/$package_name"

    wget -qO- $package_name $package_url | gzip -d >$GOST_LOCATION
    chmod +x $GOST_LOCATION
    rm -f $package_name

    # Check if gost is installed
    if [ ! -f $GOST_LOCATION ]; then
        panic "gost installation failed"
    fi

    success "gost installed successfully"
    log
fi

# Ask for Hostname
while true; do
    input "Etern your targeted Hostname: " hostname

    if [ -z $hostname ]; then
        error "Hostname cannot be empty"
        log
        continue
    fi

    # check if host is within our reach
    if ! ping -c 1 $hostname &>/dev/null; then
        panic "Host is unreachable"
    fi

    # get hostname ping in ms
    ping_ms=$(ping -c 1 $hostname | awk -F '/' 'END {print $5}')

    pair "Hostname" $hostname
    pair "Ping" "$ping_ms ms"
    log

    break
done

# Ask for Ports to forward
while true; do
    input "Enter the ports to forward (space separated): " ports

    if [ -z "$ports" ]; then
        error "Ports cannot be empty"
        log
        continue
    fi

    break
done

# Create a systemd service
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

# Enable and start gost service
log "Enabling and starting gost service ..."
systemctl daemon-reload
systemctl enable gost.service
systemctl start gost.service

success "gost service started successfully"
log

# Install gtctl
log "Installing Gost Tunnel Control (gtctl) ..."

# Download gtctl
log "Downloading gtctl ..."

if [ $ENV_MODE == "production" ]; then
    wget -qO $GTCTL_LOCATION $GTCTL_GITHUB
    chmod +x $GTCTL_LOCATION
else
    cp gtctl.sh $GTCTL_LOCATION
    chmod +x $GTCTL_LOCATION
fi

# Check if gtctl is installed
if [ ! -f $GTCTL_LOCATION ]; then
    panic "gtctl installation failed"
fi

success "gtctl installed successfully"

# Show gtctl help
log
$GTCTL_LOCATION help
log

# Remove the script
if [ $ENV_MODE == "production" ]; then
    rm -f $0
fi
