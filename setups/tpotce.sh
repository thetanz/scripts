#!/bin/bash

# https://github.com/telekom-security/tpotce

# create host (replace XXXXX accordingly)
# gcloud compute instances create tpotce --project=XXXXX --zone=australia-southeast1-b --machine-type=e2-standard-2 --network-interface=network-tier=PREMIUM,subnet=default --maintenance-policy=MIGRATE --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=debian-10-buster-v20210817 --image-project=debian-cloud --boot-disk-size=128GB --boot-disk-type=pd-balanced --boot-disk-device-name=tpotce --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
# gcloud config set project XXXXX
# gcloud compute ssh tpotce --zone australia-southeast1-b

sudo timedatectl set-timezone Pacific/Auckland

sudo apt-get -qq update -y
sudo apt-get -qq upgrade -y
sudo apt-get -qq autoclean -y
sudo apt-get -qq autoremove -y

sudo apt-get install -y \
jq \
git \
htop \
tree \
wget \
tcpdump \
python3 \
python3-pip \
unattended-upgrades

git clone https://github.com/telekom-security/tpotce
cd tpotce/iso/installer/
sudo ./install.sh --type=user
