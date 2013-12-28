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

# find .git

if [[ -d .git ]]; then
    DIR=.
else
    while [[ $PWD != / ]]; do
        cd ..
        if [[ -d .git ]]; then
            DIR=$PWD
            break
        fi
    done
    echo "ERROR: no .git directory found in path"
    exit
fi

echo "using Git base dir '$DIR'"

# try to derive the age (date of init or clone) from .git files
# (use oldest file in .git directory)
echo -n "init'ed or clone'd most probably on: "
stat -c '%Y %y %n' $DIR/.git/* | sort | head -n1 | awk '{print $2 ($3)}'

# remote links
echo -n "Remote links: "
git remote -v | cut  -f2 | cut -d' ' -f1 | sort | uniq

# git-svn
echo -n "Git-SVN info: "
git svn info


