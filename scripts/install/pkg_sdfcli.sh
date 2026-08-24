#!/usr/bin/env sh

echo "updating binaries"
sudo apt update
echo "installing maven"
sudo apt install maven -y

echo "remove old sdf dir"
sudo rm -fr /opt/sdf
sudo mkdir -p /opt/sdf

# URLs contain an internal NetSuite account ID — sourced from
# ~/.config/dotfiles/secrets.env (untracked), not hardcoded here.
: "${NS_SDF_JAR_URL:?NS_SDF_JAR_URL is not set — source ~/.config/dotfiles/secrets.env}"
: "${NS_SDF_SUPPORT_URL:?NS_SDF_SUPPORT_URL is not set — source ~/.config/dotfiles/secrets.env}"

echo "get sdf jar"
wget "$NS_SDF_JAR_URL" -O /opt/sdf/com.netsuite.ide.core_2017.1.2.jar
echo "get support files"
sudo wget -qO- "$NS_SDF_SUPPORT_URL" | sudo tar xvz -C /opt/sdf/

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
