#!/bin/bash

## Auxiliary script to analyze a file

FILEPATH="$*"
ERRCODE=""
EXITCODE=0

## Definition of the exit function
exit_line () {
	echo -e "$ERRCODE\t$MD5SUM\t$NBLINES\t$STATRSLT"
	exit $EXITCODE
}

### Extraction of 'ls' command information
STATRSLT=$(stat --printf "%i\t%b\t%s\t%A\t%u\t%U\t%g\t%G\t%x\t%y\t%z\t%n" "$FILEPATH" 2>/dev/null)

if [ "$?" != "0" ]
then
	ERRCODE=ERR1
	EXITCODE=1
	exit_line
fi

TYPE=$(echo "$STATRSLT" | awk -F' ' '{print $4}' | cut -c1)
### Extracting file information in the case of a file
if [[ "$TYPE" == "-" ]]
then
	## Counting the lines
	BUFFER="$(wc -l "$FILEPATH" 2>/dev/null)"
	if [ "$?" != "0" ]
	then
		ERRCODE=ERR2
		EXITCODE=2
		exit_line
	fi
	NBLINES="$(echo "$BUFFER" | awk -F' ' '{print $1}')"

	## Calculating the checksum
	BUFFER="$(md5sum "$FILEPATH" 2>/dev/null)"
	if [ "$?" != "0" ]
	then
		ERRCODE=ERR3
		EXITCODE=3
		exit_line
	fi
	MD5SUM="$(echo "$BUFFER" | awk -F' ' '{print $1}')"
fi

exit_line
