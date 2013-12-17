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

RCFILE=~/.backupsh.rc


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
    echo "       -b B --blacklist=B  exclude patterns for home dir (separated by space"
    echo "                           or multiple occurences, 'quote' special characters)"
    echo "       -c   --config       print default config to stdout"
    echo "                           (store as ${RCFILE})"
    echo "       -d   --dry-run      don't copy anything (hint: use /tmp as target dir)"
    echo "       -h   --help         help"
    echo "       -l L --log-dir=L    directory for log file"
    echo "       -r R --repo=R       directory with repository checkouts"
    echo "       -s S --rsync=S      directory to rsync (incremental backup)"
    echo "       -v   --verbose      print what's happening"
    echo "       B,R          space-separated lists of patterns or directories"
    echo "       S            space-sep. list of TARGET=SOURCE pairs"
    echo ""
}


ARGS=$(getopt -o 'bcdhl:r:s:v' -l 'blacklist,config,dry-run,help,log-dir:,repo:,rsync:,verbose' -- "$@")   # parse parameters and store normalized string in $ARGS
eval set -- "$ARGS";                           # set parameters to preprocessed string $ARGS

# defaults
BLACKLIST=''    # space separated list, e.g. 'checkout tmp'
REPO_DIRS=''    # space separated list, supported: Subversion, Git
RSYNC_DIRS=''   # space separated list of target=source pairs, e.g. 'musik=/home/musik bilder=~/Bilder'
LOGDIR=~/log
SOURCEDIR=~
TARGETDIR=''
VERBOSE=''
DRY_RUN=0

# read config file
if [[ -r $RCFILE ]]; then
    source $RCFILE
fi

function print_defconfig()
{
    # optional first argument: prefix for printed lines
    echo $1"VERBOSE='$VERBOSE'"
    echo $1"LOGDIR='$LOGDIR'"
    echo $1"BLACKLIST='$BLACKLIST'"
    echo $1"REPO_DIRS='$REPO_DIRS'"
    echo $1"RSYNC_DIRS='$RSYNC_DIRS'"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--blacklist)
            BLACKLIST="$BLACKLIST $1"
            ;;
        -c|--config)
            print_defconfig ''
            exit
            ;;
        -d|--dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            help
            exit
            ;;
        -l|--log-dir)
            LOGDIR="$1"
            shift
            ;;
        -r|--repo)
            REPO_DIRS="$REPO_DIRS $1"
            shift
            ;;
        -s|--rsync)
            RSYNC_DIRS="$RSYNC_DIRS $1"
            shift
            ;;
        -v|--verbose)
            VERBOSE=-v
            ;;
        --)
            ;;
        -*)
            echo "thats an unknown parameter: '$1'"
            ;;
        *)
            TARGETDIR=$1
    esac
    shift
done

#
# checking parameters
#

if [[ -z $TARGETDIR ]]; then
    help
    echo "ERROR: No directory provided!"
    echo
    exit 1
fi
if [[ ! -d $TARGETDIR ]]; then
    help
    echo "ERROR: Directory '$TARGETDIR' does not exist!"
    echo
    exit 1
fi
if [[ ! -w $TARGETDIR ]]; then
    help
    echo "ERROR: Directory '$TARGETDIR' is not writeable!"
    echo
    exit 1
fi

#
# Helper function to log into file and to screen
#
LOGFILE=$LOGDIR/backup_${HOST}_$(date +%F_%H-%M-%S).log
function log()
{
    echo $* | tee -a $LOGFILE
}


#
# display config (if verbose)
#
DIR_DATE=$TARGETDIR/${HOST}_$(date +"%Y_%m_%d")/
if [[ $VERBOSE ]]; then
    echo
    echo "/-----[ current config ]---------"
    print_defconfig "| "
    echo "| HOST='$HOST' "
    echo "| SOURCEDIR='$SOURCEDIR' "
    echo "| TARGETDIR='$TARGETDIR' "
    echo "| LOGFILE='$LOGFILE' "
    echo "| DIR_DATE='$DIR_DATE' "
    echo "\--------------------------------"
    sleep 5
fi




STARTTIME=$(date +%T)
log "Starting backup at $STARTTIME to $TARGETDIR"


if [ -d $DIR_DATE ]; then
    log Directory $DIR_DATE exists, skipping full backup, doing only rsync.
    # TODO : rsync of Home-Dir
else
    log Using directory: $DIR_DATE
    mkdir $DIR_DATE

    for PATTERN in $BLACKLIST; do
        EXCLUDE="$EXCLUDE --exclude '$PATTERN'"
    done
    # 2012-05-04: add --no-dereference
    #cp --archive --no-dereference $VERBOSE /home/georg $DIR_DATE
    # 2013-12-17: use rsync to allow a blacklist of directories
    #  cp arguments:
    #        --archive        -- same as -dR --preserve=all
    #        -d               -- same as --no-dereference --preserve=links
    #        -R               -- recursive
    #        --preserve=all   -- preserve file attributes
    #        --no-dereference -- never follow symbolic links
    #  rsync arguments:
    #        --archive        -- same as -rlptgoD
    #        -r               -- recursive
    #        -l               -- copy symlinks as symlinks
    #        -p               -- preserve permissions
    #        -t               -- preserve modification times
    #        -g               -- preserve group
    #        -o               -- preserve owner
    #        -D               -- same as --devices --specials
    #        --devices        -- preserve device files (super-user only)
    #        --specials       -- preserve special files
    if [[ $DRY_RUN -eq 0 ]]; then
        rsync --archive $VERBOSE $EXCLUDE ${SOURCEDIR} $DIR_DATE
    else
        log "DRY-RUN"
        echo "DRY-RUN: rsync --archive $VERBOSE $EXCLUDE ${SOURCEDIR} $DIR_DATE"
    fi
fi

log "Finished with home at $(date +%T)"


#
# log content of REPO_DIRS (which Git and Subversion repos are there?)
#
log "Starting repo handling for $REPO_DIRS at $(date +%T)"
for D in $REPO_DIRS; do
    for R in $SOURCEDIR/$D/*; do
        if [[ -d $R ]]; then
            if [[ -d $R/.git ]]; then
                # Git repo
                log "Git: $R"
                cat $R/.git/config >> $LOGFILE
            elif [[ -d $R/.svn ]]; then
                # Subversion repo
                log "Subversion: $R"
                pushd $R
                svn info >> $LOGFILE
                popd
            fi
        fi
    done
done
log "Finished repo handling at $(date +%T)"


#
# rsync incremental dirs
#
log "Starting rsync for $RSYNC_DIRS at $(date +%T)"
RSYNC_OPTIONS="-art --fuzzy --delete-delay $VERBOSE "
for TOKEN in $RSYNC_DIRS; do
    TARGET=${TOKEN%%=*}
    SOURCE=${TOKEN##*=}
    echo "RSYNC: '$TARGET'='$SOURCE'"
    if [[ $DRY_RUN -eq 0 ]]; then
        log "Starting rsync $TARGET at $(date +%F_%H-%M-%S)"
        rsync $RSYNC_OPTIONS $SOURCE/ $TARGETDIR/$TARGET
    else
        log "DRY-RUN: Starting rsync $TARGET at $(date +%F_%H-%M-%S)"
        echo "DRY-RUN: rsync $RSYNC_OPTIONS $SOURCE/ $TARGETDIR/$TARGET"
    fi
done
log "Finished rsync at $(date +%T)"

# previous settings:
# venus:
#   /home/bilder/        -> $TARGETDIR/bilder
#   /home/musik/lokal/   -> $TARGETDIR/musik
# saturn:
#   ~/bilder/            -> $TARGETDIR/bilder
#   ~/Musik/lokal/       -> $TARGETDIR/musik



log Backup finished. "($STARTTIME .. $(date +%T))"
du -sh $TARGETDIR/* 2>/dev/null | tee -a $LOGFILE

cp $LOGFILE $TARGETDIR/

