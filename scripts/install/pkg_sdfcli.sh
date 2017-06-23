#!/usr/bin/env sh

echo "updating binaries"
sudo apt update
echo "installing maven"
sudo apt install maven -y

echo "remove old sdf dir"
sudo rm -fr /opt/sdf
sudo mkdir -p /opt/sdf

echo "get sdf jar"
wget https://system.netsuite.com/download/ide/update_17_1/plugins/com.netsuite.ide.core_2017.1.2.jar -O /opt/sdf/com.netsuite.ide.core_2017.1.2.jar
echo "get support files"
sudo wget -qO- "https://system.netsuite.com/core/media/media.nl?id=78304610&c=NLCORP&h=7815ede561a186622753&_xd=T&_xt=.bin" | sudo tar xvz -C /opt/sdf/

echo "create sdfcli sh file"
sudo bash -c "cat <<EOF > /opt/sdf/sdfcli

#!/bin/bash¬                                                                                     
mvn -f /opt/sdf/pom.xml exec:java -Dexec.args=""$*""

EOF"
echo "execute permissions"
sudo chmod +x /opt/sdf/sdfcli

echo "symlink to the bin"
ln -s /opt/sdf/sdfcli /usr/local/bin/sdfcli
ln -s /opt/sdf/sdfcli-createproject /usr/local/bin/sdfcli-createproject

echo "test run with --help"
sdfcli --help
