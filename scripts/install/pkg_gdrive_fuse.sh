#!/usr/bin/env sh

# install gdrive fuse fs
sudo add-apt-repository ppa:alessandro-strada/ppa
sudo apt-get update
sudo apt-get install google-drive-ocamlfuse

# add parameterized bash script for mounting w/ gdrivefuse
gdrive="#\!/bin/bash\n"
gdrive+="su $USERNAME -l -c \"google-drive-ocamlfuse -label \$1 \$*\"\n"
gdrive+="exit 0"
sudo sh -c "echo $gdrive > /usr/bin/gdrive.sh"
sudo chmod +x /usr/bin/gdfuse
mkdir ~/gdrive

# add file system table entry for fuse drive
mountpt="gdfuse#default  /home/$USERNAME/gdrive     fuse    uid=1000,gid=1000,user     0       0"
sudo sh -c "echo $mountpt >> /etc/fstab"

# initiate headless auth of google drive

# mount drive 
mount ~/gdrive