#!/bin/bash
HOSTNAME=$(hostname)
USER=$(whoami)
rsync -avuzbP /home/$USER root@olympus.tolaeon.io:/mnt/backups/$HOSTNAME/home
#rsync -avuzbP /run/media/bboyd/home/brendan/* root@olympus.tolaeon.io:/mnt/backups/$HOSTNAME/home-partition

