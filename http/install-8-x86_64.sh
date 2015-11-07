#
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/sbin:/usr/pkg/bin
export PATH

set -e

#
r=/targetroot
release=7.0 # XXX

# disk partition
echo '/total sectors:/{' > /tmp/sed.$$
echo 's/.*sectors: //' >> /tmp/sed.$$
echo 's/,.*//' >> /tmp/sed.$$
echo p >> /tmp/sed.$$
echo q >> /tmp/sed.$$
echo '}' >> /tmp/sed.$$
wd_size="$(fdisk sd0d 2>/dev/null | sed -n -f /tmp/sed.$$)"
fdisk -i -a -0 -f -u -s 169/63/$(($wd_size - 63)) /dev/sd0

# disklabel
root_size="$(($wd_size - 63))"
disklabel -t sd0 > /tmp/disktab.$$ || true # XXX
sed -e "s/generated label/generated label|mylabel/" \
    -e "s/:pe#.*/:pa#$root_size:oa#63:ta=4.2BSD:ba#16384:fa#2048:pb#$swap_size:ob#$(($root_size + 63)):tb=swap:/" \
    /tmp/disktab.$$ > /tmp/newdisktab.$$
disklabel -w -f /tmp/newdisktab.$$ sd0 mylabel

# newfs
newfs -O 2 /dev/sd0a

# mount root
mount /dev/sd0a $r

# extract sets
for s in base etc comp kern-GENERIC man misc modules text ; do
  ( cd $r && tar --chroot -zxhepf /amd64/binary/sets/$s.tgz )
done

# MAKEDEV
( cd $r/dev && sh ./MAKEDEV all )

# fstab
mkdir $r/kern
mkdir $r/proc
echo "/dev/sd0a /    ffs  rw,log,softdep 1 1" > $r/etc/fstab
echo "/kern /kern kernfs rw 0 0" >> $r/etc/fstab
echo "/proc /proc procfs rw 0 0" >> $r/etc/fstab
echo "fdesc /dev fdesc ro,-o=union 0 0" >> $r/etc/fstab
echo "ptyfs /dev/pts ptyfs rw 0 0" >> $r/etc/fstab
echo "tmpfs /tmp tmpfs rw,-s96M" >> $r/etc/fstab

# installboot
chroot $r cp /usr/mdec/boot /boot
chroot $r /usr/sbin/installboot -f /dev/rsd0a /usr/mdec/bootxx_ffsv2

# root password
passhash="$(chroot $r pwhash packer)"
sed -e "s,^root::,root:$passhash:," $r/etc/master.passwd > /tmp/master.passwd
cp /tmp/master.passwd $r/etc/master.passwd
chown 0:0 $r/etc/master.passwd
chmod 600 $r/etc/master.passwd
chroot $r pwd_mkdb -p /etc/master.passwd

# hostname & network config
echo hostname=build >> $r/etc/rc.conf
echo ifconfig_vioif0=dhcp >> $r/etc/rc.conf

# ssh config
echo 'UseDNS no' >> $r/etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> $r/etc/ssh/sshd_config
#echo 'NoneEnabled yes' >> $r/etc/ssh/sshd_config
echo sshd=YES >> $r/etc/rc.conf

# misc configuration
echo wscons=YES >> $r/etc/rc.conf
sed -e 's/^rc_configured=NO/rc_configured=YES/' $r/etc/rc.conf > /tmp/rc.conf
cp /tmp/rc.conf $r/etc/rc.conf

# kill dhcpcd and relaunch it in chroot
#kill -TERM $(cat /var/run/dhclient.pid)
#chroot $r dhclient vioif0

# setup pkgin
#chroot $r pkg_add http://ftp.NetBSD.org/pub/pkgsrc/packages/NetBSD/amd64/$release/All/pkgin
#sed -e 's,^[^#].*$,http://ftp.NetBSD.org/pub/pkgsrc/packages/NetBSD/$arch/'$release'/All,' $r/usr/pkg/etc/pkgin/repositories.conf > /tmp/repositories.conf
#mv /tmp/repositories.conf $r/usr/pkg/etc/pkgin/repositories.conf
#chroot $r pkgin -y update
reboot
