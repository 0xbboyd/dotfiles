#!/bin/bash
HOSTNAME=$(hostname)
USER=$(whoami)
# Backup host is sourced from ~/.config/dotfiles/secrets.env (untracked).
: "${BACKUP_HOST:?BACKUP_HOST is not set — source ~/.config/dotfiles/secrets.env}"
rsync -avuzbP /home/$USER root@${BACKUP_HOST}:/mnt/backups/$HOSTNAME/home
#rsync -avuzbP /run/media/bboyd/home/brendan/* root@${BACKUP_HOST}:/mnt/backups/$HOSTNAME/home-partition

