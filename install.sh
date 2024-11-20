#!/bin/bash
print_system() {
    echo -e "
    ------------------------------
    OS: $OSNAME
    Version: $VER
    ------------------------------
    "
}

update_package_manager() {
    case $OSID in
        *debian*|*ubuntu*)
            sudo apt-get update
            ;;
        *centos*|*fedora*|*rhel*)
            sudo yum update
            ;;
        *arch*)
            sudo pacman -Syu
            ;;
        *alpine*)
            sudo apk update
            ;;
        *)
            echo "OS not supported"
            exit 1
            ;;
    esac
}

install_java(){
    echo "Installing openjdk-17"
    case $OSID in
        *debian*|*ubuntu*)
            sudo apt-get install openjdk-17-jdk-headless -y
            ;;
        *centos*|*fedora*|*rhel*)
            sudo yum install java-17-openjdk -y
            ;;
        *arch*)
            sudo pacman -S jdk17-openjdk --noconfirm
            ;;
        *alpine*)
            sudo apk add openjdk17
            ;;
        *)
            echo "OS not supported Please install java-17 manually"
            exit 1
            ;;
    esac
}

install_package() {
    # $1: package name for debian/ubuntu
    # $2: package name for centos/fedora
    # $3: package name for arch
    # $4: package name for alpine
    case $OSID in
        *debian*|*ubuntu*)
            echo "Installing $1"
            sudo apt-get install -y $1
            ;;
        *centos*|*fedora*|*rhel*)
            echo "Installing $2"
            sudo yum install $2 -y
            ;;
        *arch*)
            echo "Installing $3"
            sudo pacman -S $3 --noconfirm
            ;;
        *alpine*)
            echo "Installing $4"
            sudo apk add $4
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
        wget -O Plugins/lavasrc-plugin-$lavasrcver.jar "https://github.com/topi314/LavaSrc/releases/download/$lavasrcver/lavasrc-plugin-$lavasrcver.jar"
        sed -i "s|- dependency: \"com.github.topi314.lavasrc:lavasrc-plugin:*\"|- dependency: \"com.github.topi314.lavasrc:lavasrc-plugin:$lavasrcver\"|" application.yml
    fi
    lavayoutube=$(curl -s https://api.github.com/repos/lavalink-devs/youtube-source/releases | jq -r '.[0].tag_name')
    current=$(ls Plugins | grep lavasrc | grep youtube | awk -F'-' '{print $3}' | awk -F'.' '{print $1"."$2"."$3}')
    if [ "$lavayoutube" != "$current" ]; then
        echo "Downloading Youtube-source..."
        wget -O Plugins/youtube-plugin-$lavayoutube.jar "https://github.com/lavalink-devs/youtube-source/releases/download/$lavayoutube/youtube-plugin-$lavayoutube.jar"
    sed -i "s|- dependency: \"dev.lavalink.youtube:youtube-plugin:[0-9.]*\"|- dependency: \"dev.lavalink.youtube:youtube-plugin:$lavayoutube\"|" application.yml
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
spotifyid="noset"
spotifyscrect="noset"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--port) port="$2"; shift ;;
        -pwd|--password) password="$2"; shift ;;
        -sid|--spotifyclientid) spotifyid="$2"; shift ;;
        -scs|--spotifyclientsecret) spotifyscrect="$2"; shift ;;
        *) echo "未知參數: $1"; exit 1 ;;
    esac
    shift
done

echo "Updating package manager..."
update_package_manager

echo "check java..."
if ! [ -x "$(command -v java)" ]; then
    echo "java is not installed"
    echo "installing java..."
    install_java
fi

echo "check curl..."
if ! [ -x "$(command -v curl)" ]; then
    echo "curl is not installed"
    echo "installing curl..."
    install_package curl curl curl curl
fi

echo "check jq..."
if ! [ -x "$(command -v jq)" ]; then
    echo "jq is not installed"
    echo "installing jq..."
    install_package jq jq jq jq
fi

echo "Downloading Lavalink..."
url="https://api.github.com/repos/lavalink-devs/Lavalink/releases"
latest=$(curl -s $url | jq -r '.[0].tag_name')
wget -O Lavalink.jar "https://github.com/lavalink-devs/Lavalink/releases/download/$latest/Lavalink.jar"
mkdir -p Plugins

lavasrcver=$(curl -s https://api.github.com/repos/topi314/LavaSrc/releases | jq -r '.[0].tag_name')
wget -O Plugins/lavasrc-plugin-$lavasrcver.jar "https://github.com/topi314/LavaSrc/releases/download/$lavasrcver/lavasrc-plugin-$lavasrcver.jar"

lavayoutube=$(curl -s https://api.github.com/repos/lavalink-devs/youtube-source/releases | jq -r '.[0].tag_name')
wget -O Plugins/youtube-plugin-$lavayoutube.jar "https://github.com/lavalink-devs/youtube-source/releases/download/$lavayoutube/youtube-plugin-$lavayoutube.jar"

echo "Downloading Lavalink config..."
lavaapp=$(curl -s https://raw.githubusercontent.com/phillychi3/lavalink-install/main/application.yml)
echo "$lavaapp" > application.yml
sed -i "s|- dependency: \"com.github.topi314.lavasrc:lavasrc-plugin:*\"|- dependency: \"com.github.topi314.lavasrc:lavasrc-plugin:$lavasrcver\"|" application.yml
sed -i "s|- dependency: \"dev.lavalink.youtube:youtube-plugin:[0-9.]*\"|- dependency: \"dev.lavalink.youtube:youtube-plugin:$lavayoutube\"|" application.yml

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

if [[ $spotifyid == "noset" ]]; then
    echo "Please enter spotify client id:"
    read spotify_id
    if [[ -n "$spotify_id" ]]; then
        spotifyid=$spotify_id
    else
        echo "you need edit application.yml manually"
    fi
fi

if [[ $spotifyscrect == "noset" ]]; then
    echo "Please enter the spotify secret:"
    read spotify_screct
    if [[ -n "$spotify_screct" ]]; then
        spotifyscrect=$spotify_screct
    else
        echo "you need edit application.yml manually"
    fi
fi

sed -i "s|port:.*|port: $port|" application.yml
sed -i "s|password:.*|password: \"$password\"|" application.yml
sed -i "s|clientId:.*|clientId: \"$spotifyid\"|" application.yml
sed -i "s|clientSecret:.*|clientSecret: \"$spotifyscrect\"|" application.yml

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