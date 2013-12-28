#!/bin/bash
#===============================================================================
#
#          FILE:  gitanalyzer.sh
# 
#         USAGE:  ./gitanalyzer.sh 
# 
#   DESCRIPTION:  Analyze Git repo (age, remote connections, etc.)
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Georg Wassen (georg.wassen@googlemail.com), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  28.12.2013 12:20:22 CET
#      REVISION:  ---
#===============================================================================

COLERROR='\033[1;31m'
COLDIR='\033[1;34m'
COLDATE='\033[1;33m'
COLREMOTE='\033[1;31m'
COLACTION='\033[1;36m'
COLRESET='\033[0m'

# parse command line arguments

function usage() {
    echo
    echo "Analyze Git Repo"
    echo "print some basic infos about age, source, etc."
    echo "Usage:"
    echo "  $(basename $0) [parameters] [<dir>]"
    echo "  Parameters: "
    echo "    -h  --help       print this help message"
    echo
}


ARGS=$(getopt -o 'h' -l 'help' -- "$@")   # parse parameters and store normalized string in $ARGS
eval set -- "$ARGS";                           # set parameters to preprocessed string $ARGS

PARAM_WD=$PWD

while [[ $# -gt 0 ]]; do
    #echo "1='$1'"
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        #-e|--edit)
        #    PARAM_EDIT="gvim -p "
        #    ;;
        --)
            ;;
        *)
            # set as search term
            PARAM_WD="$1"
            ;;
    esac
    shift
done

#echo "PARAM_WD='$PARAM_WD'"


cd $PARAM_WD

DIR=''
# find .git
if [[ -d .git ]]; then
    DIR=$PARAM_WD
else
    while [[ $PWD != / ]]; do
        cd ..
        if [[ -d .git ]]; then
            DIR=$PWD
            break
        fi
    done
fi
if [[ -z $DIR ]]; then
    echo -e $COLERROR"ERROR: no .git directory found in path '$PARAM_WD'"$COLRESET
    exit
fi

echo -e "using Git base dir $COLDIR'$DIR'$COLRESET"



# try to derive the age (date of init or clone) from .git files
# (use oldest file in .git directory)
echo -n "init'ed or clone'd most probably on: "
stat -c '%Y %y %n' $DIR/.git/* | sort | head -n1 | awk '{print "'$COLDATE'" $2 " " $3  "'$COLRESET' (" $5 ")" }'


# short history (derived from .git/logs)
#   convert UNIX time stamp to readable format: date -d @1386429090 +'%Y-%m-%d %H:%M:%S'

read REV0 REV1 REST < <(head -n1 $DIR/.git/logs/HEAD)
#echo "REV0   = '$REV0'"
#echo "REV1   = '$REV1'"
NAME=${REST%% <*}
#echo "NAME   = '$NAME'"
REST=${REST##* <}
MAIL=${REST%%>*}
#echo "MAIL   = '$MAIL'"
REST=${REST##*> }
read TIME ZONE ACTION < <(echo $REST )
#echo "TIME   = '$TIME'"
#echo "ZONE   = '$ZONE'"
DATE=$(date -d@$TIME  +'%Y-%m-%d %H:%M:%S')
#echo "ACTION = '$ACTION'"
if [[ -z $ACTION ]]; then
    ACTION="git init"
fi

echo -e "Source of this Repo: $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET"

# remote links
echo -n "Remote links: "
echo -en "$COLREMOTE"
git remote -v | cut  -f1-2 | cut -d' ' -f1 | sort | uniq
echo -en "$COLRESET"

# git-svn
SVNINFO=$(git svn info 2>&1)
if [[ ! "$SVNINFO" =~ ^Unable ]]; then
    echo -n "Git-SVN info: " $SVNINFO
fi

# last commit
# formats:
#  %h   abbreviated sha1 hash
#  %ci  commit date (iso format)
#  %d   decorate (ref names)
#  %s   subject
#  %C.. color
echo -n "Last commit: "
git --no-pager log --all -n1 --format='%C(yellow dim)%h %C(yellow bold)%ci%Creset%d %C(white bold)%s%Creset' 


