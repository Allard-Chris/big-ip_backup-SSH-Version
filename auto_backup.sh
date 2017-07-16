#!/bin/bash
#
#   Name : auto_backup.sh
# Author : Allard Chris
#   Date : 12/07/2017
#Version : 1.0

textMail="$(date "+%m_%d_%y-%T") Backup_F5:STARTED \n"

#list of appliances to backup
nbElement=("hostname.domaine.com" \
		"hostname2.domaine.com")

#loop on nbElement
for((i=$((${#nbElement[@]}-1));i>=0;i--)); do
	fileName=${nbElement[${i}]}-$(date "+%m_%d_%y")
	#make backup file on appliance
	ssh ACCOUNT@${nbElement[${i}]} "tmsh save sys ucs $fileName"
	#copy file to local
	scp ACCOUNT@${nbElement[${i}]}:/var/local/ucs/$fileName.ucs \
			/log/F5/${nbElement[${i}]}/$fileName.ucs > /dev/null
	#delete backup file on appliance
	ssh ACCOUNT@${nbElement[${i}]} "rm /var/local/ucs/$fileName.ucs"
	#delete backup local file older than 7 days
	find /log/F5/${nbElement[${i}]}/ -type f -mtime +7 -delete
	textMail+="\t${nbElement[${i}]}:OK\n"
done
textMail+="$(date "+%m_%d_%y-%T") Backup_F5:FINISHED \n"

#send mail via telnet commands in smtp
(
echo "HELO hostname.domaine.com"
sleep 1
echo "mail from: noreply@hostname.com"
sleep 1
echo "rcpt to: yourmail@hostname.com"
sleep 1
echo "data"
sleep 1
echo "subject: Rapport backup quotidien F5"
echo "Bonjour,"
echo -e $textMail
sleep 1
echo "."
sleep 1
echo "quit" ) | telnet smtp.domaine.com 25

#write in a local log file
echo -e $textMail >> /log/F5/resume.log