#!/bin/bash
#
# StackX Monitoring System (SMS)
# sms.sh / lamp_monitoring.stackx.sh
# Author: Christophe Casalegno / Brain 0verride
# Contact: brain@christophe-casalegno.com
# Version 1.0.2
#
# Copyright (c) 2020 Christophe Casalegno
#
# This program is free software: you can redistribute it and/or modify
#
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>
#
# The license is available on this server here:
# https://www.christophe-casalegno.com/licences/gpl-3.0.txt
#
# To inlude in a php page for example: (dont forget to put your script in a
# directory not readable by your web server)
#
# The graphic banner is available here:
# https://www.christophe-casalegno.com/banners/ScalarX.jpg
#
# <?php
#
# function checkall()
# {
#	$homecheck = "/home/sx/data";
#	$checkscript = "lamp_monitoring.stackx.sh";
#	$check="$homecheck/$checkscript";
#	system("$check");
# }
#
# checkall();
# ?>
#
# Example for a CONF_FILE: (with only needed variable for this script)
# loginsxmysql:sx
# passsxmysql:prxotpoofas
#
# Example for process2monitor.txt (generated automatically by my deployer for each server)
# apache2
# fail2ban-server
# memcached
# miniserv.pl
# php-fpm5.6
# php-fpm7.0
# php-fpm7.1
# php-fpm7.2
# php-fpm7.3
# php-fpm7.4
# php-fpm8.0
# pure-ftpd
# sshd
#
# Example for fs_list.txt (generated automatically by my deployer for each server)
#
# grep -v '#' /etc/fstab |awk '{print $2}' > fs_list.txt
#
# If you use other filesystem like network sshfs you may add:
# grep  'sshfs' /etc/fstab |awk '{print $2}' >> fs_list.txt
#
# Result can be something like :
# /
# /datastore
# /datadrop/cd101
# etc. depending of your configuration
#
# Need to check more tcp services on a limited system without netcat, etc.?
# You can use directly:
# timeout 1 cat </dev/tcp/$ip/port to create your own tcp banner grabber.
# For example : timeout 1 cat </dev/tcp/127.0.0.1/65022



CONF_FILE="/home/sx/.sx" # Replace by your config file
#CONF_FILE="/home/jpg/Github/Bash-by-Chris-Casalegno/scr/conf.txt" # Replace by your config file

function read_config()
{
	CONF_FILE="$1"
	VAR_CONF=$(cat $CONF_FILE |sed "s/ /_/g")

	for LINE in $VAR_CONF
	do
		VARNAME1=${LINE%%:*}
		VARNAME2=${VARNAME1^^}
		VAR=${LINE#*:}
		eval ${VARNAME2}=$VAR

		# Alternative with external programs like cut, grep and tr
		# VARNAME=$(echo $LINE |cut -d ":" -f1 |tr [:lower:] [:upper:])
		# VAR=$(echo $LINE |grep -w "$VAR_CONF" |cut -d ":" -f2)
		# eval ${VARNAME}=$VAR

	done
}

read_config $CONF_FILE

function format()
{
	TARGETFORMAT="$1"
	CHAIN2FORMAT="$2"

	if [[ "$TARGETFORMAT" = 'N' ]]
	then
		echo "<font size=-1>$CHAIN2FORMAT</font>"
	elif [[ "$TARGETFORMAT" = 'O' ]]
	then
		echo "<font size=-1 color='#64FE2E'>$CHAIN2FORMAT</font>"
	elif [[ "$TARGETFORMAT" = 'W' ]]
	then
		echo "<font size=-1 color='yellow'>$CHAIN2FORMAT</font>"
	elif [[ "$TARGETFORMAT" = 'E' ]]
	then
		echo "<font size=-1 color='red'>$CHAIN2FORMAT</font>"
	else
		echo 'format not specified'
	fi
}

function checktest()
{
  if [ "$1" -eq 0 ]

       then
                       format N "$2:"
                       format O "OK"
       else
                       format N "$2:"
                       format E "ERROR"
fi
echo '<br>'
}

function checkwarning()
{
	if [ "$1" -eq 0 ]
	then
		format N "$2:"
		format O "OK"
	else
		format N "$2:"
		format W "WARNING"
	fi
echo '<br>'
}

function startpage()
{
	HTML_TITLE="$1"
	echo '<html>'
	echo '<head>'
	echo "<title>$HTML_TITLE</title>"
	echo '</head>'
	echo  '<body bgcolor="#000000" text="white">'
}

function title()
{
	TITLE="$1"
	echo '<table><tr><td valign="middle">'
	echo '<img src="ScalarX.jpg" alt="ScalarX">'
	echo '</td><td width="5"></td><td valign="middle">'
	echo "<font size +5><strong>$TITLE</strong></font>"
	echo '</td></tr></table>'
	echo '<hr width="600" align="left">'
}

function titlecheck()
{
	TITLE_CHECK="$1"
  	echo "<br>"
  	format N "<strong>$TITLE_CHECK check</strong>"
  	echo "<hr>"
}

function table_init()
{
	echo '<table width=600><tr><td valign="top">'
}

function center_column()
{
echo '</td>'
echo '<td width="20"></td>'
echo '<td valign="top">'
}

function table_end()
{
	echo '</td></tr></table>'
}

function endpage()

{
	echo "</body>";
	echo "</html>";
}

PROCESS_CONF="/home/sx/data/process2monitor.txt"
FILE2CHECK=$(cat $PROCESS_CONF)

function check_process()

{
	P2CHECK="$1"
	PROCESS=$(pgrep -c "$P2CHECK")

	if [[ "$PROCESS" -eq 0 ]]
	then
		format N "$P2CHECK:"
		format E "ERROR"
	else
		format N "$P2CHECK:"
		format O "OK"
	fi

}

function internet_check()
{
	titlecheck "Internet"
	for DNS in "$@"
	do
		CHECK_DNS_PING=$(ping -c 1 -W 1 $DNS > /dev/null; echo "$?")
		checkwarning "$CHECK_DNS_PING" "$DNS ping"
	done
}

function dns_check()
{
	titlecheck "DNS resolve"
	for DNS in "$@"
	do
		CHECK_DNS_RESOLVE=$(dig +time=0 +tries=1 $DNS > /dev/null; echo "$?")
		checkwarning "$CHECK_DNS_RESOLVE" "$DNS host"
	done
}

function mysql_check()
{
	LOGINSXSQL="$1"
	DBPASSWORDSQL="$2"
	REPLICATION_TRESHOLD="$3"
	DBSXSQL="sx"
	TABLE_NAME="sx_test"
	ERRORS=()

	CONNECT="mysql -u$LOGINSXSQL --database=$DBSXSQL -p$DBPASSWORDSQL -e "

	titlecheck "MySQL / MariaDB"

	CONNECTION_SQL=$($CONNECT "SHOW VARIABLES LIKE '%version%';" > /dev/null; echo "$?")
	checktest "$CONNECTION_SQL" "Connexion SQL"

	CREATE_TABLE=$($CONNECT "CREATE TABLE $TABLE_NAME(test varchar(255));" >/dev/null; echo "$?")
	checktest "$CREATE_TABLE" "Create table"

	SHOW_TABLE=$($CONNECT "SHOW TABLES;" > /dev/null; echo "$?")
	checktest "$SHOW_TABLE" "Show tables"

	DELETE_TABLE=$($CONNECT "DROP TABLE $TABLE_NAME;" >/dev/null; echo "$?")
	checktest "$DELETE_TABLE" "Delete table"

	if [[ $REPLICATION_TRESHOLD != '0' ]]
	then

	titlecheck "Replication MySQL / MariaDB"

	SLAVE_STATUS=$($CONNECT "SHOW SLAVE STATUS\G" |grep -v row)

	LAST_ERRNO=$(echo "$SLAVE_STATUS" |grep "Last_Errno:" |awk '{print $2}')
	if [[ $LAST_ERRNO = 0 ]]
	then
		format N "Last_Errno:"
		format O "OK"
	else
		format N "Last_Errno:"
		format E "ERROR"
	fi
	echo '<BR>'

	REPLICATION_LATE=$(echo "$SLAVE_STATUS" |grep  "Seconds_Behind_Master:" | awk '{ print $2 }' )

	if [[ $REPLICATION_LATE == "NULL" ]]
	then
		format N "Second(s)_late:"
		format E "ERROR"

	elif [[ $REPLICATION_LATE -gt $REPLICATION_TRESHOLD ]]
	then
		format N "Second(s)_late:"
		format E "<strong>ERROR ($REPLICATION_LATE)</strong>"
	else
		format N "Second(s)_late:"
		format O "OK ($REPLICATION_LATE)"
	fi

	echo '<BR>'

	SLAVE_IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{ print $2 }' )

	if [[ $SLAVE_IO_RUNNING = "Yes" ]]

	then
		format N "S_IO_Running:"
		format O "OK"
	else
		format N "S_IO_Running:"
		format E "ERROR"
	fi

	echo '<BR>'

	SLAVE_SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{ print $2 }')

	if [[ $SLAVE_SQL_RUNNING = "Yes" ]]
	then
		format N "S_SQL_Running"
		format O "OK"
	else
		format N "S_SQL_Running"
		format E "ERROR"
	fi

	echo '<BR>'

else
	true
fi

}

function memcached_check()
{
	IP="$1"
	PORT="$2"

	titlecheck "Memcached"

	MEMCACHED=$(echo stats |timeout 1 bash -c "</dev/tcp/$IP/$PORT" > /dev/null; echo "$?")

	checktest "$MEMCACHED" "Memcached connect (port 11211)"
}

function disk_check()

{
	SPACE_ERROR_TRESHOLD="$1"
	SPACE_WARNING_TRESHOLD="$2"
	INODES_ERROR_TRESHOLD="$3"
	INODES_WARNING_TRESHOLD="$4"

	titlecheck "Disks"

	LIST_DISK=$(df -x tmpfs -x devtmpfs | grep 'dev' |awk -F " " '{print $1}' |cut -d/ -f3)

	for DISK in $LIST_DISK
	do
		SPACE_USED_PERCENT=$(df |grep -w "$DISK" |head -1|awk -F" " '{print $5}' |cut -d% -f1)
		SPACE_USED=$(df -x tmpfs -x devtmpfs -h |grep "$DISK" |head -1 |awk -F " " '{print $3}')
		SPACE_TOTAL=$(df -x tmpfs -x devtmpfs -h |grep "$DISK" |head -1 |awk -F " " '{print $2}')

		if [[ "$SPACE_USED_PERCENT" -gt "$SPACE_ERROR_TRESHOLD" ]]
		then
			format N "Part: <strong>$DISK</strong> - $SPACE_USED / $SPACE_TOTAL ($SPACE_USED_PERCENT%) space:"
			format E "ERROR"
			echo '<br>'
		elif [[ "$SPACE_USED_PERCENT" -gt "$SPACE_WARNING_TRESHOLD" ]]
		then
			format N "Part: <strong>$DISK</strong> - $SPACE_USED / $SPACE_TOTAL ($SPACE_USED_PERCENT%) space:"
			format W "WARNING"
			echo '<br>'
		else
			format N "Part: <strong>$DISK</strong> - $SPACE_USED / $SPACE_TOTAL ($SPACE_USED_PERCENT%) space:"
			format O "OK"
			echo '<br>'
		fi

		INODES_USED_PERCENT=$(df -i|grep -w "$DISK" |head -1 |awk -F" " '{print $5}' |cut -d% -f1)
		INODES_USED=$(df -i -h |grep -w "$DISK" |head -1 |awk -F" " '{print $3}' |cut -d% -f1)
		INODES_TOTAL=$(df -i -h |grep -w "$DISK" |head -1 |awk -F" " '{print $2}')

		if [[ "$INODES_USED_PERCENT" -gt "$INODES_ERROR_TRESHOLD" ]]
		then
			format N "Part: <strong>$DISK</strong> - $INODES_USED / $INODES_TOTAL ($INODES_USED_PERCENT%) inodes:"
			format E "ERROR"
			echo '<br>'
		elif [[ "$INODES_USED_PERCENT" -gt "$INODES_WARNING_TRESHOLD" ]]
		then
			format N "Part: <strong>$DISK</strong> - $INODES_USED / $INODES_TOTAL ($INODES_USED_PERCENT%) inodes:"
			format W "WARNING"
			echo '<br>'
		else
			format N "Part: <strong>$DISK</strong> - $INODES_USED / $INODES_TOTAL ($INODES_USED_PERCENT%) inodes:"
			format O "OK"
			echo '<br>'
		fi

	done
}

function mem_check()

{
	MEM_ERROR_TRESHOLD="$1"
	MEM_WARNING_TRESHOLD="$2"
	MEM_TOTAL=$(free -h |grep Mem |awk '{print $2}' |cut -d "i" -f1)

	titlecheck "Memory"

	MEM_USED_PERCENT=$(free |awk 'FNR == 2 {print 100-(($2-$3)/$2)*100}' |cut -d "." -f1)
	MEM_USED=$(free -h |grep Mem |awk '{print $3}' |cut -d "i" -f1)

	if [[ "$MEM_USED_PERCENT" -gt "$MEM_ERROR_TRESHOLD" ]]
	then
		format N "Memory usage: $MEM_USED / $MEM_TOTAL ($MEM_USED_PERCENT%):"
		format E "ERROR"
	elif [[ "$MEM_USED_PERCENT" -gt "$MEM_WARNING_TRESHOLD" ]]
	then
		format N "Memory usage: $MEM_USED / $MEM_TOTAL ($MEM_USED_PERCENT%):"
		format W "WARNING"
	else
		format N "Memory usage: $MEM_USED / $MEM_TOTAL ($MEM_USED_PERCENT%):"
		format O "OK"
	fi
}

function load_check()
{
	THREADS=$(grep processor /proc/cpuinfo |wc -l)
	LOAD_TRESHOLD=$(echo $(($THREADS * 2)))
	WAIT_B4_CHECK="1"

	echo "<br>"
	titlecheck "Load Average"

	LOAD_AVERAGE1=$(awk '{print $1}' < /proc/loadavg |cut -d "." -f1)
	sleep "$WAIT_B4_CHECK"
	LOAD_AVERAGE2=$(awk '{print $1}' < /proc/loadavg |cut -d "." -f1)

	if [[ "$LOAD_AVERAGE1" -ge "$LOAD_TRESHOLD" ]]
	then
		if [[ "$LOAD_AVERAGE2" -ge "$LOAD_AVERAGE1" ]]
		then
			format N "Load average ($LOAD_AVERAGE2 / $LOAD_TRESHOLD) / $THREADS core(s):"
			format E "ERROR"
		else
			format N "Load average ($LOAD_AVERAGE2 / $LOAD_TRESHOLD) / $THREADS core(s) but going down:"
			format W "WARNING"
		fi
	else
		format N "Load average ($LOAD_AVERAGE2 / $LOAD_TRESHOLD) / $THREADS core(s):"
		format O "OK"

	fi
}

function all_process_check()
{
for LINE2CHECK in $FILE2CHECK
do

	check_process "$LINE2CHECK"
	echo "<BR>"

done
}

function fs_check()
{

	FS_ACTIVE="$1"

	if [[ $FS_ACTIVE = "yes" ]]
	then
			titlecheck "Filesystems"

		for LINE in $(cat /home/sx/data/fs_list.txt)
		do
				FS=$(df -x tmpfs -x devtmpfs |grep '\|@' |grep $LINE)

				if [[ -z "$FS" ]]
				then
							format N "$LINE:"
							format E "ERROR"
							echo '<br>'
				else
							format N "$LINE:"
							format O "OK"
							echo '<br>'
				fi
		done
	else
			true
	fi

}

startpage "StackX Local monitoring"
title "StackX Monitoring System"
table_init
titlecheck "Server process"
all_process_check
internet_check 1.1.1.1 8.8.8.8
dns_check google.com cloudflare.com
fs_check
center_column
#mysql_check $LOGINSXMYSQL $PASSSXMYSQL 0
#memcached_check 127.0.0.1 11211
disk_check 95 50 95 90
mem_check 95 90
load_check
table_end
endpage
