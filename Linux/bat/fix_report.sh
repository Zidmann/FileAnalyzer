#!/bin/bash

##################################################################################
## AUTHOR : Emmanuel ZIDEL-CAUFFET - Zidmann (emmanuel.zidel@gmail.com)
##################################################################################
## 2020/05/09 - First release of the script
##################################################################################
## 2020/11/11 - Changing the filename column to check
##              Refactoring of the analysis
##              Correcting the glitch with grep when no result is found
##################################################################################
## 2020/11/11 - Including the signal trap management
##################################################################################


##################################################################################
# Beginning of the script - definition of the variables
##################################################################################
SCRIPT_VERSION="0.0.6"

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
	if [ -f "$TMP3_PATH" ]
	then
		echo "[i] Removing the temporary file $TMP3_PATH"
		rm "$TMP3_PATH" 2>/dev/null
	fi
	if [ -f "$TMP4_PATH" ]
	then
		echo "[i] Removing the temporary file $TMP4_PATH"
		rm "$TMP4_PATH" 2>/dev/null
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
elif [ -f "$CONF_DIR/fix_report.env" ]
then
	PREFIX_NAME="fix_report"
	CONF_PATH="$CONF_DIR/$PREFIX_NAME.env"
else
	echo "[-] Impossible to find a valid configuration file"
	exit "$RETURN_CODE"
fi

TARGET_REPORT="$1"
if [ "$TARGET_REPORT" == "" ]
then
	echo "Usage : $0 <REPORT> [LOGFILE]"
	exit "$RETURN_CODE"
fi

# Bad line file
TARGET_REPORT_DIR="$(dirname "$TARGET_REPORT")"
TARGET_REPORT_BASENAME="$(basename "$TARGET_REPORT")"
HAS_EXTENSION=$(echo "$TARGET_REPORT_BASENAME" | awk 'BEGIN{FS="."}{if(NF-1==0){EXTENSION=0}else{EXTENSION=1} print EXTENSION}')
if [ "$HAS_EXTENSION" == "1" ]
then
	BADLINE_BASENAME=$(echo "$TARGET_REPORT_BASENAME" | awk 'BEGIN{FS=OFS="."}{$NF="bad."$NF; print $0}')
else
	BADLINE_BASENAME="$TARGET_REPORT_BASENAME.bad"
fi
BADLINE_REPORT="$TARGET_REPORT_DIR"/"$BADLINE_BASENAME"

# Loading configuration file
source "$CONF_PATH"
LOG_DIR="$DIRNAME/log"
TMP_DIR="$DIRNAME/tmp"

# Log file path
LOG_PATH=${2:-"${LOG_DIR}/$PREFIX_NAME.$(hostname).$TODAYDATE.$TODAYTIME.log"}
mkdir -p "$(dirname "$LOG_PATH")"

# Temporary file path
TMP_PATH="$TMP_DIR/$PREFIX_NAME.1.$$.tmp"
TMP2_PATH="$TMP_DIR/$PREFIX_NAME.2.$$.tmp"
TMP3_PATH="$TMP_DIR/$PREFIX_NAME.3.$$.tmp"
TMP4_PATH="$TMP_DIR/$PREFIX_NAME.4.$$.tmp"
mkdir -p "$(dirname "$TMP_PATH")"
mkdir -p "$(dirname "$TMP2_PATH")"
mkdir -p "$(dirname "$TMP3_PATH")"
mkdir -p "$(dirname "$TMP4_PATH")"

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
	echo "= SCRIPT TO FIX A REPORT                             ="
	echo "======================================================"
	echo "======================================================"

	echo "Starting time : $(date)"
	echo "Version : $SCRIPT_VERSION"
	echo ""
	echo "TARGET_REPORT=$TARGET_REPORT"
	echo "BADLINE_REPORT=$BADLINE_REPORT"
	echo "LOG_PATH=$LOG_PATH"
	echo "TMP_PATH=$TMP_PATH"
	echo "TMP2_PATH=$TMP2_PATH"
	echo "TMP3_PATH=$TMP3_PATH"
	echo "TMP4_PATH=$TMP4_PATH"

	##################################################################################
	echo "------------------------------------------------------"
	if [ ! -f "$TARGET_REPORT" ]
	then
		echo "[-] The target report does not exist"
	else
		echo "[i] RULE-01 - Keeping the line with 14 delimiters"
		awk 'BEGIN{FS=OFS="\t"; ORS="\n"; first_line=1}{if(NF==(14+1)){if(first_line==1){first_line=0;STATUS=1}else{STATUS=0}}else{STATUS=2} print STATUS, $0}' "$TARGET_REPORT" 1>"$TMP_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

		echo "[i] RULE-02 - Removing the line with unknown status column"
		awk 'BEGIN{FS=OFS="\t"; ORS="\n"}{if($1==0){if($2!="OK" && $2!="ERR1" && $2!="ERR2" && $2!="ERR3"){$1=3}};print $0}' "$TMP_PATH" 1>"$TMP2_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
	 
		# RULES-02 is here to avoid any odd letters (like  or ┼)
		# Most of the time they come from some data corruption and could jam the Qlik script during the file loading
		echo "[i] RULE-03 - Keeping line with valid letters"
		VALID_LETTERS=$(cat "$CONF_DIR/letters_valid.conf" |tr -d '\n');

		awk -v VALID_LETTERS="$VALID_LETTERS" 'BEGIN{FS=OFS="\t";ORS="\n";for(i=1;i<=length(VALID_LETTERS);i++){hashmap_validletters[substr(VALID_LETTERS,i,1)]=1}}{for(i=1;i<=length($NF);i++){if(hashmap_validletters[substr($NF,i,1)]!=1){$1=4;break;}}print $0;}' "$TMP2_PATH" 1>"$TMP3_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

		echo "[i] Copying valid lines in original file"
		awk 'BEGIN{FS=OFS="\t";ORS="\n";}{if($1==0 || $1==1){print $0}}' "$TMP3_PATH" 1>"$TMP4_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
		cut -c3-  "$TMP4_PATH" 1>"$TARGET_REPORT"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

		echo "[i] Copying bad lines in anormal file"
		awk 'BEGIN{FS=OFS="\t";ORS="\n";}{if($1!=0 && $1!=1){print $0}}' "$TMP3_PATH" 1>"$TMP4_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
		cut -c3-  "$TMP4_PATH" 1>"$TMP3_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
		if [ -s "$TMP3_PATH" ]
		then
			cat "$TMP3_PATH" 1>"$BADLINE_REPORT"
			RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
		else
			echo " - No bad lines to copy in anormal file"
		fi
	fi
}

main_code 2>&1 | tee -a "$LOG_PATH"

##################################################################################
exit "$RETURN_CODE"

