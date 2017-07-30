# Edit this file to CATALINA_BASE/bin/setenv.sh to set custom options
# Tomcat accepts two parameters JAVA_OPTS and CATALINA_OPTS
# JAVA_OPTS are used during START/STOP/RUN
# CATALINA_OPTS are used during START/RUN

# JVM memory settings - general
GENERAL_JVM_OPTS="-Xmx1536m -Xms512m -server -Xss192k"

# JVM Sun specific settings
# For a complete list http://blogs.sun.com/watt/resource/jvm-options-list.html
#SUN_JVM_OPTS="-XX:MaxPermSize=192m \
#              -XX:MaxGCPauseMillis=500 \
#              -XX:+HeapDumpOnOutOfMemoryError"

SUN_JVM_OPTS="-XX:MaxPermSize=512m \
              -XX:PermSize=64m \
              -XX:NewSize=192m \
              -XX:MaxNewSize=640m \
              -XX:+HeapDumpOnOutOfMemoryError \
              -XX:HeapDumpPath=$CATALINA_BASE/logs/"

# JVM IBM specific settings
#IBM_JVM_OPTS=""

# Set any custom application options here
#APPLICATION_OPTS=""

# Must contain all JVM Options.  Used by AMS.
JVM_OPTS="$GENERAL_JVM_OPTS $SUN_JVM_OPTS"

CATALINA_OPTS="$JVM_OPTS $APPLICATION_OPTS"

#JAVA_HOME=setme
JAVA_HOME=/opt/java/jdk1.7.0_55

#JVM MEMORY ALLOCATION
CATALINA_OPTS="-Xmx1536m -Xms512m"

#APR LIBRARY LOAD
CATALINA_OPTS="$CATALINA_OPTS -Djava.library.path=/opt/environments/springsource-tc-server-node/tomcat-6.0.29.A.RELEASE/apr-connector/lib"

#JMX Console Enable
JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote"

#PERMGEN SPACE ALLOCATION
JAVA_OPTS="$JAVA_OPTS -XX:PermSize=64m -XX:MaxPermSize=512m"

# AWT Headless for image uploads
JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"
