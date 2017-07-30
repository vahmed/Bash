#!/bin/bash
# Name: storageRpt.sh Jul-7-2014
# 
# This script runs each week and generates storage reports 
# for xxxxxx db and emails.
# Updated: 02/04/2010 - Added gzip when archiving reports

export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1

BASE_DIR=/home/oracle
DB=xxxxxx
USER=system
PASS=yyyyyyyy
DATE=`date +%m-%d-%Y`

SQL_1=$BASE_DIR/storage_rpt.sql

cd $BASE_DIR/data

if [ -f storage_rpt.txt ]
then
    mv storage_rpt.txt storage_rpt.$DATE.txt
    gzip -f storage_rpt.$DATE.txt
fi


$ORACLE_HOME/bin/sqlplus -S $USER/`echo ${PASS}|openssl enc -base64 -d`@$DB @$SQL_1


if [ ! -z storage_rpt.txt ]
then
    
    RPT_DATE=`date +'%B, %Y'`
    # Manual override. Leave the line below commented unless you are running this script manually.
    #RPT_DATE="Mar, 2011"
    /bin/cat $BASE_DIR/email.txt | sed "s/#DATE#/$RPT_DATE/" > /tmp/email.$$.txt 
    cat $BASE_DIR/storage_rpt.txt | mutt -F $BASE_DIR/muttrc -s "XXXXX - Weekly Storage Report" -a $BASE_DIR/storage_rpt.txt myemail@sample.com < /tmp/email.$$.txt
else
echo "An error occured while running the weekly storage report for XXXXX." | mutt -F $BASE_DIR/scripts/muttrc -s "GTTOTP - Weekly Storage Report ERROR" myemail@sample.com
fi

rm -f /tmp/email.$$.txt
