#!/bin/bash

# Script to bundle an existing stopped EBS backed volume based off of the instance id.


if [ "$1" == "" -o "$2" == "" -o "$3" == "" ]
then
   echo "Usage: aws-bundle-image.sh <instance id> <image name> <image description>"
   echo "Example: aws-bundle-image.sh i-1234abcd jboss-template-2.2 \"Snapshot of Jboss Template\""
   echo ""
   echo "Note: <image name> cannot have spaces or special characters besides - or . "
   echo "Note: <image description> can have spaces, but must be enclodes in quotes "
   exit 1
fi


INSTANCE_ID="$1"
NAME="$2"
DESCRIPTION="$3"


VOLUME_ID=$(ec2-describe-instances $INSTANCE_ID | grep BLOCKDEVICE | awk '{print $3}')

SNAPSHOT_ID=$(ec2-create-snapshot $VOLUME_ID -d "$DESCRIPTION" | grep SNAPSHOT | awk '{print $2}')

while true
do
    STATUS=$(ec2-describe-snapshots $SNAPSHOT_ID | grep SNAPSHOT | awk '{print $4}' )

    if [ "$STATUS" == "completed" ]
    then
        break
    fi
    echo "`ec2-describe-snapshots $SNAPSHOT_ID`"
    sleep 5
done



AMI_ID=$(ec2-register -n "$NAME" -a x86_64 -d "$DESCRIPTION" --kernel aki-427d952b -s "$SNAPSHOT_ID" -b /dev/sdc=ephemer
al0 | grep IMAGE | awk '{print $2}' )

echo $AMI_ID
echo $AMI_ID > ~/server-information/.ami_id_last
