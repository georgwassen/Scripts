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

# parse command line arguments

function usage() {
    echo
    echo "Analyze Git Repo"
    echo "print some basic infos about age, source, etc."
    echo "Usage:"
    echo "  $(basename $0) [parameters] [<dir>]"
    echo "  Parameters: "
    echo "    -h  --help       print this help message"
    echo "    -n  --no-color   don't use colors"
    echo "    -v  --verbose    be more verbose (increments)"
    echo
}


ARGS=$(getopt -o 'hnv' -l 'help,no-color,verbose' -- "$@")   # parse parameters and store normalized string in $ARGS
eval set -- "$ARGS";                           # set parameters to preprocessed string $ARGS

PARAM_WD=$PWD
PARAM_VERBOSE=0
PARAM_COLOR=1

while [[ $# -gt 0 ]]; do
    #echo "1='$1'"
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        -n|--no-color)
            PARAM_COLOR=0
            ;;
        -v|--verbose)
            PARAM_VERBOSE=$(( PARAM_VERBOSE + 1 ))
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

# set colors (leave empty to deactivate)
if [[ $PARAM_COLOR -ge 1 ]]; then
    COLERROR='\033[1;31m'
    COLDIR='\033[1;34m'
    COLDATE='\033[1;33m'
    COLREMOTE='\033[1;31m'
    COLACTION='\033[1;36m'
    COLRESET='\033[0m'

    # colors for git log --format
    COLGITHASH='%C(yellow dim)'
    COLGITDATE='%C(yellow bold)'
    COLGITSUBJECT='%C(white bold)'
    COLGITRESET='%Creset'
fi

#echo "PARAM_WD='$PARAM_WD'"


# use echo_v1 to print only on verbose==1
function echo_v1()
{
if [[ $PARAM_VERBOSE -eq 1 ]]; then
    echo "$@"
fi
}
function echo_v2()
{
if [[ $PARAM_VERBOSE -ge 2 ]]; then
    echo "$@"
fi
}


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

echo -e "Using Git base dir $COLDIR'$DIR'$COLRESET"



# try to derive the age (date of init or clone) from .git files
# (use oldest file in .git directory)
echo -n "Init'ed or clone'd most probably on: "
stat -c '%Y %y %n' $DIR/.git/* | sort | head -n1 | awk '{print "'$COLDATE'" $2 " " $3  "'$COLRESET' (" $5 ")" }'


# short history (derived from .git/logs)
#   convert UNIX time stamp to readable format: date -d @1386429090 +'%Y-%m-%d %H:%M:%S'
function tokenize_log()
{
read REV0 REV1 REST < <(echo "$@")
echo_v2 "REV0   = '$REV0'"
echo_v2 "REV1   = '$REV1'"
NAME=${REST%% <*}
#echo "NAME   = '$NAME'"
REST=${REST##* <}
MAIL=${REST%%>*}
echo_v2 "MAIL   = '$MAIL'"
REST=${REST##*> }
read TIME ZONE ACTION < <(echo $REST )
echo_v2 "TIME   = '$TIME'"
echo_v2 "ZONE   = '$ZONE'"
DATE=$(date -d@$TIME  +'%Y-%m-%d %H:%M:%S')
echo_v2 "ACTION = '$ACTION'"
if [[ -z $ACTION ]]; then
    ACTION="git init"
fi
}

if [[ $PARAM_VERBOSE -ge 1 ]]; then
    echo -e "History of master"
    while read LINE; do
        tokenize_log "$LINE"
        echo -e "   $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET by $NAME $MAIL"
    done < <(cat $DIR/.git/logs/refs/heads/master)
else
    tokenize_log $(head -n1 $DIR/.git/logs/HEAD)
    echo -e "Source of this Repo: $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET"

    tokenize_log $(tail -n1 $DIR/.git/logs/HEAD)
    echo -e "Last action: $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET by $NAME $MAIL"
fi

# remote links
echo  "Remote links: "
#echo -en "$COLREMOTE"
#git remote -v | cut  -f1-2 | cut -d' ' -f1 | sort | uniq
#echo -en "$COLRESET"


for D in $DIR/.git/logs/refs/remotes/*; do
    REMOTE=${D##*/}
    REMSERVER=$(git remote -v | grep $REMOTE | cut  -f2 | cut -d' ' -f1 | sort | uniq)
    echo -e "History of $COLREMOTE$REMOTE ($REMSERVER)$COLRESET"
    if [[ $PARAM_VERBOSE -ge 1 ]]; then
        while read LINE; do
            tokenize_log "$LINE"
            echo -e "   $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET by $NAME $MAIL"
        done < <(cat $D/master)
    else
        tokenize_log $(head -n1 $D/master)
        echo -e "  First action: $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET"

        tokenize_log $(tail -n1 $D/master)
        echo -e "  Last action: $COLACTION$ACTION$COLRESET on $COLDATE$DATE$COLRESET by $NAME $MAIL"
    fi
done


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
git --no-pager log --all -n1 --format="${COLGITHASH}%h ${COLGITDATE}%ci${COLGITRESET}%d ${COLGITSUBJECT}%s${COLGITRESET}" 


