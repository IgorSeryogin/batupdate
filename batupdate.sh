#!/bin/sh -e
##################################################################################
# B.A.T.M.A.N. Advanced Automated Installaion and Update Script. GOSH, 2016
# v2016012303
##################################################################################

WORK_DIR="/tmp/batman-build"
SCRIPT_DIR="ftp://gosh.pp.ua/batman-adv/scripts"
INTERNET_CONNECTED="n"
READY_TO_BUILD="n"
ACTUAL_VERSION="NA"
BATCTL_VERSION="NA"
ALFRED_VERSION="NA"
FORCE_VERSION="NA"
BATMAN_ADV_VERSION="NA"
DISPATCHER_VERSION="NA"
PWD=`pwd`
CPU_THREADS=`cat /proc/cpuinfo | grep processor | wc -l`
BATMAN_ADV_OPTIONS="CONFIG_BATMAN_ADV_NC=y"
ALFRED_OPTIONS="CONFIG_ALFRED_GPSD=n"

EchoGreen () {
    echo "\033[32m$1\033[0m"
}

EchoRed () {
    echo "\033[31m$1\033[0m"
}

CheckBuild () {
    local PKG=`dpkg --get-selections | grep build-essential | grep install`
    if [ -n    "$PKG" ]; then
        READY_TO_BUILD="y"
    else
        READY_TO_BUILD="n"
    fi
}

CheckInternet () {
    local CHECK_IP="8.8.8.8"
    ping -c 1 -w 1 $CHECK_IP > /dev/null
    if [ "$?" != "0" ]; then
        INTERNET_CONNECTED="n"
    else
        INTERNET_CONNECTED="y"
    fi
}

CheckActualVersion () {
    if [ "$FORCE_VERSION" = "NA" ]; then
        if [ "$INTERNET_CONNECTED" = "y" ]; then
            ACTUAL_VERSION=`wget -qO - http://downloads.open-mesh.org/batman/releases/ | grep batman-adv | cut -d"\"" -f 6 | cut -d"/" -f1 | cut -d"-" -f 3 | sort | tail -1`
            local VALIDATION=`echo "$ACTUAL_VERSION" | grep -E "^[0-9]{4}\.[0-9]{1,2}$"`
            if [ -z "$VALIDATION" ]; then
                ACTUAL_VERSION="ERROR"
            fi
        else
            ACTUAL_VERSION="NA"
        fi
    else
        ACTUAL_VERSION=$FORCE_VERSION
    fi
}

CheckBatctlVersion () {
    BATCTL_VERSION=`batctl -v | cut -d" " -f 2`
    local VALIDATION=`echo "$BATCTL_VERSION" | grep -E "^[0-9]{4}\.[0-9]"`
    if [ -z "$VALIDATION" ]; then
        BATCTL_VERSION="NA"
    fi
}

CheckBatmanAdvVersion () {
    BATMAN_ADV_VERSION=`modinfo batman-adv | grep ^version | cut -d" " -f9`
    local VALIDATION=`echo "$BATMAN_ADV_VERSION" | grep -E "^[0-9]{4}\.[0-9]$"`
    if [ -z "$VALIDATION" ]; then
        BATMAN_ADV_VERSION="NA"
    fi
}

CheckAlfredVersion () {
    ALFRED_VERSION=`alfred -v | head -n 1 | cut -d" " -f 2`
    local VALIDATION=`echo "$ALFRED_VERSION" | grep -E "^[0-9]{4}\.[0-9]$"`
    if [ -z "$VALIDATION" ]; then
        ALFRED_VERSION="NA"
    fi
}

CheckDispatcherVersion () {
    local DISPATCHER=/etc/NetworkManager/dispatcher.d/02batman-adv
    if [ -e "$DISPATCHER" ]; then
        DISPATCHER_VERSION=`cat $DISPATCHER | grep -E "^# v[0-9]+\.[0-9]+\.[0-9]+$" | cut -d"v" -f2`
        if [ -z "$DISPATCHER_VERSION" ]; then
            DISPATCHER_VERSION="ERROR";
        fi
    else
        DISPATCHER_VERSION="NA"
    fi 
}

Check () {
    CheckBuild
    CheckInternet
    CheckActualVersion
    CheckBatctlVersion
    CheckBatmanAdvVersion
    CheckAlfredVersion
    CheckDispatcherVersion
}

PrintStat () {
    echo "===================================="
    if [ "$INTERNET_CONNECTED" = "y" ]; then
        EchoGreen "Internet Ready!"
    else
        EchoRed "Internet Not Ready!"
    fi
    if [ "$READY_TO_BUILD" = "y" ]; then
        EchoGreen "Build Ready!"
    else
        EchoRed "Build Not Ready!"
    fi
    if [ "$ACTUAL_VERSION" != "NA" ] && [ "$ACTUAL_VERSION" != "ERROR" ]; then
        EchoGreen "Actual Version: $ACTUAL_VERSION"
    else
        EchoRed "Actual Version: $ACTUAL_VERSION"
    fi
    if [ "$BATCTL_VERSION" = "NA" ] || ( [ "$ACTUAL_VERSION" != "NA" ] && [ "$ACTUAL_VERSION" != "ERROR" ] && [ "$ACTUAL_VERSION" != "$BATCTL_VERSION" ] ); then
        EchoRed "Batctl Version: $BATCTL_VERSION"
    else
        EchoGreen "Batctl Version: $BATCTL_VERSION"
    fi
    if [ "$BATMAN_ADV_VERSION" = "NA" ] || ( [ "$ACTUAL_VERSION" != "NA" ] && [ "$ACTUAL_VERSION" != "ERROR" ] && [ "$ACTUAL_VERSION" != "$BATMAN_ADV_VERSION" ] ); then
        EchoRed "Batman-adv Version: $BATMAN_ADV_VERSION"
    else
        EchoGreen "Batman-adv Version: $BATMAN_ADV_VERSION"
    fi
    if [ "$ALFRED_VERSION" = "NA" ] || ( [ "$ACTUAL_VERSION" != "NA" ] && [ "$ACTUAL_VERSION" != "ERROR" ] && [ "$ACTUAL_VERSION" != "$ALFRED_VERSION" ] ); then
        EchoRed "Alfred Version: $ALFRED_VERSION"
    else
        EchoGreen "Alfred Version: $ALFRED_VERSION"
    fi
    echo "===================================="
    if [ "$DISPATCHER_VERSION" != "NA" ] && [ "$DISPATCHER_VERSION" != "ERROR" ]; then
        EchoGreen "Dispatcher Version: $DISPATCHER_VERSION"
    else
        EchoRed "Dispatcher Version: $DISPATCHER_VERSION"
    fi
    echo "===================================="   
}

Init () {
    sudo mkdir $WORK_DIR;
}

Done () {
    sudo rm -rf $WORK_DIR;
}

InstallBatctl () {
    local BATCTL_URL=http://downloads.open-mesh.org/batman/releases/batman-adv-$ACTUAL_VERSION/batctl-$ACTUAL_VERSION.tar.gz;
    if [ "$BATCTL_VERSION" = "$ACTUAL_VERSION" ]; 
        then
            EchoGreen "Batctl OK!";
        else
            EchoRed "Batctl updating...";
            Done;
            Init;
            sudo wget -qO $WORK_DIR/batctl.tar.gz $BATCTL_URL;
            cd $WORK_DIR;
            sudo tar -xf batctl.tar.gz;
            cd $WORK_DIR/batctl-$ACTUAL_VERSION;
            sudo make -j $CPU_THREADS;
            sudo make install;
            cd $PWD;
            Done;
    fi
}

InstallBatmanAdv () {
    BATMAN_ADV_URL=http://downloads.open-mesh.org/batman/releases/batman-adv-$ACTUAL_VERSION/batman-adv-$ACTUAL_VERSION.tar.gz
    if [ "$BATMAN_ADV_VERSION" = "$ACTUAL_VERSION" ]; then
        EchoGreen "Batman-adv OK!"
    else
        EchoRed "Batman-adv updating..."
        Done
        Init
        sudo wget -qO $WORK_DIR/batman-adv.tar.gz $BATMAN_ADV_URL
        cd $WORK_DIR
        sudo tar -xf batman-adv.tar.gz
        cd $WORK_DIR/batman-adv-$ACTUAL_VERSION
        sudo make -j $CPU_THREADS $BATMAN_ADV_OPTIONS
        sudo make $BATMAN_ADV_OPTIONS install
        sudo rmmod batman-adv
        sudo modprobe batman-adv
        cd $PWD
        Done
    fi
    local MOD=`cat /etc/modules | grep batman-adv`
    if [ -z "$MOD" ]; then
        EchoRed "Setting up kernel module autoload..."
        echo "echo "batman-adv" >> /etc/modules" | sudo sh
    else
        EchoGreen "Kernel module autoload OK!"
    fi
}

InstallAlfred () {
    ALFRED_URL=http://downloads.open-mesh.org/batman/releases/batman-adv-$ACTUAL_VERSION/alfred-$ACTUAL_VERSION.tar.gz
    if [ "$ALFRED_VERSION" = "$ACTUAL_VERSION" ]; then
        EchoGreen "Alfred OK!"
    else
        EchoRed "Alfred updating..."
        Done
        Init
        sudo wget -qO $WORK_DIR/alfred.tar.gz $ALFRED_URL
        cd $WORK_DIR
        sudo tar -xf alfred.tar.gz
        cd $WORK_DIR/alfred-$ACTUAL_VERSION
        sudo make -j $CPU_THREADS $ALFRED_OPTIONS
        sudo make $ALFRED_OPTIONS install
        cd $PWD
        Done
    fi
}

InstallLogo () {
    if [ -e /etc/mesh/batlogo_black.svg ]; then
        EchoGreen "Logo OK!"
    else
        EchoRed "Logo installing..."
        sudo mkdir -p /etc/mes
        sudo wget -qO /etc/mesh/batlogo_black.svg $SCRIPT_DIR/batlogo_black.svg
    fi
}

InstallNetworkManagerDispatcher () {
    if [ -e /etc/NetworkManager/dispatcher.d/02batman-adv ]; then
            EchoGreen "NetworkManager dispatcher script OK!"
    else
        EchoRed "Installing NetworkManager dispatcher script..."
        sudo wget -qO /etc/NetworkManager/dispatcher.d/02batman-adv $SCRIPT_DIR/02batman-adv
        sudo chmod 755 /etc/NetworkManager/dispatcher.d/02batman-adv
    fi
}

PatchNetworkManagerConf () {
    local NM="/etc/NetworkManager/NetworkManager.conf"
    local DNS=`cat "$NM" | grep dns | grep "#"`
    if [ -z "$DNS" ]; then
        EchoRed "Patching NetworkManager.conf..."
        Done
        sudo wget -qO $WORK/patch $SCRIPT_DIR/NetworkManager.patch
        sudo patch -s "$NM" $WORK/patch
        Done
    else
        EchoGreen "NetworkManger.conf OK!"
    fi
}

InstallConnection () {
    if [ -e "/etc/NetworkManager/system-connections/open-mesh.org" ]; then
        EchoGreen "Connection configuration OK!"
    else
        EchoRed "Connection installing..."
        sudo wget -qO "/etc/NetworkManager/system-connections/open-mesh.org" $SCRIPT_DIR/open-mesh.org
        sudo chmod 600 /etc/NetworkManager/system-connections/open-mesh.org
        sudo /etc/init.d/network-manager restart
    fi
}

InstallAuto () {
    InstallBatmanAdv
    InstallBatctl
    InstallAlfred
    InstallNetworkManager
    InstallLogo
    InstallConnection
}

InstallNetworkManager () {
    InstallNetworkManagerDispatcher
    PatchNetworkManagerConf
}

Usage () {
    echo "Usage: batupdate.sh [module]"
    echo "module: auto"
    echo "        server"
    echo "        check"
    echo "        nm"
    echo "        ctl"
    echo "        mod"
    echo "        alfred"
    echo "        logo"
    echo "        conn"
}

Check
PrintStat

if [ "$#" -ne "1" ]; then
    if [ "$#" -ne "0" ]; then
        Usage;
    else
        InstallAuto;
    fi;
else
    case "$1" in
        "auto")
            InstallAuto && exit 0
            ;;
        "server")
            echo "server" && exit 0
            ;;
        "check")
            echo "check" && exit 0
            ;;
        "conn")
            InstallConnection && exit 0
            ;;
        "nm")
            InstallNetworkManager && exit 0
            ;;
        "mod")
            InstallBatmanAdv && exit 0
            ;;
        "ctl")
            InstallBatctl && exit 0
            ;;
        "alfred")
            InstallAlfred && exit 0
            ;;
        "logo")
            InstallLogo && exit 0
            ;;
        "test")
            exit 0
            ;;
    esac
        Usage && exit 0
fi