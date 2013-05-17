#!/bin/bash

# Watchdog script to monitor OpenVZ VEs
# Derived from script by Thomas Mellenthin <melle@gmx.at>
# http://blog.mellenthin.de/archives/2010/03/29/watchdog-script-to-supervise-procuser_beancounters/

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

if [ $(vzlist 2>&1 | wc -l) = 1 ]; then
	# Stop if no containers are running
	exit 0
fi

# get running VEs
VES=`/usr/sbin/vzlist -H -o veid | egrep -v "ignoreTheseVEIDs"`
MAILFILE=/var/run/vzwatchdog_mail.txt

# check every running VE
for VE in $VES; do
	# create file if it does not exist
	NEWFCFILE=/var/run/vzwatchdog_$VE.txt
	LASTFCFILE=/var/run/vzwatchdog_$VE.last-alert.txt

	# Create file if missing
	test -f $LASTFCFILE || touch $LASTFCFILE

	# save current failcounter
	vzctl exec $VE 'cat /proc/user_beancounters' | cut -b 13-129 | sed 's/ \+/ /g' | awk {'print $6 "\t"  $1'} > $NEWFCFILE

	# If $BARRIER percent of the softlimit have been reached, trigger an error
	BARRIER=90

	if ! grep -q "^DISK_QUOTA=\"no\"" /etc/vz/conf/$VE.conf; then
		# Check if disk quota limit is reached
		WARNING=
		line=$(vzquota -b stat $VE | head -n 1)
		USED=$(     echo $line | cut -d" " -f1)
		SOFTLIMIT=$(echo $line | cut -d" " -f2)
		test $USED -gt $(($SOFTLIMIT/100*$BARRIER)) && RESULT="1" && WARNING="$BARRIER% was reached!" || RESULT="0"
		echo -e "$RESULT\tdiskquota $WARNING" >> $NEWFCFILE

		# Check if disk inodes limit is reached
		WARNING=
		line=$(vzquota -b stat $VE | tail -n 1)
		USED=$(     echo $line | cut -d" " -f1)
		SOFTLIMIT=$(echo $line | cut -d" " -f2)
		test $USED -gt $(($SOFTLIMIT/100*$BARRIER)) && RESULT="1" && WARNING="$BARRIER% was reached!" || RESULT="0"
		echo -e "$RESULT\tdiskinodes $WARNING"  >> $NEWFCFILE
	fi

	# compare to reference failcounter
	diff -U 0 -d $LASTFCFILE $NEWFCFILE > /dev/null
	if [ $? != 0 ]; then
		# yepp, something failed
		echo "****************************************" >> $MAILFILE
		echo "UBC fail in VE $VE!" >> $MAILFILE
		diff -U 0 -d $LASTFCFILE $NEWFCFILE | grep "^[+,-][a-z,A-Z,0-9]\+" >> $MAILFILE
		echo "****************************************" >> $MAILFILE
		echo "" >> $MAILFILE
		echo "UBC now:" >> $MAILFILE
		vzctl exec $VE 'cat /proc/user_beancounters' >> $MAILFILE
		vzquota stat $VE >> $MAILFILE
		echo "" >> $MAILFILE

		# save new failcounter as reference
		cp $NEWFCFILE $LASTFCFILE
	fi
done;

# send mail to root
if [ -f $MAILFILE ]; then
	mail -s "UBC Fail!" root < $MAILFILE
	rm $MAILFILE
fi
