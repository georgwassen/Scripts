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
#        AUTHOR:  Georg Wassen (georg.wassen@googlemail.com), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  03.09.2011 22:35:01 CEST
#      REVISION:  ---
#===============================================================================
#
# Concept:
#  - home : always a complete copy
#  - musik, bilder : incremental (rsync)
#
# open improvements/ideas:
#  - Blacklist : directories not to include in backup (.thumbnails, Downloads, ...)
#


HOST=$(hostname)
#[[ $(hostname). =~ ([a-zA-Z0-9]*)\..* ]]
#HOST=${BASH_REMATCH[1]}
HOST=${HOST%%.*}    # remove longest match to '.*' (file pattern, not regex!) from end


function help()
{
    echo ""
    echo "backup.sh"
    echo "  Backup script to save \$HOME to an external USB hard drive"
    echo "  Mount USB drive somewhere, then call backup.sh /mnt/usb"
    echo "Usage:"
    echo "  $0 [options] <path/to/drive>"
    echo "       -c   --config   print default config to stdout"
    echo "                       (store as ~/.backupsh.rc)"
    echo "       -h   --help     help"
    echo "       -v   --verbose  print what's happening"
    echo ""
    echo ""
    echo ""
}


ARGS=$(getopt -o 'chv' -l 'config,help,verbose' -- "$@")   # parse parameters and store normalized string in $ARGS
eval set -- "$ARGS";                           # set parameters to preprocessed string $ARGS

# defaults
VERBOSE=''

function print_defconfig()
{
    echo $1"VERBOSE='$VERBOSE'"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            print_defconfig ''
            exit
            ;;
        -h|--help)
            help
            exit
            ;;
        -v|--verbose)
            VERBOSE=-v
            ;;
        --)
            ;;
        *)
            echo "thats an unknown parameter: '$1'"
    esac
    shift
done


if [[ $VERBOSE ]]; then
    echo
    echo "/-----[ current config ]---------"
    print_defconfig "| "
    echo "| HOST='$HOST' "
    echo "|  "
    echo "\--------------------------------"
    sleep 2
fi

exit

#
# Helper function to log into file and to screen
#
LOGFILE=./backup_${HOST}_$(date +%F_%H-%M-%S).log
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


DIR_DATE=$DIR/${HOST}_$(date +"%Y_%m_%d")/
if [ -d $DIR_DATE ]; then
    log Directory $DIR_DATE exists, skipping full backup, doing only rsync.
    # TODO : rsync of Home-Dir
else
    log Using directory: $DIR_DATE
    mkdir $DIR_DATE

    # 2012-05-04: add --no-dereference
    cp --archive --no-dereference $VERBOSE /home/georg $DIR_DATE
fi



if [[ $HOST = venus ]]; then
    RSYNC_OPTIONS="-art --fuzzy --delete-delay $VERBOSE "
    log "Starting rsync bilder at $(date +%F_%H-%M-%S)"
    rsync $RSYNC_OPTIONS /home/bilder/ $DIR/bilder
    log "Starting rsync musik at $(date +%F_%H-%M-%S)"
    rsync $RSYNC_OPTIONS /home/musik/lokal/ $DIR/musik
else
    log "Skipping rsync bilder and musik"
fi




log Backup finished. "($STARTTIME .. $(date +%T))"
du -sh $DIR/* 2>/dev/null | tee -a $LOGFILE

mkdir -p $DIR/log
cp $LOGFILE $DIR/log/

