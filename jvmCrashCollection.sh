#! /bin/bash

APPSERVER_HOME="/home/appserver"
JAVA_HOME="jrockit-R27.5.0-jdk1.5.0_14"

cd $APPSERVER_HOME

mkdir `hostname -s`_`date +%m_%d_%Y_%H_%M_%p`

PIDS=`/sbin/pidof java`

if [ -f /opt/$JAVA_HOME/bin/jrcmd ]
then
   echo "Setting JVM as JROKIT"
   echo "<--------------------top process details--------------------->" >> $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/os_memory_details
   for i in `echo ${PIDS}`
   do 
   echo "Running jstat...."
   /opt/$JAVA_HOME/bin/jstat -gc -t $i 1s 1 > $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/jstat.$i
   echo "Running jrcmd...."
   /opt/$JAVA_HOME/bin/jrcmd $i print_properties > $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/jrcmd.print_properties.$i
   /opt/$JAVA_HOME/bin/jrcmd $i print_object_summary > $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/jrcmd.print_object_summary.$i
   #/opt/$JAVA_HOME/bin/jrcmd $i verbose_referents > $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/jrcmd.verbose_referents.$i
   /opt/$JAVA_HOME/bin/jrcmd $i heap_diagnostics > $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/jrcmd.heap_diagnostics.$i
   /opt/$JAVA_HOME/bin/jrcmd $i print_threads > $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/jrcmd.print_threads.$i
   /usr/bin/top -b1 -n1 -p $i >> $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/os_memory_details
   done
   echo "Gathering vmstat..."
   echo "<--------------------vmstat--------------------->" >> $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/os_memory_details
   cat /proc/vmstat >> $APPSERVER_HOME/`hostname -s`_`date +%m_%d_%Y_%H_%M_%p`/os_memory_details
   cd $APPSERVER_HOME
   zip  -r `hostname -s`_`date +%m_%d_%Y_%H_%M_%p`.zip  `hostname -s`_`date +%m_%d_%Y_%H_%M_%p`
   rm -rf `hostname -s`_`date +%m_%d_%Y_%H_%M_%p`
   
fi
 
