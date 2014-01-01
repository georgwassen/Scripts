#!/bin/bash
#===============================================================================
#
#          FILE:  checkoutanalyzer.sh
# 
#         USAGE:  ./checkoutanalyzer.sh 
# 
#   DESCRIPTION:  analyze all checked-out repositories
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Georg Wassen (georg.wassen@googlemail.com), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  01.01.2014 18:22:08 CET
#      REVISION:  ---
#===============================================================================

DIR=~/checkout

cd $DIR
for D in *; do
    if [[ -d $D ]]; then
        pushd $D > /dev/null

        if [[ -d .git ]]; then
            # Git

            STR="Git"
        elif [[ -d .svn ]]; then
            # Subversion 


            STR="Subversion"
        else
            # unknown
            STR="unknown format"
        fi

        printf "%-20s : %s\n" "$D" "$STR"


        popd > /dev/null
    fi
done
