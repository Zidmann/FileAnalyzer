#!/bin/bash

##################################################################################
## AUTHOR : Emmanuel ZIDEL-CAUFFET - Zidmann (emmanuel.zidel@gmail.com)
##################################################################################
## 2020/05/09 - First release of the script
##################################################################################


##################################################################################
# Beginning of the script - definition of the variables
##################################################################################
SCRIPT_VERSION="0.0.1"

# Return code
RETURN_CODE=0

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
mkdir -p "$(dirname "$TMP_PATH")"

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

##################################################################################
echo "------------------------------------------------------" | tee -a "$LOG_PATH"
if [ ! -f "$TARGET_REPORT" ]
then
	echo "[-] The target report does not exist" | tee -a "$LOG_PATH"
else
	echo "[i] RULE-01 - Keeping the line with 15 delimiters" | tee -a "$LOG_PATH"
	awk -F';' 'BEGIN{FS=OFS=";"}{if(NF-1==15){VALID=1}else{VALID=0} print VALID, $0}' "$TARGET_REPORT" 1>"$TMP_PATH" 2>"$LOG_PATH"

	echo "[i] Copying valid lines in original file" | tee -a "$LOG_PATH"
	grep "^1;" "$TMP_PATH"    | cut -c3- 1>"$TARGET_REPORT"  2>"$LOG_PATH"

	NB_LINES=$(grep -v "^1;" "$TMP_PATH" 2>/dev/null | wc -l)
	if [ "$NB_LINES" != "0" ]
	then
		echo "[i] Copying bad lines in anormal file" | tee -a "$LOG_PATH"
		grep -v "^1;" "$TMP_PATH" | cut -c3- 1>"$BADLINE_REPORT" 2>"$LOG_PATH"
	else
		echo "[i] No bad lines to copy in anormal file" | tee -a "$LOG_PATH"
	fi
fi

##################################################################################
# Elapsed time - end date and length
END_DATE=$(date +%s)
ELAPSED_TIME=$(( $END_DATE - $BEGIN_DATE ))

##################################################################################
# End of the script
##################################################################################
echo "------------------------------------------------------" | tee -a "$LOG_PATH"
echo "[i] Removing the temporary file $TMP_PATH"              | tee -a "$LOG_PATH"
rm "$TMP_PATH" 2>/dev/null                                    | tee -a "$LOG_PATH"

echo "------------------------------------------------------" | tee -a "$LOG_PATH"
echo "Elapsed time : $ELAPSED_TIME sec"                       | tee -a "$LOG_PATH"
echo "Ending time  : $(date)"                                 | tee -a "$LOG_PATH"
echo "------------------------------------------------------" | tee -a "$LOG_PATH"
echo "Exit code = $RETURN_CODE"                               | tee -a "$LOG_PATH"

echo "------------------------------------------------------" | tee -a "$LOG_PATH"
exit "$RETURN_CODE"
##################################################################################

