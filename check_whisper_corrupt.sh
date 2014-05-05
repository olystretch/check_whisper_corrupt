#!/bin/bash -
#===============================================================================
#
#          FILE:  check_whisper_corrupt.sh
#
#         USAGE:  ./check_whisper_corrupt.sh
#
#   DESCRIPTION: Uses whisper-info to check the readability of whisper files
#
#
#  REQUIREMENTS: Needs to be able to read/write to the storage directory
#          BUGS: None Known.
#         NOTES: ---
#        AUTHOR: Kurt Abersold (KSA), kurtabersold@gmail.com
#       COMPANY: 
#       CREATED: 04/28/2014 10:46:00 AM PDT
#      REVISION: Alf
#       VERSION: 0.0.1
#===============================================================================
# set -o nounset      # Treat unset variables as an error
canonicalpath=`readlink -f $0`
canonicaldirname=`dirname ${canonicalpath}`/..
samedirname=`dirname ${canonicalpath}`

#===  FUNCTION  ================================================================
#          NAME:  usage
#   DESCRIPTION:  Show how to use this script with examples
#    PARAMETERS:  None. Echo to stdout
#       RETURNS:  The entire function result
#===============================================================================
usage() {
cat << EOF
Usage: $0 options

OPTIONS:
-h   Show this message
-x   enable debug mode
-d   Path of directory to check. Defaults to: /opt/graphite/storage/whisper
-m   Max depth of directory recursion. Defaults to unlimited
-n   Nagios monitor. Suppresses output intended for user, and uses Nagios exit statuses and messages (In Development)

Choose only ONE of the following file handling options:

-b   Create backups of files before deleting (CAREFUL!!! this can fill your disk FAST)
-r   Don't create backups, just remove the file
-c   Check and list files, don't delete (Default)

Example:
$0 -d /opt/graphite/storage/whisper/foo/bar -m 4

EOF
}

#===  GETOPTS  =================================================================
#          NAME:  getopts
#   DESCRIPTION:  Not a function.  Get the options from the command args
#    PARAMETERS:  as defined
#       RETURNS:  nothing by default.  Variable declaration
#===============================================================================
while getopts "xhd:m:brcn" OPTION
do
  case ${OPTION} in
    h) usage; exit 0		;;
    x) set -x			;;
    d) DIRECTORY="${OPTARG}"    ;;
    m) MAXDEPTH="${OPTARG}"     ;;
    b) ACTION='BACKUP' 		;;
    r) ACTION='REMOVE'		;;
    c) ACTION='LIST'		;;
    n) NAGIOS='TRUE'		;;
    *) echo "Status UNKNOWN - Unexpected arguments given.  Exiting"; exit 3 ;;
  esac
done

#-------------------------------------------------------------------------------
#  Validate the inputs
#-------------------------------------------------------------------------------
if [ -z ${DIRECTORY} ]; then DIRECTORY="/opt/graphite/storage/whisper"; fi
if [ -z ${MAXDEPTH} ]; then MAXDEPTH=`getconf PATH_MAX ${DIRECTORY}`; fi
if [ -z ${ACTION} ]; then ACTION="LIST"; fi

# Bins used: find, whisper-info, mv, rm
# Verify existance of whisper-info???
# Are we root?

# Initialize variables:
matches=()
file=''
retval=''
file_list=$(find ${DIRECTORY} -maxdepth "${MAXDEPTH}" -type f -name '*.wsp' -print)
file_count=$(echo -en "${file_list}"|wc -l)

if [ ${file_count} -eq 0 ]; then
	if [ ${NAGIOS} ]; then
	echo -en "\r\033[KSTATUS UNKNOWN - ${file_count} Whisper Files Found in Given Directory Tree | checkedFiles=${file_count}\n"; exit 3
	else
	echo -en "\r\033[K ${file_count} Whisper Files Found in Given Directory Tree... Exiting\n"; exit 3
	fi
fi

if [ -z ${NAGIOS} ]; then
echo -e "Checking ${file_count} whisper files..."
fi

for file in ${file_list}; do
$(python /usr/local/bin/whisper-info.py $file > /dev/null 2>&1)
retval=$?
if [ -z ${NAGIOS} ]; then
echo -en "\r\033[KChecking $file"
fi
[ $retval -ne 0 ] && matches+=($file)
done

if [ ${#matches[@]} -eq 0 ]; then
	if [ ${NAGIOS} ]; then
	echo -en "\r\033[KSTATUS OK - ${#matches[@]} Corrupt Files | corruptFiles=${#matches[@]} checkedFiles=${file_count} \n"; exit 0
	else
	echo -en "\r\033[K${#matches[@]} Corrupt Files... Exiting\n"; exit 0
	fi
fi

# Need to fix up for nagios functionality

if [ $ACTION == 'LIST' ]; then
echo -en "\r\033[KListing ${#matches[@]} corrupt files:\n"
for file in "${matches[@]}"; do
echo -e "\t$file"
done

elif [ $ACTION == 'BACKUP' ]; then
echo -en "\r\033[KBacking Up ${#matches[@]} corrupt files:\n"
for file in "${matches[@]}"; do
sudo mv $file $file.bak && echo -e "\t$file to $file.bak"
done

elif [ $ACTION == 'REMOVE' ]; then
echo -e "\r\033[KDeleting ${#matches[@]} corrupt files:\n"
for file in "${matches[@]}"; do
sudo rm -f $file && echo -e "\t$file"
done

fi

