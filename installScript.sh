#!/bin/bash

LogInfo(){
	
	echo $1
	echo $1 >> $logFile
}

CreateLogFile(){
	currentDate=$(date +"%m_%d_%Y")
	logFile="$currentDir/InetSoftScriptLog_$currentDate"

	if [ -f $logFile ]; then
		LogInfo "Removing old logfile"
		rm -f $logFile		
	fi
}

VerifyUserIsRoot(){
	LogInfo "Verifying user permissions"	 

	test -w /
	if [ $? -eq 0 ];then
		LogInfo "User is root"						
	else
		LogInfo "User must be root to execute this script"
		echo "Script will exit"		
		exit -1
	fi
}

#Checks to see if JAVA_HOME has been set and if the directory exists
VerifyJavaInstallation(){
	LogInfo "Verifying java is installed"	
	
	if [ -z $JAVA_HOME ]; then
		LogInfo "JAVA_HOME has not been set"			
		echo "Script will exit"
		exit -1
	else
		if [ -d $JAVA_HOME ]; then
			LogInfo "Java has been installed on the machine"
		else
			LogInfo "JAVA_HOME does not point to the correct directory"
			echo "Script will exit"
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
	else
		LogInfo "Java version "$javaVersionNum" not supported."
		echo "Installer will exit"	
		exit -1
	fi
}

#Checks to see if CATALINA_HOME has been set and if the directory exists
VerifyTomcatInstallation(){
	LogInfo "Verifying tomcat is installed"
		
	if [ -z $CATALINA_HOME ]; then
		LogInfo "CATALINA_HOME has not been set"
		echo "Script will exit"
		exit -1
	else
		if [ -d $CATALINA_HOME ]; then
			LogInfo "Tomcat has been installed on the machine"			
		else
			LogInfo "Tomcat is not installed or has not been configured correctly"
			echo "Script will exit"
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
		echo "Tomcat requirements met"
		
	else
		LogInfo "Tomcat version "$tomcatVersion" not supported."
		echo "Script will exit"
		exit -1
	fi
}

#Checks to see if tomcat has 1024mb or 1gb+ of memory allocated. 
#If not a warning message is displayed 
CheckTomcatMemory(){
	LogInfo "Checking tomcat allocated memory"	
		
	mbMemory=$(grep "X1024mx" $CATALINA_HOME/bin/catalina.sh)
	
	if [ -z $mbMemory ]; then	

		gbMemory=$(grep "Xmx.*\g" $CATALINA_HOME/bin/catalina.sh)
		
		if [ -z $gbMemory ]; then
			LogInfo "Tomcat memory may be below the recommended amount"
			echo "For best performance increase memory to atleast 1GB"
		
		else
			LogInfo "Tomcat memory meets or excedes recommended amount"		
		fi
	
	else		
		LogInfo "Tomcat memory meets recommended amount"
	fi
}


VerifyAntInstallation(){
	LogInfo "Verifying ant is installed"
	
	if [ -z $ANT_HOME ]; then
		LogInfo "ANT_HOME has not been set"
		echo "Script will exit"		
		exit -1
	else
		if [ -d $ANT_HOME ]; then
			echo "Ant has been installed on the machine"
		else
			LogInfo "ANT_HOME is not pointing to the correct directory"
			echo "Script will exit"
			exit -1
		fi
	fi
}


#VerifyFolderCreated(){
#	error=$(mkdir $1 2>&1)

#	echo $error

#	if [ -z $error ]; then
#		echo "$1 created successfully"
#	else
#		echo "Could not create folder"
#		echo "Script will exit, see log file for more detail"
#		LogInfo $error
#		exit -1
#	fi
#}

#VerifyFileCreated(){
#	error=$(mk $1 2>&1)

#	echo $error

#	if [ -z $error ]; then
#		echo "$1 created successfully"
#	else
#		echo "Could not create file"
#		echo "Script will exit, see log file for more detail"
#		LogInfo $error
#		exit -1
#	fi
#}


#Get inetconfigfile path from user. Validate path, loop until path exists
GetInetSoftPath(){
	doesInetSoftPathExist="false"

	while [ $doesInetSoftPathExist = "false" ]; do
	
		echo "Enter path where the Inetsoft config file will be stored"
		read inetsoftConfigPath		

		if [ -d $inetsoftConfigPath ]; then
			doesInetSoftPathExist="true"

			echo "$inetsoftConfigPath exist"
			LogInfo "The user provided path $inetsoftConfigPath already exists"			
		else
			validResponse="false"
			while [ $validResponse = "false" ]; do
				echo "The following path could not be found: "$inetsoftConfigPath""	
				echo "Would you like to create it? (Y/N)"
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
						echo "Invalid character";;
				esac		
			done
		
			if [ $createFolder = 'Y' ]; then
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
	 	echo "There was an error performing this action"
		echo "Script will exit, see log file for details"
		LogInfo $1
		exit -1		
	fi
}


#Uses the current directory to find build.xml and set tomcat.home and spree.home values
SetBuildXMLConfig(){
	LogInfo "Updating build xml file"
	
	buildXMLPath=""$currentDir"/reporting/build.xml"
	buildXMLCopyPath=""$currentDir"/reporting/buildOriginal.xml"

	LogInfo "Creating backup copy of build.xml"
	
	error=$(cp $buildXMLPath $buildXMLCopyPath 2>&1)

	ValidateAction $error

	LogInfo "Injecting path to tomcat into build.xml"	
	
	#sets property name="tomcat.home" in build.xml file	   
	error=$(sed -i 's,/opt/apache-tomcat-7.0.47,'$CATALINA_HOME',g' $buildXMLPath 2>&1)
	
	ValidateAction "$error"

	LogInfo "Injecting path to InetSoftConfig into build.xml"	

	#sets property name="sree.home" in build.xml file         
	error=$(sed -i 's,/opt/InetsoftConfig,'$inetsoftConfigPath',g' $buildXMLPath 2>&1)
	
	ValidateAction "$error"
}

#sets property name="sree.home" in web.xml file
SetWebXMLConfig(){
	LogInfo "Updating web xml file"
	
	webXMLPath=""$currentDir"/reporting/web/WEB-INF/web.xml"
	webXMLCopyPath=""$currentDir"/reporting/web/WEB-INF/webOriginal.xml"
	
	LogInfo "Creating backup copy of build.xml"	
	
	error=$(cp $webXMLPath $webXMLCopyPath 2>&1)

	ValidateAction "$error"	

	LogInfo="Injecting path to InetSoftConfig into web.xml"
	
	error=$(sed -i 's,/opt/InetsoftConfig,'$inetsoftConfigPath',g' $webXMLPath 2>&1)
	ValidateAction "$error"
}

#If Inetsoftconfig folder exists, user is asked if it should be overwrriten.
#If so the InetsoftConfig package is copied to the user specified directory
CopyInetSoftConfig(){
	LogInfo "Copying inetsoftconfig folder to $inetsoftConfigPath"
	
	
	if [ -d "$inetsoftConfigPath/InetsoftConfig" ]; then
			validResponse="false"
			while [ $validResponse = "false" ]; do
	
			echo "Should the folder content be overwitten? (Y/N)"
			read overWriteInetSoft
	
			overWriteInetSoft=$(echo "$overWriteInetSoft" | tr '[:lower:]' '[:upper:]')
	
			case $overWriteInetSoft in
				
				[yY])
					LogInfo "Overwriting InetSoftConfig"		
					
					inetSoftsourcePath="$currentDir/InetsoftConfig"
					inetSoftdestinationPath="$inetsoftConfigPath"
					error=$(cp -r $inetSoftsourcePath $inetsoftConfigPath 2>&1)
					ValidateAction "$error"
					validResponse="true"
					
					;;
				[nN])			
					LogInfo "The InetSoftConfig directory will not be replaced"
					validResponse="true"
					;;
				*)
					echo "Invalid character";;
			esac	
		done
	else
		LogInfo "	Copying InetSoftConfig to $inetSoftdestinationPath"		
			
		inetSoftsourcePath="$currentDir/InetsoftConfig"
		inetSoftdestinationPath=$inetsoftConfigPath

		error=$(cp -r $inetSoftsourcePath $inetSoftdestinationPath 2>&1)
		ValidateAction "$error"
	fi
}

#Deploys ant build
DeployAnt(){
	LogInfo "Deploying ant build"
	
	cd $currentDir/reporting
	ant deploy #>> $logFile
}

VerifyReportingWarExists(){
	LogInfo "Verifying reporting.war file exists"
	
	reportingWarFile="$CATALINA_HOME/webapps/reporting.war"

	if [ -a "$reportingWarFile" ]; then
		LogInfo "Reporting war file deployed successfully"
	else
		LogInfo "reporting.war could not be found. InetSoft reporting failed to deploy correctly"
		echo "	Script will exit"
		ResetOriginalXmlFiles
		exit -1
	fi
}
	
GetIPAddress(){		
	LogInfo "Getting machine's IP address"		

	ipaddress=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' 2>&1)
	
	LogInfo "Machine ipaddress: $ipaddress"
}

ValidatePortStatus(){
	#checks to make sure there is at least 1 open port 
	if [ ${#openPortArray[@]} = 0 ]; then
		LogInfo "Tomcat has no open ports"
		echo "Configure tomcat and restart script"
		echo "Installer will exit"
		ResetOriginalXmlFiles
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
			LogInfo "$tomcatPort is an invalid port"			
		fi
	done	
}

GetPort(){
	LogInfo "Loading ports used by tomcat"	

	#Gets all possible ports from tomcat server.xml separated by spaces
	tomcatPortsList=$(grep -w "Connector port" $CATALINA_HOME/conf/server.xml | cut -d '"' -f2)
	
	#Tests each port to see if it's open. 
	#If tomcat has multiple ports they are stored in an array
	echo "Checking port status"
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
		
			echo "Enter the port you would like to use from the list above"
			read tomcatPort

			ValidateUserPortNumber		
		done
	fi
}

#Formats url
GetReportingURL(){
	LogInfo "Creating reporting URL"	
	hostName=$(hostname)

	reportingUrl=("http://$hostName:$tomcatPort/reporting/Reports")

	LogInfo "Reporting URL: $reportingUrl"
	echo "Save this URL, it will be required during the OTP desktop installation"	
}

PingReportingURL(){
	LogInfo "Testing reporting URL"

	pingURL=$(curl -ls "$reportingUrl?op=ping")
	
	if [ "$pingURL" = "ok" ]; then
		echo "Reporting URL test successful"	
	else
		echo "Reporing URL test failed"
	fi
}

#Overwrites edited copies of build.xml and web.xml
ResetOriginalXmlFiles(){
	error=$(cp $webXMLCopyPath $webXMLPath 2>&1)
	ValidateAction "$error"

	error=$(cp $buildXMLCopyPath $buildXMLPath  2>&1)
	ValidateAction "$error"
	
	error=$(rm -f $webXMLCopyPath 2>&1)
	ValidateAction "$error"

	error=$(rm -f $buildXMLCopyPath	2>&1)
	ValidateAction "$error"
}

#Stops tomcat
StopTomcat(){
	LogInfo "Stopping tomcat"
	
	error=$( { $CATALINA_HOME/bin/shutdown.sh >> $logFile; } 2>&1 )
	
	if [ -z "$error" ]; then
		return
	else				
		echo "Tomcat is either not running or could not be stopped"
	
	fi
}

#Starts tomcat. At times the script would check for open ports before 
#tomcat could start so we sleep for 5 seconds.
StartTomcat(){
	LogInfo "Starting tomcat"
	error=$( { $CATALINA_HOME/bin/startup.sh >> $logFile; } 2>&1 )
	
	sleep 5	
	
	if [ -z "$error" ]; then
		return
	else				
		echo "Tomcat is either already running or could not be started."
	
	fi
}

#Function calls
GetExecutingDirectory
CreateLogFile
#VerifyUserIsRoot
VerifyJavaInstallation
VerifyJavaVersion
VerifyTomcatInstallation
VerifyTomcatVersion
CheckTomcatMemory
VerifyAntInstallation
StopTomcat
GetInetSoftPath
SetBuildXMLConfig
SetWebXMLConfig
CopyInetSoftConfig
DeployAnt
VerifyReportingWarExists
ResetOriginalXmlFiles
StartTomcat
GetIPAddress
GetPort
CheckOpenPorts
GetReportingURL
PingReportingURL

