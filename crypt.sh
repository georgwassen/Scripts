#!/bin/bash
#===============================================================================
#
#          FILE:  mount.sh
# 
#         USAGE:  ./mount.sh 
# 
#   DESCRIPTION:  Script to (un)mount crypt container
#                 see: 
#                 http://www.tomshardware.de/Security-Container-Daten-Verschlusselung-TrueCrypt,testberichte-239849-7.html
#                 http://de.opensuse.org/SDB:Sicherheit_Verschl%C3%BCsselung_mit_LUKS
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

# TODO: find unused loop device...
LOOP=/dev/loop3

#
# print help
#
function help() {
    echo 'crypt.sh COMMAND <parameters>'
    echo '         create <filename> <size>    - create container of size MB'
    echo '         mount  <filename>           - mount container to mp'
    echo '         umount <filename>           - unmount'
}

#
# load needed kernel modules
#
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

    # make sure, the needed modules are there
    loadmodules

    # create a file of requested size
    dd if=/dev/zero of="$CONTAINER" bs=1M count=$SIZE

    # bind the file to a loop device
    # this is done as user, who needs rw access rights on /dev/loopX
    # (on Fedora, the group 'disk' has these rights)
    losetup $LOOP "$CONTAINER"

    # fill first few blocks with random data
    dd if=/dev/urandom of=$LOOP bs=512 count=4000

    # setup a LUKS container on the loop device (must be root)
    # this will ask, if you're sure and for the passphrase
    sudo cryptsetup luksFormat -v -y -s 256 -c aes-cbc-essiv:sha256 $LOOP

    # open as root, needs the passphrase
    sudo cryptsetup luksOpen $LOOP $MAPPER_NAME

    # fill the whole partition with zeros (which will be encrypted an result in random data in the container file)
    sudo dd if=/dev/zero of=/dev/mapper/$MAPPER_NAME

    # now create an EXT3 partition
    sudo mkfs.ext3 /dev/mapper/$MAPPER_NAME

    # close LUKS and unbind loop device, so that the container can be mounted afterwards.
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
    
    # bind the container file to a loop device
    losetup $LOOP $CONTAINER

    # open the LUKS container (asks for the password)
    sudo cryptsetup luksOpen $LOOP $MAPPER_NAME

    # create a mount directory (based on the container file name) and changes its ownership to the user
    sudo mkdir -p /mnt/$MAPPER_NAME
    sudo chown wassen.team /mnt/$MAPPER_NAME

    # mount mapped LUKS partition to the created mountpoint
    sudo mount -t ext3 /dev/mapper/$MAPPER_NAME /mnt/$MAPPER_NAME

    # grant access rights to the user
    sudo chown wassen.team /mnt/$MAPPER_NAME

elif [ "$1" == 'umount' ]; then
    CONTAINER=$2
    if [ ! -r $CONTAINER ]; then
        echo "ERROR: file does not exist!"
        help
        exit
    fi
    MAPPER_NAME=$(basename $CONTAINER)

    # unmount
    sudo umount /mnt/$MAPPER_NAME
    # remove mount point
    sudo rmdir /mnt/$MAPPER_NAME
    # close LUKS container
    sudo cryptsetup luksClose $MAPPER_NAME
    # and remove loop device
    losetup -d $LOOP
    
else
    # all other commands
    echo "unknown command"
    help
fi


