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
#        AUTHOR:   (), 
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
    echo "ERROR: no .git directory found in path '$PARAM_WD'"
    exit
fi

echo "using Git base dir '$DIR'"

# try to derive the age (date of init or clone) from .git files
# (use oldest file in .git directory)
echo -n "init'ed or clone'd most probably on: "
stat -c '%Y %y %n' $DIR/.git/* | sort | head -n1 | awk '{print $2 " " $3  " (" $5 ")" }'

# remote links
echo -n "Remote links: "
git remote -v | cut  -f2 | cut -d' ' -f1 | sort | uniq

# git-svn
echo -n "Git-SVN info: "
git svn info


