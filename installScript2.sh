#!/bin/bash

# Terminal settings
BOLD=$(tput bold)
CLEAR=$(tput clear)
HIGH_LIGHT=$(tput smso)
RESET_TERM=$(tput sgr0)
BEGIN_UNDER=$(tput smul)
END_UNDER=$(tput rmul)
REV=$(tput rev)

LogInfo(){
	
	#echo $1
	echo $1 >> $logFile
}

# Creates log file
CreateLogFile(){
	currentDate=$(date +"%m_%d_%Y")
	logFile="$currentDir/AnalyticalReportingLog_$currentDate"

	if [ -f $logFile ]; then
		LogInfo "Removing old logfile"
		rm -f $logFile		
	fi
}

# Verify the installing user has write permission to directory where InetsoftConfig is stored
VerifyWritePermission(){
	LogInfo "Verifying user permissions"	 

	test -w $inetsoftConfigPath
	if [ $? -eq 0 ];then
		LogInfo "$(whoami) has write permission on $inetsoftConfigPath"

	else
		LogInfo "User does not have write permissions on $inetsoftConfigPath"
		echo -e "\nUser does not have write permissions on $inetsoftConfigPath"
		exit -1
	fi
}

#Checks to see if JAVA_HOME has been set and if the directory exists
VerifyJavaInstallation(){
	LogInfo "Verifying java is installed"	
	
	if [ -z $JAVA_HOME ]; then
		LogInfo "JAVA_HOME has not been set"			
		echo -e -n "\n${BOLD}Environment variable JAVA_HOME not set. Please specify JAVA_HOME(eg. /opt/java): "
		read JAVA_HOME
		if [ ! -f $JAVA_HOME/bin/java ]
			then
			echo -e "\nUnable to locate $JAVA_HOME/bin/java Installer will exit now."
			exit 1
		fi

	else
		if [ -d $JAVA_HOME ]; then
			LogInfo "Java has been installed on the machine"
		else
			LogInfo "JAVA_HOME does not point to the correct directory"
			echo -e "\n${BOLD}Unable to find java command based your JAVA_HOME. Export the correct JAVA_HOME and re-run this script."
			exit -1
		fi
	fi
}

#gets Java version 
VerifyJavaVersion(){
	LogInfo "Verifying java version"
	
	javapath="$JAVA_HOME/bin/java"
	javaVersionOutput=$("$javapath" -version 2>&1)
	javaVersionNum=${javaVersionOutput:16:1}
 
	if [ "$javaVersionNum" -ge 6 ]; then
		LogInfo "Java version is "$javaVersionNum""
		LogInfo "Java version requirements met"
		echo -e "\n${BOLD}Java version requirements met"
	else
		LogInfo "Java version "$javaVersionNum" not supported."
		echo -e "\n${BOLD} Java version not supported. Installer will exit"	
		exit -1
	fi
}

#Checks to see if CATALINA_HOME has been set and if the directory exists
VerifyTomcatInstallation(){
	LogInfo "Verifying tomcat is installed"
		
	if [ -z $CATALINA_HOME ]; then
		LogInfo "CATALINA_HOME has not been set or missing Tomcat installation."
		echo -e -n "\n${BOLD}Environment variable CATALINA_HOME not set. Please specify CATALINA_HOME(eg. /apps/apache-tomcat-7.0.50): "
		read CATALINA_HOME
		if [ ! -f $CATALINA_HOME/bin/catalina.sh ]
			then
			echo -e "\nUnable to locate $CATALINA_HOME/bin/catalina.sh Installer will exit now."
			exit 1
		fi
	else
		if [ -d $CATALINA_HOME ]; then
			LogInfo "Tomcat has been installed on the machine"			
		else
			LogInfo "Tomcat is not installed or has not been configured correctly"
			echo -e "\n${BOLD}Unable to find Tomcat install based on your CATALINA_HOME. Export the correct CATALINA_HOME and re-run this script."
			exit -1
		fi
	fi

}

#runs the version command and saves only the server version. 
#Verifies version is atleast 7
VerifyTomcatVersion (){
	LogInfo="Verifying tomcat version"
	
	tomcatPath=$CATALINA_HOME/bin/catalina.sh
	tomcatVersionOutput=$("$tomcatPath" version | grep "Server number: *.*.*.*" 2>&1)
	tomcatVersion=${tomcatVersionOutput:16:1}	

	if [ "$tomcatVersion" -ge 7 ]; then
		LogInfo "Tomcat version is "$tomcatVersion""
		echo -e "\n${BOLD}Tomcat requirements met"
		
	else
		LogInfo "Tomcat version "$tomcatVersion" not supported."
		echo -e "\n${BOLD}Tomcat version not supported. Script will exit"
		exit -1
	fi
}

#Checks to see if tomcat has 1024mb or 1gb+ of memory allocated. 
#If not a warning message is displayed 
CheckTomcatMemory(){
	LogInfo "Checking tomcat allocated memory"	
		
	mbMemory=$(grep "Xmx1024m" $CATALINA_HOME/bin/catalina.sh)
	
	if [ -z $mbMemory ]; then	

		gbMemory=$(grep "Xmx.*\g" $CATALINA_HOME/bin/catalina.sh)
		
		if [ -z $gbMemory ]; then
			LogInfo "Tomcat memory may be below the recommended amount"
			echo -e "\n${BOLD}For best performance increase memory to atleast 1GB"
		else
			LogInfo "Tomcat memory meets or excedes recommended amount"		
		fi
	
	else		
		LogInfo "Tomcat memory meets recommended amount"
	fi
}

# Asks the user if this is hosted environment.
IsHosted() {
	echo -e -n "\n${BOLD}Is this TR hosted environment? (Y/N): "
	read isHosted

	isHosted=$(echo "$isHosted" | tr '[:lower:]' '[:upper:]')
	
	if [ $isHosted = "Y" ]
		then
		echo -e -n "\nIs this production? (Y/N): "
		read isHostedProd
		isHostedProd=$(echo "$isHostedProd" | tr '[:lower:]' '[:upper:]')
	fi
}

# Cluster question
IsCluster() {
	echo -e -n "\n${BOLD}Is this in cluster mode? (Y/N): "
	read clusterMode
	clusterMode=$(echo "$clusterMode" | tr '[:lower:]' '[:upper:]')
	
	echo -e -n "\n${BOLD}Do you have a VIP configured on Loadbalancers? (Y/N): "
	read isVIP
	isVIP=$(echo "$isVIP" | tr '[:lower:]' '[:upper:]')

	if [ $isVP = "Y" ]
	then
		echo -e -n "\n${BOLD}Provide DNS name for VIP (eg. analysis.fas109.com): "
		read vipName
		vipName=$(echo "$vipName" | tr '[:upper:]' '[:lower:]')
	fi
	if [ $clusterMode = "Y"]
		then
			echo -e -n "\n${BOLD}Is this master server? (Y/N): "
			read isMaster
			isMaster=$(echo "$isMaster" | tr '[:lower:]' '[:upper:]')
		fi
}

#Get inetconfigfile path from user. Validate path, loop until path exists
GetInetSoftPath() {
	doesInetSoftPathExist="false"

	while [ $doesInetSoftPathExist = "false" ]; do
	
		echo -e -n "\nEnter path where the Inetsoft configs will be stored(eg. /apps): "
		read inetsoftConfigPath

		if [[ ! -z $inetsoftConfigPath && -d $inetsoftConfigPath ]]; then
			doesInetSoftPathExist="true"

			echo "Good $inetsoftConfigPath exist. Installer will copy the configs now."
			LogInfo "The user provided path $inetsoftConfigPath already exists"			
		else
			validResponse="false"
			while [[ $validResponse = "false" && ! -z $inetsoftConfigPath ]]; do
				echo -e "\nThe following path could not be found: "$inetsoftConfigPath""	
				echo -e -n "\nWould you like to create it? (Y/N): "
				read createFolder
		
				createFolder=$(echo "$createFolder" | tr '[:lower:]' '[:upper:]')				
		
				case $createFolder in
			
					[yY])
						LogInfo "Creating $inetsoftConfigPath"
						error=$(mkdir $inetsoftConfigPath 2>&1)
						ValidateAction "$error"
						validResponse="true"

						LogInfo "Folder created successfully"
						;;
					[nN])					
						validResponse="true"
						;;
					*)
						echo -e "\nInvalid character";;
				esac		
			done
		
			if [[ $createFolder = "Y" ]]; then
				doesInetSoftPathExist=true				
		
			else				
				continue
			fi
		fi	
	done
}

#Gets executing Directory
GetExecutingDirectory(){		 	
	currentDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}")" && pwd )"		
}


ValidateAction(){

	if [ -z "$1" ]; then
		return

	else
	 	echo -e "\nThere was an error performing this action"
		echo -e "\nScript will exit, see log file for details"
		LogInfo $1
		exit -1		
	fi
}

# Configure WAR based on deployment environment
ConfigureWAR(){
	echo -e "\nConfiguring reporting WAR"
	LogInfo "Configuring reporting WAR based on environment"
	if [ ! -f $currentDir/reporting.war ]; then
		LogInfo "reporting.war not found in $currentDir"
		echo -e "\nInetsoft WAR not found. Installer will exit."
		exit 1
	fi
	
	# Lets make a backup of original war before we begin
	if [ ! -f $currentDir/.reporting.war ]; then
		cp -p $currentDir/reporting.war $currentDir/.reporting.war
	fi
	mkdir -p $currentDir/reporting
	cp $currentDir/reporting.war $currentDir/reporting
	cd $currentDir/reporting
	$JAVA_HOME/bin/jar -xf reporting.war
	rm -f reporting.war
	sed -i 's,/opt,'$inetsoftConfigPath',g' WEB-INF/web.xml
	# If not hosted then remove following JARs
	if [ $isHosted = "N" ]; then
		LogInfo "Configuring non hosted environment"
		echo -e "\nConfiguring for non hosted"
		rm -f WEB-INF/lib/hcon*.jar
		rm -f WEB-INF/lib/hpcon*.jar
	fi
	# If hosted make changes to JARs below
	if [ $isHosted = "Y" ]; then
		if [ $isHostedProd = "Y" ]; then
			LogInfo "Configuring hosted Prod environment"
			echo -e "\nConfiguring for Hosted Prod"
			rm -f WEB-INF/lib/lcon*.jar
			rm -f WEB-INF/lib/hcon*.jar
			sed -i 's,qa-trtasso.int.thomson.com,trtasso.thomson.com,g' WEB-INF/classes/com/thomsonreuters/inetsoft/config.properties
		else
			LogInfo "Configuring hosted DEV/QA/SAT environment"
			echo -e "\nConfiguring for hosted DEV/QA/SAT"
			rm -f WEB-INF/lib/lcon*.jar
			rm -f WEB-INF/lib/hpcon*.jar
		fi
	fi
	# Configure slave to remove EM
	if [ $isMaster = "N" ]; then
		LogInfo "Slave setup indicated. removing web.xml EM section"
		startCut=$(grep -B 1 -A 12 'Remove' WEB-INF/web.xml -n | head -1  | cut -d'-' -f1)
		endCut=$(grep -B 1 -A 12 'Remove' WEB-INF/web.xml -n | tail -1  | cut -d'-' -f1)
		sed -i -e ''$startCut','$endCut'd' WEB-INF/web.xml
	fi

	$JAVA_HOME/bin/jar -cf ../reporting.war .
	cd $currentDir
	rm -rf reporting/
}

CopyWAR(){

	LogInfo "Attempting WAR copy to Tomcat in $CATALINA_HOME/webapps"
	test -w $CATALINA_HOME/webapps
	if [ $? -eq 0 ];then
		LogInfo "$(whoami) has write permission on $CATALINA_HOME/webapps"
		LogInfo "Copying reporting.war to $CATALINA_HOME/webapps"
		echo -e "\nCopying reporting.war to tomcat"
		cp -v $currentDir/reporting.war $CATALINA_HOME/webapps
	else
		LogInfo "Unable to copy reporting.war to $CATALINA_HOME/webapps"
		LogInfo "Manually copy reporting.war from $currentDir to $CATALINA_HOME/webapps"
		echo -e "\n${HIGH_LIGHT}Unable to copy $currentDir/reporting.war to $CATALINA_HOME/webapps"
		read -p "${RESET_TERM}Open another session to this host and copy reporting.war manually to tomcat's webapps then hit enter to continue"
	fi
}

#If Inetsoftconfig folder exists, user is asked if it should be overwrriten.
#If so the InetsoftConfig package is copied to the user specified directory
CopyInetSoftConfig(){

	LogInfo "Copying InetsoftConfig folder to $inetsoftConfigPath"
	
	if [ ! -d "$currentDir/InetsoftConfig" ]; then
		LogInfo "InetSoft Config not found in $currentDir"
		echo -e "\nInetSoftConfig not found. Installer will exit."
		exit 1
	fi

	if [ -d "$inetsoftConfigPath/InetsoftConfig" ]; then
			validResponse="false"
			while [ $validResponse = "false" ]; do
	
			echo -e -n "\nShould the folder contents of $inetsoftConfigPath/InetsoftConfig be overwitten? (Y/N): "
			read overWriteInetSoft
	
			overWriteInetSoft=$(echo "$overWriteInetSoft" | tr '[:lower:]' '[:upper:]')
	
			case $overWriteInetSoft in
				
				[yY])
					LogInfo "Overwriting AnalyticalSoftConfig"		
					
					inetSoftsourcePath="$currentDir/InetsoftConfig"
					inetSoftdestinationPath="$inetsoftConfigPath"
					mv $inetSoftdestinationPath/InetsoftConfig $inetSoftdestinationPath/InetsoftConfig.$currentDate 2>&1
					error=$(cp -r $inetSoftsourcePath $inetSoftdestinationPath 2>&1)
					ValidateAction "$error"
					validResponse="true"
					
					;;
				[nN])			
					LogInfo "The AnalyticalSoftConfig directory will not be replaced"
					validResponse="true"
					;;
				*)
					echo "Invalid character";;
			esac	
		done
	else
			
		inetSoftsourcePath="$currentDir/InetsoftConfig"
		inetSoftdestinationPath="$inetsoftConfigPath"
		LogInfo "Copying InetSoftConfig to $inetSoftdestinationPath"

		error=$(cp -r $inetSoftsourcePath $inetSoftdestinationPath 2>&1)
		ValidateAction "$error"
	fi
}

ConfigureProperties() {
	# minimum configuration of property file to set log & cache directory
	LogInfo "Configuring properties file"
	setLog=$(awk -F"=" '/^log.output.file/ {print $2}' $inetsoftConfigPath/sree.properties)
	sed -i 's,/'$setLog','$inetsoftConfigPath/analysis/log/sree.log',g' $inetsoftConfigPath/sree.properties
	setCache=$(awk -F"=" '/^replet.cache.directory/ {print $2}' $inetsoftConfigPath/sree.properties)
	sed -i 's,'$setCache','$inetsoftConfigPath/analysis/cache',g' $inetsoftConfigPath/sree.properties

	# Cluster Mode changes 
	if [ $clusterMode = "Y" ]
		then
		setCluster=`awk -F"=" '/^server.type/ {print $2}' $inetsoftConfigPath/sree.properties`
		sed -i 's,'$setCluster','server_cluster',g' $inetsoftConfigPath/sree.properties
		LogInfo "Setting server_cluster in $inetsoftConfigPath/sree.properties"
	fi
	if [ $clusterMode = "N" ]
		then
		setCluster=`awk -F"=" '/^server.type/ {print $2}' $inetsoftConfigPath/sree.properties`
		sed -i 's,'$setCluster','servlet',g' $inetsoftConfigPath/sree.properties
		LogInfo "Setting server_cluster in $inetsoftConfigPath/sree.properties"
	fi
}

LicenseInfo() {

	LogInfo "Verify Licensing details"
	checkCSH=$(awk -F"=" '/^cluster.servers.hosts/ {print $2}' $inetsoftConfigPath/sree.properties)
	checkCSL=$(awk -F"=" '/^cluster.servers.licenses/ {print $2}' $inetsoftConfigPath/sree.properties)
	if [ -n $checkCSH ] &&  [ -n $checkCSL ]
		then
		echo -e -n "\n${BOLD}Do you want to update license information? If YES have your hostname, port # and license information ready (Y/N): "
		read updateLicense
		updateLicense=$(echo "$updateLicense" | tr '[:lower:]' '[:upper:]')
		if [ $updateLicense = "Y" ]
			then
			echo -e -n "\n${BOLD}Enter server & port 1 per line and hit enter on blank line when finished (eg. hostX.domain.com 8080): "
			while read -a hostPortArr
			do [ ${#hostPortArr[@]} -eq 0 ] && break
			hostPort=$(echo ${hostPortArr[0]}\\:${hostPortArr[1]})
			clusterServerHost+=$hostPort';'

			echo -e -n "\n${BOLD}Enter License key comma seperated for multiple license keys (eg. S000-XXX*,S000-YYY*): "
			read licenseKeys
			licenseKeys=$(echo $licenseKeys | sed  s,' ','\\:',g)
			clusterServerLicense+=${hostPortArr[0]}\\:$licenseKeys';'
			echo -e -n "\n${BOLD}Enter server & port (eg. hostX.domain.com 8080): "
		done
	fi
fi
		echo ${clusterServerHost%?}
		echo ${clusterServerLicense%?}
}

CreateFolders() {

LogInfo "Checking if $inetsoftConfigPath/analysis exists"

# Check if the analysis folder exists under inetsoftConfigPath"

if [ ! -d $inetsoftConfigPath/analysis ]
then
	if [ ! -d $inetsoftConfigPath/analysis/logs ]
	then
		LogInfo "$inetsoftConfigPath/analysis/logs does not exists. creating."
		mkdir -p -v $inetsoftConfigPath/analysis/Logs
	fi

	if [ ! -d $inetsoftConfigPath/analysis/cache ]
	then
		LogInfo "$inetsoftConfigPath/analysis/cache does not exists. creating."
		mkdir -p -v $inetsoftConfigPath/analysis/cache
	fi
fi
}

VerifyReportingWarExists(){
	LogInfo "Verifying reporting.war file exists"
	
	reportingWarFile="$CATALINA_HOME/webapps/reporting.war"

	if [ -a "$reportingWarFile" ]; then
		LogInfo "Reporting war file deployed successfully"
		echo -e "\nReporting war file deployed to tomcat"
	else
		LogInfo "reporting.war could not be found. AnalyticalSoft reporting failed to deploy correctly"
		echo -e "\nreporting.war could not be found. Installer will exit"
		exit -1
	fi
}
	
GetIPAddress(){		
	LogInfo "Getting IP address"		

	ipaddress=$(/sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' 2>&1)
	
	LogInfo "Machine ipaddress: $ipaddress"
	echo -e "\nIP Address: $ipaddress"
}

ValidatePortStatus(){
	#checks to make sure there is at least 1 open port 
	if [ ${#openPortArray[@]} = 0 ]; then
		LogInfo "Tomcat has no open ports"
		echo -e "\nConfigure tomcat and restart script"
		echo -e "\nInstaller will exit"
		exit -1
	fi
}

#Checks to make sure user specified port exists in the array of open ports
ValidateUserPortNumber(){	
	for port in ${openPortArray[@]}; do
		if [ $tomcatPort = $port ]; then			
			isvalidPortEntry="true"
			break
		else
			echo -e "\nTomcat port is invalid"
			LogInfo "$tomcatPort is an invalid port"			
		fi
	done	
}

GetPort(){
	LogInfo "Loading ports used by tomcat"	

	#Gets all possible ports from tomcat server.xml separated by spaces
	tomcatPortsList=$(grep -w "port" $CATALINA_HOME/conf/server.xml | cut -d '"' -f2)
	
	#Tests each port to see if it's open. 
	#If tomcat has multiple ports they are stored in an array
	echo -e "\nChecking port status"
	for port in $tomcatPortsList
	do
		portStatus=$(netstat -an | grep $port)
		
		if [ -z "$portStatus" ]; then
			LogInfo "	$port is not open"
		else
			LogInfo "	$port is open"
			tomcatPort="$port"
			openPortArray=($openPortArray $port)		
		fi
	done

	ValidatePortStatus
}

#Checks to see if tomcat is using more than one port.
#If more than 1 port has been specified, the user will have to specify which to us
CheckOpenPorts(){
	if [ ${#openPortArray[@]} -eq '1' ]; then
		LogInfo "Tomcat port: $tomcatPort"		
	else
		LogInfo "Tomcat has been configured with multiple ports"
		
		isvalidPortEntry="false"
		while [ $isvalidPortEntry = "false" ]; do
			
			echo "Available Ports"

			for ((i=0; i<${#openPortArray[@]}; i++ ));
			do
				echo "	${openPortArray[i]}"				
				
			done
		
			echo -e -n "\nEnter the port you would like to use from the list above: "
			read tomcatPort

			ValidateUserPortNumber		
		done
	fi
}

#Formats url
GetReportingURL(){
		
	
	LogInfo "Creating reporting URL"	
	hostName=$(hostname)

	verifyHost=$(grep $hostName$ /etc/hosts)
	if [ $? != 0 ]; then
		altReportingUrl=("http://$ipaddress:$tomcatPort/reporting/Reports")
		echo -e "\nHostname: $hostName not found in /etc/hosts file."
		echo -e "\nPlease make sure you update the hosts file or use IP Address instead"
		echo -e "\n${BEGIN_UNDER}Alternate Reporting URL: $altReportingUrl${END_UNDER}"
		LogInfo "Hostname is not set for $hostName in server's hosts file. Alternate Reporting URL: $altReportingUrl"
		missingHost=1
	fi
	reportingUrl=("http://$hostName:$tomcatPort/reporting/Reports")

	LogInfo "Reporting URL: $reportingUrl"
	echo -e "\n${BEGIN_UNDER}Reporting URL: $reportingUrl${END_UNDER}"
	echo -e "\nIf you have a load balancer VIP configured as reporting url then substitute your hostname with that VIP and configured Port."

	echo -e "\nSave this URL, it will be required during the OTP desktop installation"
}

PingReportingURL(){

	LogInfo "Checking if WAR exploded"
	if [ -d $CATALINA_HOME/webapps/reporting ]; then

	LogInfo "Testing reporting URL"

	pingURL=$(curl -ls --connect-timeout 60 "$reportingUrl?op=ping")
	
	fi
	if [ "$pingURL" = "ok" ]; then
		echo -e "\nReporting URL test successful"	
	else
		echo -e "\nReporing URL test failed"
	fi
}

#Stops tomcat
StopTomcat(){

	echo -e "\nStopping Tomcat"
	LogInfo "Stopping tomcat"
	tcOwner=$(stat -c %U $CATALINA_HOME/bin/shutdown.sh)
	scriptOwner=$(whoami)

if [ $tcOwner = $scriptOwner ]; then
	mv -f $CATALINA_HOME/webapps/reporting.war $currentDir/.old.reporting.war 2>/dev/null 
	sleep 5
	error=$( { $CATALINA_HOME/bin/shutdown.sh >> $logFile; } 2>&1 )
	
	if [ -z "$error" ]; then
		pgrep -d' ' -f $CATALINA_HOME | xargs kill -9 2>/dev/null
		return
	else				
		echo -e "\nTomcat is either not running or could not be stopped."
		LogInfo "Killing tomcat to make sure its down before attempting this deploy"
		pgrep -d' ' -f $CATALINA_HOME | xargs kill -9 2>/dev/null 
	fi
else
	LogInfo "Tomcat is owned by $tcOwner and not $ScriptOwner. Requesting manual Tomcat shutdown"
	echo -e "\nTomcat is owned by $tcOwner which is not same as this user $ScriptOwner"
	read -p "Either run this script as $tcOwner or open another terminal and stop Tomcat manually and return here to continue"
fi
}

#Starts tomcat. At times the script would check for open ports before 
#tomcat could start so we sleep for 5 seconds.
StartTomcat(){

	echo -e "\nStarting Tomcat"
	LogInfo "Starting tomcat"
	tcOwner=$(stat -c %U $CATALINA_HOME/bin/startup.sh)
	scriptOwner=$(whoami)

if [ "$tcOwner" = "$scriptOwner" ]; then
	cd $CATALINA_HOME/logs

	# Clear cache
	$CATALINA_HOME/bin/clean_cache

	error=$( { $CATALINA_HOME/bin/startup.sh >> $logFile; } 2>&1 )
	
	sleep 10
	
	if [ -z "$error" ]; then
		return
	else				
		echo -e "\nTomcat is either already running or could not be started."
	
	fi
else
	LogInfo "Tomcat is owned by $tcOwner and not $ScriptOwner. Requesting manual Tomcat startup"
	echo -e "\nTomcat is owned by $tcOwner which is not same as this user $ScriptOwner"
	read -p "Open another terminal and start Tomcat manually and return here to continue"
fi
}

echo ${CLEAR}
echo "${HIGH_LIGHT}${BEGIN_UNDER}AnalysisSoft Installer${END_UNDER}"
echo ${RESET_TERM}

#Function calls
IsHosted
IsCluster
GetExecutingDirectory
CreateLogFile
VerifyJavaInstallation
VerifyJavaVersion
VerifyTomcatInstallation
VerifyTomcatVersion
CheckTomcatMemory
StopTomcat
GetInetSoftPath
VerifyWritePermission
CopyInetSoftConfig
CreateFolders
ConfigureWAR
CopyWAR
VerifyReportingWarExists
StartTomcat
GetIPAddress
GetPort
CheckOpenPorts
GetReportingURL
PingReportingURL
echo ${RESET_TERM}
