#!/bin/bash
#===============================================================================
#
#          FILE:  mount.sh
# 
#         USAGE:  ./mount.sh 
# 
#   DESCRIPTION:  Script to (un)mount crypt container
#                 see: http://www.tomshardware.de/Security-Container-Daten-Verschlusselung-TrueCrypt,testberichte-239849-7.html
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  09.01.2012 12:22:56 CET
#      REVISION:  ---
#===============================================================================

MAPPER_NAME=mycrypt
LOOP=/dev/loop3

function help() {
    echo 'crypt.sh COMMAND <parameters>'
    echo '         create <filename> <size>        - create container of size MB'
    echo '         mount  <filename> <mountpoint>  - mount container to mp'
    echo '         umount <mountpoint>             - unmount'
}
function loadmodules() {
    sudo modprobe dm-crypt
}

if [ $# -eq 0 -o "$1" == 'help' ]; then
    help

elif [ "$1" == 'create' ]; then
    if [ $# -lt 3 ]; then
        help
        exit
    fi
    CONTAINER=$2
    if [ -r $CONTAINER ]; then
        echo "ERROR: file exists already!"
        help
        exit
    fi
    SIZE=$3
    if [ $SIZE -lt 1 -o $SIZE -gt 1024 ]; then
        echo "ERROR: size out of bounds!"
        help
        exit
    fi
    MAPPER_NAME=$(basename $CONTAINER)

    loadmodules
    dd if=/dev/zero of="$CONTAINER" bs=1M count=$SIZE
    losetup $LOOP "$CONTAINER"
    dd if=/dev/urandom of=$LOOP bs=512 count=4000
    sudo cryptsetup luksFormat -v -y -s 256 -c aes-cbc-essiv:sha256 $LOOP
    sudo cryptsetup luksOpen $LOOP $MAPPER_NAME
    sudo dd if=/dev/zero of=/dev/mapper/$MAPPER_NAME
    sudo mkfs.ext3 /dev/mapper/$MAPPER_NAME
    sudo cryptsetup luksClose $MAPPER_NAME
    losetup -d $LOOP


elif [ "$1" == 'mount' ]; then
    CONTAINER=$2
    if [ ! -r $CONTAINER ]; then
        echo "ERROR: file does not exist!"
        help
        exit
    fi
    MAPPER_NAME=$(basename $CONTAINER)

    loadmodules
    losetup $LOOP $CONTAINER
    sudo cryptsetup luksOpen $LOOP $MAPPER_NAME
    sudo mkdir -p /mnt/$MAPPER_NAME
    sudo chown wassen.team /mnt/$MAPPER_NAME
    sudo mount -t ext3 /dev/mapper/$MAPPER_NAME /mnt/$MAPPER_NAME
    sudo chown wassen.team /mnt/$MAPPER_NAME

elif [ "$1" == 'umount' ]; then
    CONTAINER=$2
    if [ ! -r $CONTAINER ]; then
        echo "ERROR: file does not exist!"
        help
        exit
    fi
    MAPPER_NAME=$(basename $CONTAINER)

    sudo umount /mnt/$MAPPER_NAME
    sudo rmdir /mnt/$MAPPER_NAME
    sudo cryptsetup luksClose $MAPPER_NAME
    losetup -d $LOOP
    
else
    help
fi


