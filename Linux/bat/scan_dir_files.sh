#!/bin/bash

##################################################################################
## AUTHOR : Emmanuel ZIDEL-CAUFFET - Zidmann (emmanuel.zidel@gmail.com)
##################################################################################
## 2019/08/12 - First release of the script
##################################################################################
## 2020/05/08 - Removing useless ';' at the end of each line
##            - Adding the elapse time printing
##################################################################################
## 2020/11/11 - Changes applied in the columns and delimiter,
##               using 'stat' results instead of 'ls' program
##               and splitting the sort step in several command to check errors
##################################################################################
## 2020/11/11 - Including the signal trap management
##################################################################################


##################################################################################
# Beginning of the script - definition of the variables
##################################################################################
SCRIPT_VERSION="0.0.8"

# Return code
RETURN_CODE=0

# Flag to execute the exit function
EXECUTE_EXIT_FUNCTION=0

# Trap management
function exit_function_auxi(){
	echo "------------------------------------------------------"
	if [ -f "$TMP_PATH" ]
	then
		echo "[i] Removing the temporary file $TMP_PATH"
		rm "$TMP_PATH" 2>/dev/null
	fi
	if [ -f "$TMP2_PATH" ]
	then
		echo "[i] Removing the temporary file $TMP2_PATH"
		rm "$TMP2_PATH" 2>/dev/null
	fi

	# Elapsed time - end date and length
	if [ "$BEGIN_DATE" != "" ]
	then 
		END_DATE=$(date +%s)
		ELAPSED_TIME=$((END_DATE - BEGIN_DATE))

		echo "------------------------------------------------------"
		echo "Elapsed time : $ELAPSED_TIME sec"
		echo "Ending time  : $(date)"
	fi
	echo "------------------------------------------------------"
	echo "Exit code = $RETURN_CODE"
	echo "------------------------------------------------------"
}
function exit_function(){
	if [ "$EXECUTE_EXIT_FUNCTION" != "0" ]
	then
		if [ -f "$LOG_PATH" ]
		then
			exit_function_auxi | tee -a "$LOG_PATH"
		else
			exit_function_auxi
		fi
	fi
}
function interrupt_script_auxi(){
	echo "------------------------------------------------------"
	echo "[-] A signal $1 was trapped"
}
function interrupt_script(){
	if [ -f "$LOG_PATH" ]
	then
		interrupt_script_auxi "$1" | tee -a "$LOG_PATH"
	else
		interrupt_script_auxi "$1"
	fi
}

trap exit_function              EXIT
trap "interrupt_script SIGINT"  SIGINT
trap "interrupt_script SIGQUIT" SIGQUIT
trap "interrupt_script SIGTERM" SIGTERM

# Analysis of the path and the names
DIRNAME="$(dirname "$(dirname "$(readlink -f "$0")")")"
CONF_DIR="$DIRNAME/conf"

PREFIX_NAME="$(basename "$(readlink -f "$0")")"
NBDELIMITER=$(echo "$PREFIX_NAME" | awk -F"." '{print NF-1}')

if [ "$NBDELIMITER" != "0" ]
then
	PREFIX_NAME=$(echo "$PREFIX_NAME" | awk 'BEGIN{FS="."; OFS="."; ORS="\n"} NF{NF-=1};1')
fi

if [ -f "$CONF_DIR/$PREFIX_NAME.env" ]
then
	CONF_PATH="$CONF_DIR/$PREFIX_NAME.env"	
elif [ -f "$CONF_DIR/scan_dir_files.env" ]
then
	PREFIX_NAME="scan_dir_files"
	CONF_PATH="$CONF_DIR/$PREFIX_NAME.env"
else
	echo "[-] Impossible to find a valid configuration file"
	exit "$RETURN_CODE"
fi

TARGET_DIR="$1"
if [ "$TARGET_DIR" == "" ]
then
	echo "Usage : $0 <DIRECTORY> [REPORT] [LOGFILE]"
	exit "$RETURN_CODE"
fi

# Loading configuration file
source "$CONF_PATH"
REPORT_DIR="$DIRNAME/report"
LOG_DIR="$DIRNAME/log"
TMP_DIR="$DIRNAME/tmp"
UTIL_DIR="$DIRNAME/util"

# Report file path
REPORT_PATH=${2:-"${REPORT_DIR}/$PREFIX_NAME.$(hostname).$TODAYDATE.$TODAYTIME.csv"}
mkdir -p "$(dirname "$REPORT_PATH")"

# Log file path
LOG_PATH=${3:-"${LOG_DIR}/$PREFIX_NAME.$(hostname).$TODAYDATE.$TODAYTIME.log"}
mkdir -p "$(dirname "$LOG_PATH")"

# Temporary file path
TMP_PATH="$TMP_DIR/$PREFIX_NAME.1.$$.tmp"
TMP2_PATH="$TMP_DIR/$PREFIX_NAME.2.$$.tmp"
mkdir -p "$(dirname "$TMP_PATH")"
mkdir -p "$(dirname "$TMP2_PATH")"

HEADER="STATUSCODE\tMD5SUM\tNBLINES\tINODE\tNBBLOCKS\tSIZE\tPERMISSION\tOWNERID\tOWNER\tGROUPID\tGROUP\tLASTACCESS\tLASTMODIFICATION\tLASTSTATUSCHANGE\tFILEPATH"
# Elapsed time - begin date
BEGIN_DATE=$(date +%s)

EXECUTE_EXIT_FUNCTION=1

function main_code(){
	##################################################################################
	# First console actions - Printing the header and the variables
	##################################################################################
	echo ""
	echo "======================================================"
	echo "======================================================"
	echo "= SCRIPT TO ANALYZE FILES IN A DIRECTORY             ="
	echo "======================================================"
	echo "======================================================"

	echo "Starting time : $(date)"
	echo "Version : $SCRIPT_VERSION"
	echo ""
	echo "TARGET_DIR=$TARGET_DIR"
	echo "LOG_PATH=$LOG_PATH"
	echo "REPORT_PATH=$REPORT_PATH"
	echo "TMP_PATH=$TMP_PATH"
	echo "TMP2_PATH=$TMP2_PATH"

	##################################################################################
	# Next console actions - Starting the analyzing
	##################################################################################
	rm -f "$REPORT_PATH" 2>/dev/null
	echo -e "$HEADER" > "$REPORT_PATH"

	##################################################################################
	echo "------------------------------------------------------"
	echo "[i] Analyze of the files"

	find "$TARGET_DIR" -exec "$UTIL_DIR/analyze_file.sh" {} \; 1>"$TMP_PATH" 2>"$TMP2_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
	cat "$TMP2_PATH"

	##################################################################################
	echo "------------------------------------------------------"
	echo "[i] Sort of the information"
	sort "$TMP_PATH"  1>"$TMP2_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

	uniq "$TMP2_PATH" 1>"$TMP_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

	awk 'BEGIN {FS=OFS="\t"; ORS="\n"}{print $0}' "$TMP_PATH" 1>>"$REPORT_PATH" 
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

	exit "$RETURN_CODE"
}
main_code > >(tee "$LOG_PATH") 2>&1
RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

##################################################################################
exit "$RETURN_CODE"
