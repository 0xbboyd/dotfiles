#!/usr/bin/env sh

# bup init
bup index -u ~/.ssh
bup save -n keys ~/.ssh

bup index -u ~/.gnupg
bup save -n keys ~/.gnupg