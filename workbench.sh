#!/bin/sh

set -e

for i in workbench; do docker exec -i $i sh -c "sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install wget apt-transport-https curl -y"; done

docker exec workbench sh -c "sudo apt-get install qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils synaptic virt-manager -y"

docker exec workbench sh -c "wget -O terraform-amd64.zip https://releases.hashicorp.com/terraform/1.2.3/terraform_1.2.3_linux_amd64.zip && \
    unzip terraform-amd64.zip && \
    mv terraform usr/local/bin && \
    touch ~/.bashrc && \
    terraform -install-autocomplete"

docker exec workbench sudo sh -c "wget -qO - https://mirror.mwt.me/ghd/gpgkey | tee /etc/apt/trusted.gpg.d/shiftkey-desktop.asc > /dev/null"

docker exec workbench sudo sh -c 'echo "deb [arch=amd64] https://mirror.mwt.me/ghd/deb/ any main" > /etc/apt/sources.list.d/packagecloud-shiftkey-desktop.list'

docker exec workbench sudo sh -c 'sudo apt-get update -y && sudo apt-get install github-desktop -y'

docker exec workbench sudo sh -c 'sudo apt-get install xvfb xbase-clients python3-psutil -y'

docker exec workbench sudo sh -c 'wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
sudo dpkg -i chrome-remote-desktop_current_amd64.deb &&
rm chrome-remote-desktop_current_amd64.deb'

docker exec workbench sudo sh -c 'wget https://release.gitkraken.com/linux/gitkraken-amd64.deb && \
sudo dpkg -i gitkraken-amd64.deb && \
rm gitkraken-amd64.deb'

docker exec workbench sudo sh -c 'sudo rm /usr/share/backgrounds/ubuntu-mate-common/Green-Wall-Logo.png && \
sudo wget https://raw.githubusercontent.com/Underground-Ops/underground-nexus/main/Wallpapers/underground-nexus-scifi-space-jelly.png -O /usr/share/backgrounds/ubuntu-mate-common/Green-Wall-Logo.png'

docker exec Security-Operation-Center sudo sh -c 'sudo apk update && sudo apk add wget dpkg && apk upgrade'