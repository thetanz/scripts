#!/bin/bash

if ! [ "$(id -u)" = 0 ]; then
  printf "needs root!"
  exit 0
fi

sudo timedatectl set-timezone Pacific/Auckland

sudo apt-get -qq update -y
sudo apt-get -qq upgrade -y
sudo apt-get -qq autoclean -y
sudo apt-get -qq autoremove -y

# sudo apt-get install -y ufw zsh cowsay lolcat golang-go
# curl -s ipinfo.io | jq .ip,.city,.country -r | cowsay | lolcat --animate --speed=150
# runuser -l ${cloudrole} -c 'touch ~/.hushlogin'
# originaddr=`last | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | sort -u`
# yes | sudo ufw reset > /dev/null
# sudo ufw default deny incoming > /dev/null
# sudo ufw default allow outgoing > /dev/null
# sudo ufw allow from $originaddr to any port 22 proto tcp > /dev/null
# yes | sudo ufw enable > /dev/null

sudo apt-get install -qq -y \
jq \
git \
htop \
tree \
wget \
tcpdump \
python3 \
torsocks \
python3-pip \
unattended-upgrades
