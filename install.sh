#!/bin/bash
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
    url="https://api.github.com/repos/lavalink-devs/Lavalink/releases"
    latest=$(curl -s $url | jq -r '.[0].tag_name')
    current=$(java -jar Lavalink.jar --version | grep "Version" | awk '{print $2}')

    if [ "$latest" == "$current" ]; then
        echo "Lavalink is up to date"
    else
        echo "Lavalink has a new version"
        echo "Downloading..."
        wget -O Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/$latest/Lavalink.jar"
    fi
    lavasrcver=$(curl -s https://api.github.com/repos/topi314/LavaSrc/releases | jq -r '.[0].tag_name')
    //lavasrc-4.2.0.jar
    current=$(ls Plugins | grep lavasrc | awk -F'-' '{print $3}' | awk -F'.' '{print $1"."$2"."$3}')
    if [ "$lavasrcver" != "$current" ]; then
        echo "Downloading Lavasrc..."
        wget -O Plugins/lavasrc-$lavasrcver.jar "https://github.com/topi314/LavaSrc/releases/download/$lavasrcver/lavasrc-$lavasrcver.jar"
        sed -i "s|- dependency: com.github.topi314.lavasrc:lavasrc-plugin:*|- dependency: com.github.topi314.lavasrc:lavasrc-plugin:$lavasrcver|" application.yml
    fi
    lavayoutube=$(curl -s https://api.github.com/repos/lavalink-devs/youtube-source/releases | jq -r '.[0].tag_name')
    current=$(ls Plugins | grep lavasrc | grep youtube | awk -F'-' '{print $3}' | awk -F'.' '{print $1"."$2"."$3}')
    if [ "$lavayoutube" != "$current" ]; then
        echo "Downloading Youtube-source..."
        wget -O Plugins/youtube-plugin-$lavayoutube.jar "https://github.com/lavalink-devs/youtube-source/releases/download/$lavayoutube/youtube-plugin-$lavayoutube.jar"
    sed -i "s|- dependency: "dev.lavalink.youtube:youtube-plugin:*|- dependency: "dev.lavalink.youtube:youtube-plugin:$lavayoutube|" application.yml
    fi
    systemctl restart lavalink
    exit 0
fi

if [ `id -u` -ne 0 ]; then
    echo "Please run as root"
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

port="noset"
password="noset"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--port) port="$2"; shift ;;
        -pwd|--password) password="$2"; shift ;;
        *) echo "未知參數: $1"; exit 1 ;;
    esac
    shift
done

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
url="https://api.github.com/repos/lavalink-devs/Lavalink/releases"
latest=$(curl -s $url | jq -r '.[0].tag_name')
wget -O Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/$latest/Lavalink.jar"
mkdir -p Plugins

lavasrcver=$(curl -s https://api.github.com/repos/topi314/LavaSrc/releases | jq -r '.[0].tag_name')
wget -O Plugins/lavasrc-$lavasrcver.jar "https://github.com/topi314/LavaSrc/releases/download/$lavasrcver/lavasrc-$lavasrcver.jar"

lavayoutube=$(curl -s https://api.github.com/repos/lavalink-devs/youtube-source/releases | jq -r '.[0].tag_name')
wget -O Plugins/youtube-plugin-$lavayoutube.jar "https://github.com/lavalink-devs/youtube-source/releases/download/$lavayoutube/youtube-plugin-$lavayoutube.jar"

echo "Downloading Lavalink config..."
lavaapp=$(curl -s https://raw.githubusercontent.com/phillychi3/lavalink-install/main/application.yml)
echo "$lavaapp" > application.yml
sed -i "s|- dependency: com.github.topi314.lavasrc:lavasrc-plugin:*|- dependency: com.github.topi314.lavasrc:lavasrc-plugin:$lavasrcver|" application.yml
sed -i "s|- dependency: \"dev.lavalink.youtube:youtube-plugin:*|- dependency: \"dev.lavalink.youtube:youtube-plugin:$lavayoutube|" application.yml

if [[ $port == "noset" ]]; then
    echo "Please enter the port you want to use (default: 23333):"
    read user_port
    if [[ -n "$user_port" ]]; then
        port=$user_port
    else
        port=23333
    fi
fi

if [[ $password == "noset" ]]; then
    echo "Please enter the password you want to use:"
    read user_password
    if [[ -n "$user_password" ]]; then
        password=$user_password
    else
        echo "password: n0s3tp@ssw0rd"
        password="n0s3tp@ssw0rd"
    fi
fi

sed -i "s|port:.*|port: $port|" application.yml
sed -i "s|password:.*|password: \"$password\"|" application.yml

echo "Register Lavalink as a service..."
lavaservice=$(curl -s https://raw.githubusercontent.com/phillychi3/lavalink-install/main/lavalink.service)
echo "$lavaservice" > lavalink.service
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$PWD|" lavalink.service
sed -i "s|ExecStart=.*|ExecStart=java -jar $PWD/Lavalink.jar|" lavalink.service
cp lavalink.service /etc/systemd/system/lavalink.service
rm lavalink.service

systemctl daemon-reload
systemctl enable lavalink
systemctl start lavalink

echo "Lavalink is now running"
echo "Please Edit your application.yml for more configuration"

echo -e "
Installation finished
------------------------------
Lavalink Port: $port
Lavalink Password: $password
------------------------------
"