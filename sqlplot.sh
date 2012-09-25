#!/bin/bash

########################################################################
#
# sqlplot
#
# you need sqlite (http://www.sqlite.org/, Public Domain)
# and gnuplot (http://www.gnuplot.info, Freeware)
# 
# Adjust SQL and PLOT to point to the binaries
# Add "-persist" to gnuplot, when working on UNIX with x11
# to keep plots open. On Windows, use pgnuplot.exe and set
# WIN=1
#
# Put your data into a SQLite Database and start this script.
# Type 'help' to get a list of commands.
# Write a SELECT statement to get the data you want to see.
# The last two columns are used as x- resp. y values, all other columns
# are used to distinct data series.
# Write 'plot' to display the last query, write 'plot file.png' to
# write the plot to a file.
#
# copyright 2007 Georg Wassen   georg (at) wassen (dot) net
# This script is released unter the Terms of the GNU GPL, version 2
# 
########################################################################

# TODO:
#  * log2tics (still experimental, either just document or improve...)
#     (best solution would be to auto detect the range...)
#     (see tics(): better but not foolprof...)


VERSION="0.8 (LfBS branch) 13.7.2007"

# global settings (to sqlite3- and gnuplot executables) ################
SQL="sqlite3"

# Unix: use -persist
# Windows: use pgnuplot.exe and set WIN=1 (for some workarounds)
PLOT="gnuplot -persist"
WIN=0
#PLOT='./gnuplot42/bin/pgnuplot.exe'
#WIN=1

# NFS workaround
# if you get errors from sqlite that the database file could not be locked
# set this to 1 and the database file will be copied to /tmp on startup
NFS_WORKAROUND=1


# script start and parameter evaluation ################################
function usage() {
	echo "Usage $0 database [scriptfile]"
	echo "start program and type help to get list of commands"
	echo "if scriptfile given, execute and then terminate"
	exit 1
}

if [ $# == 0 ]; then
    usage
else
    FILE=$1
    if [ $NFS_WORKAROUND -eq 1 ]; then
	TMPDB=`mktemp`
	cp $FILE $TMPDB
	FILE=$TMPDB
    fi
    if [ "$2" ]; then
    	# 2nd parameter: use as STDIN
    	exec < $2
    fi
fi

TMPFILE=`mktemp`
DATFILE=`mktemp`
GPFILE=sqlplot.gp
HISTFILE='sqlplot.hist'
SETFILE='sqlplot.settings'
#`mktemp`


# execution funtions ###################################################

function help() {
    case $PARAMS in
	'desc')
	    echo 'desc - print list of all available tables'
	    echo 'desc xxx - print definition of table xxx'
	    ;;
	'select')
	    echo 'Arbitrary SQL select command.'
	    echo 'The query must be on a single line.'
	    echo 'The result is printed as list.'
	    echo 'For plotting, the last 2 (3 on 3D plots) columns are used'
	    echo 'for x, y(, z) values. All previous columns form together'
	    echo 'the groups for data series.'
	    echo 'A simple "select" just reexecutes the last query'
	    ;;
	'set')
	    echo 'set xxx - set gnuplot option'
	    echo '          the settings are stored internally and applied to every plot.'
	    echo '          (please refer to gnuplot documentation for possible settings)'
	    echo '          some important examples:'
	    echo "            set title 'Hello World'"
	    echo "            set xlabel 'x axis'"
	    echo "            set xrange [0:*]"
	    echo "            set style data lines/points/linespoints/..."
	    echo "            set key left/right/top/bottom/..."
	    echo "          the following is recommanded for hist:"
	    echo "            set style fill solid 1.00 boder -1"
	    echo "            set style histogram clustered gap 1 title offset character 0,0,0"
	    echo "          the following is recommanded for splot:"
	    echo "            set ticslevel 0"
	    echo "            set hidden3d"
	    ;;
	'unset')
	    echo 'unset xxx - remove setting from internal storage'
	    echo '            the settings are stored internally and applied to every plot.'
	    echo '            to remove a previously set option, use this command.'
	    echo '            example:'
	    echo "              unset title"
	    ;;
	'plot')
	    echo 'plot - plot last SQL query and display on screen'
	    echo 'plot xxx.png - create png file'
	    echo 'plot xxx.jpeg- create jpeg file'
	    echo 'plot xxx.svg - create svg file'
	    echo 'plot xxx.ps  - create postscript file'
	    echo 'plot xxx.sp  - dont plot, but create sqlplot script to regenerate a plot'
	    echo '  The last select command is used to get the data.'
	    echo '  The two rightmost columns are used for x and y values.'
	    echo '  All previous columns are grouped to data series, their'
	    echo '  output is used as data series title for the key.'
	    ;;
	'splot')
	    echo 'splot - 3d-plot last SQL query and display on screen'
	    echo 'splot xxx.png - create png file'
	    echo 'splot xxx.jpeg- create jpeg file'
	    echo 'splot xxx.svg - create svg file'
	    echo 'splot xxx.ps  - create postscript file'
	    echo 'splot xxx.sp  - dont plot, but create sqlplot script to regenerate a plot'
	    echo '  The last select command is used to get the data.'
	    echo '  The three rightmost columns are used for x, y and z values.'
	    echo '  All previous columns are grouped to data series, their'
	    echo '  output is used as data series title for the key.'
	    ;;
	'hist')
	    echo 'hist - bar-plot last SQL query and display on screen'
	    echo 'hist xxx.png - create png file'
	    echo 'hist xxx.jpeg- create jpeg file'
	    echo 'hist xxx.svg - create svg file'
	    echo 'hist xxx.ps  - create postscript file'
	    echo 'hist xxx.sp  - dont plot, but create sqlplot script to regenerate a plot'
	    echo '  The last select command is used to get the data.'
	    echo '  The rightmost column is the height, the second column from the right is the'
	    echo '  title of the cluster. When this column output contains letters, it must be'
	    echo '  enclosed in double quotes.'
	    echo "    (to do so, use: select a, b, '\"'||c||'\"', d from ... )"
	    echo '  All previous columns are grouped to data series (bars of same colour), their'
	    echo '  output is used as data series title for the key.'
	    ;;

	'save')
	    echo 'save xxx - set save file name xxx and print every command to that file'
	    echo 'save - turn off saving'
	    echo '           The log file is created in the current directory.'
	    echo '           It can be used for later replay by redirecting it to STDIN'
	    echo '           manually cleaned.'
	    echo '           On Windows (Cygwin & pgnuplot), redirection of STDIN does NOT work!'
	    ;;
	'load')
	    echo 'load xxx - replay given script'
	    echo 'load - list *.sp scripts in working directory'
	    echo '           This command allows to replay scripts that were generated by'
	    echo '           "[s]plot xxx.sp" or "hist xxx.sp".'
	    echo '           These scripts can contain all sqlplot-commands and are interpreted'
	    echo '           like user input.'
	    echo '           By default, the scripts start with "reset", so this will usually'
	    echo '           overwrite your settings.'
	    ;;
	*)
	    echo "help [xxx] - help [topic xxx] "
	    echo "exit       - quit program"
	    echo "desc       - list of tables or table description"
	    echo "select ... - SQL select statement"
	    echo "set ...    - set gnuplot options"
	    echo "unset ...  - remove gnuplot setting"
	    echo "show       - show current gnuplot settings"
	    echo "reset      - remove all gnuplot settings"
	    echo "plot       - xy plot of last query"
	    echo "hist       - histogram (bar plot) of last query"
	    echo "splot      - 3d plot of last query"
	    echo "load       - load *.sp script"
	    ;;
    esac
	#echo "all SQL statements are given to the backend database"
	echo
}

function desc() {
	if [ -z "$PARAMS" ]; then
		$SQL $FILE .tables
	else
		$SQL $FILE ".schema $PARAMS" | sed 's/(/(\n\t/g' | sed 's/,/,\n\t/g'
	fi
	echo
}

function sql_select() {
	if [ -n "$PARAMS" ]; then
		LASTSELECT="$COMMAND $PARAMS"
	else
		echo "$LASTSELECT" 
	fi	
    $SQL -column -header $FILE "$LASTSELECT" |tee $TMPFILE
    echo
}

function do_set() {
	# MODE is set to one of (set,unset,reset,show)
	#echo "this is do_set with MODE=$MODE"
	
	SETTING=`echo $PARAMS | cut -d' ' -f1`
	if [ "$SETTING" == style ]; then
	    SETTING=`echo $PARAMS | cut -d' ' -f1,2`
		if [ "$SETTING" == "style line" ]; then
		    SETTING=`echo $PARAMS | cut -d' ' -f1,2,3`
	    fi
	fi
	case $MODE in
		'set')
			CURRENT_SET=`echo "$CURRENT_SET" | egrep -v "^set $SETTING"`
			CURRENT_SET=`printf "%s\n%s" "$CURRENT_SET" "set $PARAMS"`
			#CURRENT_SET="${CURRENT_SET}set $PARAMS\n"
			;;
		'unset')
			CURRENT_SET=`echo "$CURRENT_SET" | egrep -v "^set $SETTING"`
			;;
		'reset')
			CURRENT_SET=''
			;;
		'show')
			echo "$CURRENT_SET"
			echo
			;;
	esac
}

# TODO: this is experimental! 
# log2tics x 1 4 4096
# should set xtics to: 1 4 16 64 256 1k 4k
# nice, if this would work: log2tics x 4k 4 2G
function log2tics() {
    XY=`echo $PARAMS | cut -d' ' -f1`
    FROM=`echo $PARAMS | cut -d' ' -f2`
    FAKTOR=`echo $PARAMS | cut -d' ' -f3`
    TO=`echo $PARAMS | cut -d' ' -f4`
    if [ $XY == x ]; then
	PARAMS=xtics
    elif [ $XY == y ]; then
	PARAMS=ytics
    else
	echo "First parameter must be x or y"
	return
    fi

    
    FIRST=1
    for (( I=$FROM ; I <= $TO ; I\*=$FAKTOR )); do
	if [ $FIRST == 1 ]; then
	    PARAMS="$PARAMS ("
	    FIRST=0
	else
	    PARAMS="$PARAMS, "
	fi
	BIN=$I
	M=''
	if [ $BIN -ge 1024 ]; then BIN=`expr $BIN / 1024`; M=k; fi
	if [ $BIN -ge 1024 ]; then BIN=`expr $BIN / 1024`; M=M; fi
	if [ $BIN -ge 1024 ]; then BIN=`expr $BIN / 1024`; M=G; fi
	PARAMS="$PARAMS '$BIN$M' $I"
    done
    PARAMS="$PARAMS)"
    MODE=set do_set
}	

function tics() {
    FACTOR=`echo "$CURRENT_SET"|egrep '^set logscale'|awk '{print $4}' `
    if [ -n "$FACTOR" ]; then
	#echo "logscale $FACTOR detected"

	NUMCOL=`head -n2 $TMPFILE|tail -n1 |wc -w`
	#echo "number columns: $NUMCOL"
	$SQL -header -separator : -nullvalue 0 -list $FILE "$LASTSELECT" > $DATFILE
	if [ "$WIN" == 1 ]; then
	    dos2unix $DATFILE 2> /dev/null
	fi
	if [ $PARAMS = '3d' ]; then
	    TCOL=`expr $NUMCOL - 3`
	    XCOL=`expr $NUMCOL - 2`
	    YCOL=`expr $NUMCOL - 1`
	    ZCOL=$NUMCOL
	else
	    TCOL=`expr $NUMCOL - 2`
	    XCOL=`expr $NUMCOL - 1`
	    YCOL=$NUMCOL
	fi
	if [ -n "`echo "$CURRENT_SET"|egrep '^set logscale.*x'   `" ]; then
	    echo 'logscale x detected'
	    MIN=`tail -n+2 $DATFILE | cut -d: -f$XCOL | sort -n | head -n1`
	    MAX=`tail -n+2 $DATFILE | cut -d: -f$XCOL | sort -n | tail -n1`
	    PARAMS="x $MIN $FACTOR $MAX"
	    log2tics
	fi
	if [ -n "`echo "$CURRENT_SET"|egrep '^set logscale.*y'  `" ]; then
	    echo 'logscale y detected'
	    MIN=`tail -n+2 $DATFILE | cut -d: -f$YCOL | sort -n | head -n1`
	    MAX=`tail -n+2 $DATFILE | cut -d: -f$YCOL | sort -n | tail -n1`
	    PARAMS="y $MIN $FACTOR $MAX"
	    log2tics
	fi
    fi
}

function plot() {
    if [ ! -s $TMPFILE ]; then
	echo 'Please first execute a query that can be plotted.'
	echo
	return
    fi

    if [ "`echo $PARAMS | cut -d. -f2`" == sp ]; then
	# don't plot, but create script to generate this plot
	echo "# script autogenerated by sqlplot.sh" > $PARAMS
	echo "reset" >> $PARAMS
	echo "$CURRENT_SET" >> $PARAMS
	echo "$LASTSELECT" >> $PARAMS
	echo "$MODE" >> $PARAMS
	echo "script $PARAMS generated."
	echo
	return
    fi

    NUMCOL=`head -n2 $TMPFILE|tail -n1 |wc -w`
	#echo "number columns: $NUMCOL"
    $SQL -header -separator : -nullvalue 0 -list $FILE "$LASTSELECT" > $DATFILE
    if [ "$WIN" == 1 ]; then
	dos2unix $DATFILE 2> /dev/null
    fi
    if [ $MODE == splot ]; then
	TCOL=`expr $NUMCOL - 3`
	XCOL=`expr $NUMCOL - 2`
	YCOL=`expr $NUMCOL - 1`
	ZCOL=$NUMCOL
    else
	TCOL=`expr $NUMCOL - 2`
	XCOL=`expr $NUMCOL - 1`
	YCOL=$NUMCOL
    fi
    
    echo "# generated by sqlplot from $FILE" > $GPFILE
    echo "# Query: $LASTSELECT" >> $GPFILE
    
    if [ -z "`echo "$CURRENT_SET" | egrep '^set title '`" ]; then
	echo "set title \"$LASTSELECT\"" >> $GPFILE
    fi
    
    if [ -z "`echo "$CURRENT_SET" | egrep '^set xlabel '`" ]; then
	VALUE=`head -n1 $DATFILE | cut -d: -f $XCOL | tr -d "'" `
	echo "set xlabel '$VALUE'" >> $GPFILE
    fi
    if [ -z "`echo "$CURRENT_SET" | egrep '^set ylabel '`" ]; then
	VALUE=`head -n1 $DATFILE | cut -d: -f $YCOL | tr -d "'" `
	echo "set ylabel '$VALUE'" >> $GPFILE
    fi
    if [ $MODE == splot -a -z "`echo "$CURRENT_SET" | egrep '^set zlabel '`" ]; then
	VALUE=`head -n1 $DATFILE | cut -d: -f $ZCOL | tr -d "'" `
	echo "set zlabel '$VALUE'" >> $GPFILE
    fi

    echo "$CURRENT_SET" >> $GPFILE
    
    if [ -n "$PARAMS" ]; then
  	# export to file
  	LT=(1 2 3 4 5 6 7 8 9 10 11 12)
  	# see EOF for list of colors...
  	case `echo $PARAMS | cut -d. -f2` in
	    'png')
		TERMINAL='png enhanced'
		OUTPUT=$PARAMS
		;;
	    'jpeg')
		TERMINAL='jpeg enhanced'
		OUTPUT=$PARAMS
		;;
	    'ps')
		TERMINAL='postscript enhanced color'
		OUTPUT=$PARAMS
		;;
	    'eps')
		TERMINAL='postscript eps enhanced color solid' # dashed'
		OUTPUT=$PARAMS
		LT=(1 2 3 4 7 9 5 6 8 10 11 12 13 14 15 16)
		;;
	    'bweps')
		TERMINAL='postscript eps enhanced monochrome dashed'
		OUTPUT=`echo $PARAMS | sed 's/.bweps/.eps/g'`
		;;
	    'svg')
		TERMINAL='svg enhanced'
		OUTPUT=$PARAMS
		;;
	    'pslatex')
		TERMINAL='pslatex'
		OUTPUT=$PARAMS.ps
		;;
	    *)
		echo "Terminal for file $PARAMS not supported."
		echo
		return
		;;
  	esac
  	echo "set terminal $TERMINAL" >> $GPFILE
  	echo "set output '$OUTPUT'" >> $GPFILE
    fi
    
    if [ $MODE == hist ]; then
	WITH="with histogram"
    else
		if echo "$CURRENT_SET" | grep "set style data"; then
		    WITH=''
		else
		    WITH="with linespoints"
		fi
	fi
    if [ $MODE == splot ]; then
		PL_COMMAND=splot
		AWK='BEGIN{x=""} x!=$1 {print " "; x=$1} {print $0} '
    else
		PL_COMMAND=plot
		AWK='{print $0}'
    fi

    if [ $TCOL -gt 0 ]; then
		DATA_LIST=`tail -n+2 $DATFILE | cut -d: -f1-$TCOL | tr ' ' '§'  | uniq`
    else
		DATA_LIST='-'
    fi
    FIRST=0
    for DATA in $DATA_LIST; do
		if [ $FIRST == 0 ]; then
		    echo -n "$PL_COMMAND " >> $GPFILE
		else
		    echo -n ", " >> $GPFILE
		fi
		DATA=`echo "$DATA" | tr '§' ' ' `
		echo -n "'-' " >> $GPFILE
		if [ "$WITH" == "with histogram" ]; then
		    echo -n "using 2:xtic(1) " >> $GPFILE
		fi
		if [ $TCOL -gt 0 ]; then
		    echo -n " title '$DATA'" >> $GPFILE
		fi
		echo -n " $WITH" >> $GPFILE
		#echo -n " lt ${LT[$FIRST]} lw 2" >> $GPFILE
		FIRST=`expr $FIRST + 1`
    done
    echo >> $GPFILE
    ###OLDX=''
    for DATA in $DATA_LIST; do
	DATA=`echo "$DATA" | tr '§' ' ' `
	if [ "$DATA" == '-' ]; then
	    DATA='.*'
	else
	    DATA="^$DATA:"
	fi
	tail -n+2 $DATFILE | egrep "$DATA" | cut -d: -f$XCOL- | tr ':' '\t'| awk "$AWK" >> $GPFILE
	echo 'e' >> $GPFILE
    done
    
    if [ -z "$PARAMS" ]; then
		# display
	if [ "$WIN" == 1 ]; then
	    echo "pause -1" >> $GPFILE
    else
        echo 'pause -1 "Drücke ENTER zum Beenden des Plots."' >> $GPFILE
  	fi
#if [ $MODE == splot ]; then
#echo "pause -1" >> $GPFILE
#echo "show view" >> $GPFILE
#echo "hit ENTER to continue."
#fi
    fi


cat $GPFILE
    $PLOT $GPFILE
    if [ -n "$PARAMS" ]; then
  	# exported to file: notice user
  	echo "plot exported to $PARAMS"
  	echo
    fi

    rm $DATFILE
    
}

function do_exit() {
    rm $TMPFILE
    #rm $GPFILE
    if [ $NFS_WORKAROUND -eq 1 ]; then
	rm $TMPDB
    fi
    if [ -n "$SETFILE" ]; then
	echo "$LASTSELECT" > $SETFILE
	echo "$CURRENT_SET" >> $SETFILE
    fi
    #echo "exit on command."
    exit
}

# Main loop ########################################################

if [ -z "$SETFILE" -o ! -r $SETFILE ]; then
    LASTSELECT=''
    CURRENT_SET=''
else
    LASTSELECT=`head -n1 $SETFILE`
    CURRENT_SET=`tail -n+2 $SETFILE`
fi

echo "using sqlite version `$SQL -version`"
echo "using gnuplot version `$PLOT --version`"
echo
echo "Welcome to sqlplot $VERSION"
echo "Print help to get list of commands"
echo
while true; do
    history -r $HISTFILE
    
    if read -e -p "sqlplot> " COMMAND PARAMS ; then
	# input
	#history -s "$COMMAND $PARAMS"
        if [[ "$COMMAND" = select && "$PARAMS" = '' ]]; then
            # empty 'select' repeats last select; but put the complete select statement into HISTFILE
            #echo "(store lastselect '$LASTSELECT')"
            echo "$LASTSELECT" >> $HISTFILE
        else
            #echo "(store command params '$COMMAND $PARAMS')"
            echo "$COMMAND $PARAMS" >> $HISTFILE
        fi
    else
        # EOF
	if [ "$LOADING" != 1 ]; then
	    do_exit
	else
	    exec 0>&4
	    LOADING=0
	fi
    fi

    
    if [ "`echo $COMMAND|cut -c1`" == '#' ]; then
	continue
    fi

    #echo "command was: \"$COMMAND $PARAMS\""
    echo
    
    # TODO: is LOGFILE still used?
    if [ -n "$LOGFILE" ]; then
	echo $COMMAND $PARAMS >> $SAVEFILE
    fi
    
    COMMAND=`echo $COMMAND | tr '[A-Z]' '[a-z]'`
    
    case $COMMAND in
	'exit')
	    do_exit
	    ;;
	'help')
	    help
	    ;;
	'desc')
	    desc
	    ;;
	'select')
	    sql_select
	    ;;
	'plot')
	    MODE=plot plot
	    ;;
	'splot')
	    MODE=splot plot
	    ;;
	'hist')
	    MODE=hist plot
	    ;;
	'set')
	    MODE=set do_set
	    ;;
	'unset')
	    MODE=unset do_set
	    ;;
	'reset')
	    MODE=reset do_set
	    ;;
	'show')
	    MODE=show do_set
	    ;;
	'log2tics')
	    log2tics
	    ;;
	'tics')
	    tics
	    ;;

	'save')
	    SAVEFILE="$PARAMS"
	    ;;
	'load')
	    if [ -z "$PARAMS" ]; then
		ls *.sp
	    else
		LOADING=1
		exec 4>&0
		exec 0<>$PARAMS
	    fi
	    ;;
	'')
	    ;;
	*)
	    echo "command not known or not implemented. Type help for list of commands."
	    #echo "'$COMMAND' '$PARAMS'"
	    echo
	    ;;
    esac
done


# lt		x11			eps			svg
#--------------------------------------------
#  1		rot			rot			rot
#  2		grün		grün		grün
#  3		blau		blau		blau
#  4		violett		violett		türkis
#  5		türkis		türkis		dunkelgrün
#  6		braun		gelb		dunkelblau
#  7		orange		schwarz		orange
#  8		dunkelorang	orange		türkis 2
#  9		(rot)		grau		gelb
# 10		(grün)		(rot)		hell-violett
# 11					(grün)		dunkelgelb
# 12					(blau)		rosa
#
#



