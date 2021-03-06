#!/bin/sh

# display usage
function usage() {
  echo "`basename $0`: Update DNS-O-MATIC dynamic DNS entries"
  echo "Usage:

`basename $0` -u <username> -p <password>"
        exit 255
}

# get command-line args
while getopts "u:p:" OPTION; do
  case $OPTION in
    u) userName="$OPTARG";;
    p) password="$OPTARG";;
    *) usage;;
  esac
done

# validate arguments
if [ -z "${password}" -o -z "${userName}" ]; then
  usage
fi

result="$(/usr/bin/curl -s -m 60 -u ${userName}:${password} 'https://updates.dnsomatic.com/nic/update?')"
retval=$?
alliswell=1
attempts=0

while [ $alliswell -eq 1 ]; do
	if [ "`echo $result | grep '^good' | wc -l`" -eq 0 ]; then
		# sleep for 90 seconds and try again
		sleep 90
		if [ "`echo $result | grep '^good' | wc -l`" -eq 0 ]; then
			let attempts+=1
			if [ $attempts -ge 5 ]; then
				echo "Problem updating IP address at OpenDNS. Filtering may not be working."
				exit 255
			fi
		else
			alliswell=0
		fi
	else
		alliswell=0
	fi
done

if [ $retval -ne 0 ]; then
	echo "$0: Curl exited with a non-zero status. You may want to investigate."
fi

exit 0
