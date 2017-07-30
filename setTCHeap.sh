#!/bin/bash
DATE=`date +%m.%d.%Y`
HOST=`hostname`
UPDATE_FILE="bin/setenv.sh"
INSTANCES=`ls -1 /apps/online`
BASE="/apps/online"

for i in `echo ${INSTANCES}`
do

if [ ${i} != "swi-8090" ]
then
        cp -vp ${BASE}/${i}/${UPDATE_FILE} ${BASE}/${i}/${UPDATE_FILE}.bkp
        sed -i -e 's/-Xmx3192m/-Xmx2048m/g' ${BASE}/${i}/${UPDATE_FILE}
        touch -r ${BASE}/${i}/${UPDATE_FILE}.bkp ${BASE}/${i}/${UPDATE_FILE}
fi

if [ ${i} == "tcs-demo" ]
then
        /apps/online/${i}/bin/tcruntime-ctl.sh stop
        mkdir -p /apps/archived_instances
        mv -v /apps/online/${i} /apps/archived_instances
fi

if [ ${i} == "swi-8090" ]
then
        cp -vp ${BASE}/${i}/${UPDATE_FILE} ${BASE}/${i}/${UPDATE_FILE}.bkp
        sed -i -e 's/-Xmx3192m/-Xmx4192m/g' ${BASE}/${i}/${UPDATE_FILE}
        touch -r ${BASE}/${i}/${UPDATE_FILE}.bkp ${BASE}/${i}/${UPDATE_FILE}
        rm -f ${BASE}/${i}/webapps/poc_201310.war
        rm -f ${BASE}/${i}/webapps/poc_201410.war
fi
done
