#!/bin/sh

if [ $# -lt 2 ]
then
	echo "Invalid Number of Arguments."
	exit 1
else
	writefile=$1
	writestr=$2
fi

filedir=$(dirname "$writefile")

mkdir -p "$filedir"

echo $writestr > "$writefile" || (echo Failed to create file $writefile with content: "'$writestr'"! ; exit 1)


