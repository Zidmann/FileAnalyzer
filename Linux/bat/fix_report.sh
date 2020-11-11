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
SCRIPT_VERSION="0.0.4"

# Return code
RETURN_CODE=0

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

	# Elapsed time - end date and length
	if [ "$BEGIN_DATE" == "" ]
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
	if [ -f "$LOG_PATH" ]
	then
		exit_function_auxi | tee -a "$LOG_PATH"
	else
		exit_function_auxi
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
if [ "$(dirname "$0")" == "." ]
then
	DIRNAME=".."
else
	DIRNAME="$(dirname "$(dirname "$0")")"
fi
CONF_DIR="$DIRNAME/conf"

PREFIX_NAME="$(basename "$0")"
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

# Temporaryfile path
TMP_PATH="$TMP_DIR/$PREFIX_NAME.1.$$.tmp"
TMP2_PATH="$TMP_DIR/$PREFIX_NAME.2.$$.tmp"
TMP3_PATH="$TMP_DIR/$PREFIX_NAME.3.$$.tmp"
mkdir -p "$(dirname "$TMP_PATH")"
mkdir -p "$(dirname "$TMP2_PATH")"

# Elapsed time - begin date
BEGIN_DATE=$(date +%s)

##################################################################################
# First console actions - Printing the header and the variables
##################################################################################
echo "" | tee -a "$LOG_PATH"
echo "======================================================" | tee -a "$LOG_PATH"
echo "======================================================" | tee -a "$LOG_PATH"
echo "= SCRIPT TO FIX A REPORT                             =" | tee -a "$LOG_PATH"
echo "======================================================" | tee -a "$LOG_PATH"
echo "======================================================" | tee -a "$LOG_PATH"

echo "Starting time : $(date)"        | tee -a "$LOG_PATH"
echo "Version : $SCRIPT_VERSION"      | tee -a "$LOG_PATH"
echo ""                               | tee -a "$LOG_PATH"
echo "TARGET_REPORT=$TARGET_REPORT"   | tee -a "$LOG_PATH"
echo "BADLINE_REPORT=$BADLINE_REPORT" | tee -a "$LOG_PATH"
echo "LOG_PATH=$LOG_PATH"             | tee -a "$LOG_PATH"
echo "TMP_PATH=$TMP_PATH"             | tee -a "$LOG_PATH"
echo "TMP2_PATH=$TMP2_PATH"           | tee -a "$LOG_PATH"
echo "TMP3_PATH=$TMP3_PATH"           | tee -a "$LOG_PATH"

##################################################################################
echo "------------------------------------------------------" | tee -a "$LOG_PATH"
if [ ! -f "$TARGET_REPORT" ]
then
	echo "[-] The target report does not exist" | tee -a "$LOG_PATH"
else
	echo "[i] RULE-01 - Keeping the line with 14 delimiters" | tee -a "$LOG_PATH"
	awk 'BEGIN{FS=OFS="\t"; ORS="\n"}{if(NF-1==14){STATUS=0}else{STATUS=1} print STATUS, $0}' "$TARGET_REPORT" 1>"$TMP_PATH" 2>>"$LOG_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

	# RULES-02 is here to avoid any odd letters (like  or ┼)
	# Most of the time they come from some data corruption and could jam the Qlik script during the file loading
	echo "[i] RULE-02 - Keeping line with valid letters" | tee -a "$LOG_PATH"
	VALID_LETTERS=$(cat "$CONF_DIR/letters_valid.conf" |tr -d '\n');

	awk -v VALID_LETTERS="$VALID_LETTERS" 'BEGIN{FS=OFS="\t";ORS="\n"}{if($1==0){STATUS=0;for(i=1;i<=length($NF);i++){STATUS=2;for(j=1;j<=length(VALID_LETTERS);j++){if(substr($NF,i,1)==substr(VALID_LETTERS,j,1)){STATUS=0;break;}}if(STATUS==2){break;}} $1=STATUS;} print $0;}' "$TMP_PATH" 1>"$TMP2_PATH" 2>>"$LOG_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

	echo "[i] Copying valid lines in original file" | tee -a "$LOG_PATH"
	grep "^0" "$TMP2_PATH" 1>"$TMP3_PATH" 2>>"$LOG_PATH"
	AUXI_CODE=$?
	if [ -s "$TMP3_PATH" ]
	then
		RETURN_CODE=$([ $AUXI_CODE == 0 ] && echo "$RETURN_CODE" || echo "1")		
	fi

	cut -c3-  "$TMP3_PATH" 1>"$TARGET_REPORT" 2>>"$LOG_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")

	echo "[i] Copying bad lines in anormal file" | tee -a "$LOG_PATH"
	grep -v "^0" "$TMP2_PATH" 1>"$TMP3_PATH" 2>>"$LOG_PATH"
	AUXI_CODE=$?
	if [ -s "$TMP3_PATH" ]
	then
		RETURN_CODE=$([ $AUXI_CODE == 0 ] && echo "$RETURN_CODE" || echo "1")		
	fi
	cut -c3-  "$TMP3_PATH" 1>"$TMP2_PATH" 2>>"$LOG_PATH"
	RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
	if [ -s "$TMP2_PATH" ]
	then
		cat "$TMP2_PATH" 1>"$BADLINE_REPORT" 2>>"$LOG_PATH"
		RETURN_CODE=$([ $? == 0 ] && echo "$RETURN_CODE" || echo "1")
	else
		echo " - No bad lines to copy in anormal file" | tee -a "$LOG_PATH"
	fi
fi

##################################################################################
exit "$RETURN_CODE"

