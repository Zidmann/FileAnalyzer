#!/bin/bash

## Auxiliary script to analyze a file

FILEPATH="$*"
ERRCODE=""

## Definition of the exit function
exit_line () {
	echo "$FILEPATH;$ERRCODE;$INODE;$TYPE;$PERM;$OWNER;$OWNERID;$GROUP;$GROUPID;$DAY;$TIME;$DEPTH;$SIZE;$NBLINES;$MD5SUM;"
	exit 0
}

### Extraction of 'ls' command information
LSRSLT=$(ls -rtldti --full-time --time-style="+%Y%m%d %H%M%S" "$FILEPATH" 2>/dev/null)
if [ "$?" != "0" ]
then
	ERRCODE=ERR1
	exit_line
fi

INODE=$(echo "$LSRSLT" | awk -F' ' '{print $1}')
TYPE=$(echo  "$LSRSLT" | awk -F' ' '{print $2}' | cut -c1)
PERM=$(echo  "$LSRSLT" | awk -F' ' '{print $2}' | cut -c2-)
OWNER=$(echo "$LSRSLT" | awk -F' ' '{print $4}')
GROUP=$(echo "$LSRSLT" | awk -F' ' '{print $5}')
DAY=$(echo   "$LSRSLT" | awk -F' ' '{print $7}')
TIME=$(echo  "$LSRSLT" | awk -F' ' '{print $8}')

### Extraction of 'stat' command information
STATRSLT=$(stat -c "%u %g"  "$FILEPATH" 2>/dev/null)
if [ "$?" != "0" ]
then
	ERRCODE=ERR2
	exit_line
fi

OWNERID=$(echo "$STATRSLT" | awk -F' ' '{print $1}')
GROUPID=$(echo "$STATRSLT" | awk -F' ' '{print $2}')

### Calculating the depth of the file according the directory
DEPTH=0
PARENTPATH="$FILEPATH"
DIRNAME="$(dirname "$FILEPATH" 2>/dev/null)"

while [ "$DIRNAME" != "$PARENTPATH" ]
do
	PARENTPATH="$DIRNAME"
	DIRNAME="$(dirname "$PARENTPATH" 2>/dev/null)"
	if [ "$?" != "0" ]
	then
		ERRCODE=ERR3
		exit_line
	fi
	DEPTH=$((DEPTH + 1))
done

### Extracting file information
if [ "$TYPE" == "-" ]
then
	TYPE="f"

	## Calculating size in Ko
	BUFFER="$(du -s "$FILEPATH" 2>/dev/null)"
	if [ "$?" != "0" ]
	then
		ERRCODE=ERR4
		exit_line
	fi
	SIZE="$(echo "$BUFFER" | awk -F' ' '{print $1}')"

	## Counting the lines
	BUFFER="$(wc -l "$FILEPATH" 2>/dev/null)"
	if [ "$?" != "0" ]
	then
		ERRCODE=ERR5
		exit_line
	fi
	NBLINES="$(echo "$BUFFER" | awk -F' ' '{print $1}')"

	## Calculating the checksum
	BUFFER="$(md5sum "$FILEPATH" 2>/dev/null)"
	if [ "$?" != "0" ]
	then
		ERRCODE=ERR6
		exit_line
	fi
	MD5SUM="$(echo "$BUFFER" | awk -F' ' '{print $1}')"
fi

exit_line
