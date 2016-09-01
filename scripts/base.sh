#!/bin/sh -x

# Init pkgsrc
ftp ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz
tar -xzf pkgsrc.tar.gz -C /usr
rm -f pkgsrc.tar.gz

# Install pkgin
cd /usr/pkgsrc/pkgtools/pkgin
make
make install
make clean

# Install ansible requirements
pkgin -y up
pkgin -y in python27



