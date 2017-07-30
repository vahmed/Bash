#!/bin/bash 

HOST=ftp.site.com 
USER=production
PASS=T@xt
FILE=$1

ftp -inv $HOST << EOF

user $USER $PASS
bin
put $FILE
bye
EOF
