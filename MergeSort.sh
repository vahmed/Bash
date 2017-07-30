#!/bin/bash
# Name: nasir.ahmed.sh
# Date: 28-Jul-2017
# Description: Script concatnates Apache access logs and groups entries by IP and sorted by time
# Sample input: 74.125.196.102- showtimeonline [22/Feb/2015:06:25:02 +0000] "GET /xxx/xxx HTTP/1.1" 200 41174 "file:///" "Mozilla/4.0 (compatible; NativeHost)"

# 1st argument accepts path to folder that has 1GB x 64 files
SRC_DIR=$1
# 2nd argument accepts path to destination folder where hwOutputFile.log would be placed
DST_DIR=$2 
# Find out the number of processors in order to see if sort command can be parallelized
NPROC=$(grep -c ^processor /proc/cpuinfo)

# Check to make sure both args are supplied if not show usage and exit
if [ $# -ne 2 ]
	then
	echo "Usage: $0 SRC_DIR DST_DIR"
	exit
fi

# Check to make sure both source and destination directories exists
if [ -d "${SRC_DIR}" ] && [ -d "${DST_DIR}" ]
	then
	# If hwOutputFile.log already exists remove it
	[ -e ${DST_DIR}/hwOutputFile.log ] && rm -f ${DST_DIR}/hwOutputFile.log
	
	echo "${SRC_DIR} found.. Trying to process files"

	# Timing the actual find/sort commands
	START=$(date +%s)
	# Find the hwFile*.log in source directory and pipe to sort for grouping data by IP and time
	find ${SRC_DIR} -type f -name "hwFile*.log" -print0 | sort --files0-from=- --parallel=${NPROC} -s -S 25% -T ${DST_DIR} | sort --parallel=${NPROC} -s -S 25% -b -t[ -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n -o ${DST_DIR}/hwOutputFile.log &
	
	SRT_PID=$!
	while kill -0 ${SRT_PID} 2> /dev/null # Signal 0 just tests whether the process exists
	do
  	echo -n "."
  	sleep 2
	done
	# End time
	END=$(date +%s)
	echo 

	# Check previous command exit status and notify user accordingly
	if [ $? -eq 0 ]
	then
  	  echo "Completed in $((END-START)) secs.. Output saved to ${DST_DIR}"
	else
  	  echo "Something went wrong.. please make sure the hwFile[1-64].log files exists in ${SRC_DIR}" >&2
	fi
fi
trap "kill -9 ${SRT_PID} 2> /dev/null; exit" 1 2 3 15
