#!/bin/sh

filesnum=0
linesnum=0

if [ $# -lt 2 ]
then
	echo "Invalid Number of Arguments."
	exit 1
else
	filesdir=$1
	searchstr=$2

	if [ ! -d $filesdir ]
	then
		echo "$filesdir does not exist!"
		exit 1
	fi
	
	filesnum=$(find ${filesdir} -type f | wc -l)
	linesnum=$(grep -r $searchstr $filesdir/* | wc -l)
fi

echo The number of files are $filesnum and the number of matching lines are $linesnum
