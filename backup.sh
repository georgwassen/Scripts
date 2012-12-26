#!/bin/bash
#===============================================================================
#
#          FILE:  backup.sh
# 
#         USAGE:  ./backup.sh <target dir>
# 
#   DESCRIPTION:  Backup script to back up ~, bilder and musik to USB hard disk
#                 
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  03.09.2011 22:35:01 CEST
#      REVISION:  ---
#===============================================================================
#
# Konzept:
#  - home : jedesmal komplett
#  - musik, bilder : inkrementell
#
# Verbesserungen/Ideen:
#  - Blacklist : Verzeichnisse nicht berücksichtigen (.thumbnails, Downloads, ...)
#

VERBOSE=-v


#
# Helper function to log into file and to screen
#
LOGFILE=./backup_$(date +%F_%H-%M-%S).log
function log()
{
    echo $* | tee -a $LOGFILE
}


#
# checking parameters
#
if [ $# -lt 1 ]; then
    echo Usage: $0 '<target dir>'
    exit 1
fi

DIR=$1
if [ ! -d $DIR ]; then
    echo Directory $DIR does not exist!
    exit 1
fi

STARTTIME=$(date +%T)
log "Starting backup at $STARTTIME to $DIR"


DIR_DATE=$DIR/$(date +"%Y_%m_%d")/
if [ -d $DIR_DATE ]; then
    log Directory $DIR_DATE exists, skipping full backup, doing only rsync.
    # TODO : rsync of Home-Dir
else
    log Using directory: $DIR_DATE
    mkdir $DIR_DATE

    # 2012-05-04: add --no-dereference
    cp --archive --no-dereference $VERBOSE /home/georg $DIR_DATE

fi
RSYNC_OPTIONS="-art --fuzzy --delete-delay $VERBOSE "
log "Starting rsync bilder at $(date +%F_%H-%M-%S)"
rsync $RSYNC_OPTIONS /home/bilder/ $DIR/bilder
log "Starting rsync musik at $(date +%F_%H-%M-%S)"
rsync $RSYNC_OPTIONS /home/musik/lokal/ $DIR/musik




log Backup finished. "($STARTTIME .. $(date +%T))"
du -sh $DIR/* 2>/dev/null | tee -a $LOGFILE

mkdir -p $DIR/log
cp $LOGFILE $DIR/log/

