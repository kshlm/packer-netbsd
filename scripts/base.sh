#!/bin/sh -x

ftp ftp://ftp.NetBSD.org/pub/pkgsrc/current/pkgsrc.tar.gz
tar -xzf pkgsrc.tar.gz -C /usr
rm -f pkgsrc.tar.gz
cd /usr/pkgsrc/www/curl
make install clean clean-depends distclean
