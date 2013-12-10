Scripts
=======

Shell scripts (mostly bash) I keep in my $PATH


backup.sh
---------
This is a simple backup script to copy the home directory to a USB disk.
It is closely tied to my home setup and handles some directories differently.
This script uses `xmodmap-esc` which maps CAPSLOCK to ESC (for vim).

bash_profile
------------
This is my Bash configuration. The original file `~/.bash_profile` sources
this one.


bibgrep and texgrep
-------------------

Grep on keys in a BibLaTeX database and in TEX files.
`bibgrep` puts the last key in the X11 clipboard (xsel -b)
and `texgrep` uses the clipboard as search term if no parameter 
was provided on the command line.


crypt.sh
--------
Handle cryto containers (create, mount, unmount)


open
----
This started as a mimic of the MacOS open command because some colleages used
it in Makefiles.


ps.sh
-----
call ps with some parameters


pymail
------
Python script to replace `mail` when no local MTA is running.
It uses an open SMTP server in the local network.


sqlplot.sh
----------
Data series analysis tool based on SQLite and Gnuplot.
See http://www.wassen.net/sql-plot.html

