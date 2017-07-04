#!/usr/bin/env sh

curl -sL https://raw.githubusercontent.com/eclipse/che/master/che.sh > /usr/local/bin/che
chmod +x /usr/local/bin/che

che start
