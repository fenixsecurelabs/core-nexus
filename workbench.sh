#!/bin/sh

set -e

docker exec workbench sudo sh -c 'sudo rm /usr/share/backgrounds/ubuntu-mate-common/Green-Wall-Logo.png && \
sudo wget https://raw.githubusercontent.com/Underground-Ops/underground-nexus/main/Wallpapers/underground-nexus-scifi-space-jelly.png -O /usr/share/backgrounds/ubuntu-mate-common/Green-Wall-Logo.png'