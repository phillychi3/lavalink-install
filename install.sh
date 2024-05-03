#/bin/bash

print_system() {
    echo -e "
    ------------------------------
    OS: $OSNAME
    Version: $VER
    ------------------------------
    "
}

install_package() {
    # $1: package name for debian/ubuntu
    # $2: package name for centos/fedora
    # $3: package name for arch
    case $OSID in
        *debian*|*ubuntu*)
            echo "Installing $1"
            sudo apt-get install $1 -y
            ;;
        *centos*|*fedora*)
            echo "Installing $2"
            sudo yum install $2 -y
            ;;
        *arch*)
            echo "Installing $3"
            sudo pacman -S $3 --noconfirm
            ;;
        *)
            echo "OS not supported"
            exit 1
            ;;
    esac
}

if [ "$1" == "-u" ]; then
    echo "Checking Update"
    url = "https://api.github.com/repos/lavalink-devs/Lavalink/releases"
    latest = $(curl -s $url | jq -r '.[0].tag_name')
    current = $(java -jar Lavalink.jar --version | grep "Version" | awk '{print $2}')

    if [ latest == "$current" ]; then
        echo "Lavalink is up to date"
    else
        echo "Lavalink has a new version"
        echo "Downloading..."
        wget -O Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/$latest/Lavalink.jar"
    exit 0
fi

if [ `id -u` -ne 0 ]
    then echo "Please run as root"
    exit
fi

echo "LavaLink install Script"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OSID=$ID
    OSNAME=$PRETTY_NAME
    VER=$VERSION_ID
else
    echo "OS not supported"
    exit 1
fi
print_system

echo "check java..."
if ! [ -x "$(command -v java)" ]; then
    echo "java is not installed"
    echo "installing java..."
    echo "not Finish install java countinue"
fi

echo "check curl..."
if ! [ -x "$(command -v curl)" ]; then
    echo "curl is not installed"
    echo "installing curl..."
    install_package curl curl curl
fi

echo "check jq..."
if ! [ -x "$(command -v jq)" ]; then
    echo "jq is not installed"
    echo "installing jq..."
    install_package jq jq jq
fi

echo "Downloading Lavalink..."
url = "https://api.github.com/repos/lavalink-devs/Lavalink/releases"
latest = $(curl -s $url | jq -r '.[0].tag_name')
wget -O Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/$latest/Lavalink.jar"
mkdir -P Plugins

lavasrcver = $(curl -s https://raw.githubusercontent.com/topi314/LavaSrc/releases | jq -r '.[0].tag_name')
wget -O Plugins/lavasrc-$lavasrcver.jar "https://github.com/topi314/LavaSrc/releases/download/$lavasrcver/lavasrc-$lavasrcver.jar"

echo "Downloading Lavalink config..."
lavaapp = $(curl -s https://raw.githubusercontent.com/phillychi3/lavalink-install/main/application.yml)
sed -i "s|- dependency: com.github.topi314.lavasrc:lavasrc-plugin:*|- dependency: com.github.topi314.lavasrc:lavasrc-plugin:$lavasrcver|" $lavaapp

echo "Please Enter you want use port"
read port
sed -i "s|port:.*|port: $port|" $lavaapp

echo "Please Enter you want use password"
read paassword
sed -i "s|password:.*|password: $password|" $lavaapp
cat "$lavaapp" > application.yml


echo "Register Lavalink as a service..."
lavaservice = $(curl -s https://raw.githubusercontent.com/phillychi3/lavalink-install/main/lavalink.service)

sed -i "s|ExecStart=.*|ExecStart=java -jar $PWD/Lavalink.jar|" $lavaservice
cat "$lavaservice" > /etc/systemd/system/lavalink.service

systemctl daemon-reload
systemctl enable lavalink
systemctl start lavalink

echo "Lavalink is now running"
echo "Please Edit your application.yml for more configuration"