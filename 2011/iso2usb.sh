#!/bin/bash

# Script for job "Gentoo Linux LiveUSB HOWTO"
# http://www.gentoo.org/doc/en/liveusb.xml

function die() {
  echo $1
  exit 1
}

# $1 - mount-point
# returns: RET_MOUNTED_DEVICE
function check_mount_point(){
  device=`mount | grep $1 | cut -f 1 -d " "`
  [ -z $device ] && die "Wrong mount-point! ($1)"
  RET_MOUNTED_DEVICE=$device
}

[ -z "$1" ] && die "Usage: `basename $0` <iso-mount-point> <usb-mount-point>"

ISO_MOUNT=`readlink -f $1`
USB_MOUNT=`readlink -f $2`

for mp in ISO USB; do
  var_mp="${mp}_MOUNT"
  var_dev="${mp}_DEVICE"
  check_mount_point ${!var_mp}
  export $var_dev="${RET_MOUNTED_DEVICE}"
done

[ "`ls ${USB_MOUNT} | wc -l`" == "0" ] || die "USB should be empty! (${USB_MOUNT})"

echo ""
echo "Making USB boot drive from ISO"
echo "-------------------------------------------------"
echo "ISO-content: ${ISO_MOUNT}"
echo "USB: ${USB_MOUNT} (${USB_DEVICE})"
echo "-------------------------------------------------"
echo ""

JOBS=("${JOBS[@]}" "cp -r ${ISO_MOUNT}/* ${USB_MOUNT}")
JOBS=("${JOBS[@]}" "mv ${USB_MOUNT}/isolinux/* ${USB_MOUNT}")
JOBS=("${JOBS[@]}" "mv ${USB_MOUNT}/isolinux.cfg ${USB_MOUNT}/syslinux.cfg")
JOBS=("${JOBS[@]}" "rm -rf ${USB_MOUNT}/isolinux*")
JOBS=("${JOBS[@]}" "umount ${USB_MOUNT}")
JOBS=("${JOBS[@]}" "syslinux ${USB_DEVICE}")

echo "This commands will be performed:"
range={0..${#JOBS[@]}}
for ((i=0; i<${#JOBS[@]}; i++)); do
  echo " > ${JOBS[i]}"
done

[ "`id -u`" == "0" ] || die "You should be root!"

echo ""
ANS="init"
until [[ "${ANS}" == "yes" || ${ANS} == "no" ]]; do
  echo -n "Perform? (yes/no): "
  read ANS
done

echo ""
if [ "${ANS}" == "yes" ]; then
  echo "Performing..."

  range={0..${#JOBS[@]}}
  for ((i=0; i<${#JOBS[@]}; i++)); do
    echo " # ${JOBS[i]}"
    ${JOBS[i]}
  done
  echo "done!"

  echo ""
  echo "You should install mbr (only once)"
  echo " # dd if=/usr/share/syslinux/mbr.bin of=${USB_DEVICE}"
  echo ""
  echo "Then you can reboot :)"
else
  echo "Canceled"
fi


