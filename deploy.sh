#!/bin/bash

VER="0.0.1"
DATE=`date +%H_%M.%m.%d.%Y`
HOST=`hostname`
BASE="/apps/online"
FILES="activemq-5.13.2-1.noarch.rpm staticbin-0.0.2-1.noarch.rpm java-1.7.0.45-1.x86_64.rpm"
URL="http://devops.sample.com/"
FROM="deployAdmin@sample.com"
TO="notify@sample.com"
SMTP="relay"
LOG=~/static.deploy.${HOST}.${DATE}.log

mkdir -p ~/.platform
cat << EOF > ~/.rpmmacros
%user_home    %(echo $HOME)
%_dbpath    %{user_home}/.platform/%(echo $OSTYPE)/rpm
%_tmppath    /tmp
EOF

cp -vp ~/.bash_profile ~/.bash_profile.${DATE}.bkp

cat << EOF >> ~/.bash_profile
export JAVA_HOME=/apps/java/jdk1.7.0_45
export PATH=$PATH:$JAVA_HOME/bin
EOF

echo "Installing Static server applications..." | tee ${LOG}
export http_proxy=http://webproxy:80/;echo $http_proxy | tee -a ${LOG}
wget -q -O sendEmail ${URL}/sendEmail
chmod 755 sendEmail

echo "Backing up necessary files..." | tee -a ${LOG}
cp -vp /apps/bin/activemq ~/activemq.${DATE}.bkp | tee -a ${LOG}

for F in `echo ${FILES}`
do
if [ $(curl -s -o /dev/null -I -w "%{http_code}" ${URL}${F}) == "200" ]
        then
        echo "Downloading ${F}. Please wait.." | tee -a ${LOG}
        wget -q -O ${F} ${URL}${F} | tee -a ${LOG}
        rpm --nodeps -ivh ${F} | tee -a ${LOG}
        rpm -qi ${F%.*} | tee -a ${LOG}
else
        echo "ERROR: Could not find required software...Please notify DevOPS about this!!!" | tee -a ${LOG}
        rpm -qa | tee -a ${LOG}
fi
done

./sendEmail -f ${FROM} -t ${TO} -u "Static Upgrade - ActiveMQ" -a ${LOG} -s ${SMTP}:25 -m "Static Upgrade Complete. Please review attached logs."  | tee -a ${LOG}

rm -f sendEmail *.rpm
