#!/bin/sh

#
#  Verify the argument(s) to the shell script.
#
if [ $# -ne 2 ]
then
    echo "Usage: $0 <script to run> <# times to run it>"
    exit 1
fi

scriptToRun=$1
counter=`expr $2`
while [ $counter != 0 ]
do
	echo "${counter} ${scriptToRun}"
        ${scriptToRun}
        counter=`expr ${counter} - 1`
done
