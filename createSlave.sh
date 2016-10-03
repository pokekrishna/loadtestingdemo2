#!/bin/bash
set -e

############## CALCULATES NO OF SLAVES REQD. AND CREATES SLAVES, WRITE ALL SLAVE IPs IN IP.txt

source /usr/share/jmeter/extras/EC2instanceproperties.sh
source /usr/share/jmeter/extras/JMetertestproperties.sh

users=$1

echo "---------------------------------------------------Creating Slaves!-------------------------------------------------------------------"
sleep 5

####calculate no of slaves needed => ceil(users/load)
num=`expr $users + $Load - 1`
SlavesNeeded=`expr $num / $Load`
sed -i '/export SlavesNeeded=/d' /usr/share/jmeter/extras/JMetertestproperties.sh
cat<<here >> /usr/share/jmeter/extras/JMetertestproperties.sh
export SlavesNeeded=$SlavesNeeded
here

> /usr/share/jmeter/extras/ip.txt
> /usr/share/jmeter/extras/RunningInstances.txt

#check no of already running slaves
aws ec2 describe-instances --filters "Name=tag:Name,Values=Slave_$PROJECT" "Name=instance-state-name,Values=running" --output json | grep PublicIpAddress | cut -d\" -f4 > /usr/share/jmeter/extras/RunningInstances.txt
Running=`cat /usr/share/jmeter/extras/RunningInstances.txt | wc -l`
if [ $Running -gt 0 ]
then
	cat /usr/share/jmeter/extras/RunningInstances.txt | while read LINE
	do
		echo $LINE"," > /usr/share/jmeter/extras/ip.txt
	done
fi

#calculate no of slaves to be newly created
count=`expr $SlavesNeeded - $Running`

#if any slave has to be created, then:
while [ $count > 0 ]
do

#InstanceID=$(aws ec2 run-instances --image-id $AMI --key-name $KeyPairName --security-group-ids $DefaultSecurityGroup --instance-type $InstanceType --subnet $Subnet --associate-public-ip-address --user-data file:///usr/share/jmeter/extras/configJMeterSlave.sh --output json | grep "InstanceId" | awk '{print $2}' | sed 's/\"//g' | sed 's/\,//g')

# encode the user data
InstanceID=""
ENCODED_USER_DATA=`cat /usr/share/jmeter/extras/configJMeterSlave.sh.sh | base64 -w0` 

RESPONSE=$(aws ec2 request-spot-instances --launch-group "$PROJECT" --spot-price "$OnDemandPrice" --instance-count 1 --type "one-time" --launch-specification "{\"ImageId\": \"$AMI\",  \"KeyName\": \"$KeyPairName\",  \"UserData\": \"$ENCODED_USER_DATA\",  \"InstanceType\": \"$InstanceType\",  \"Placement\": {    \"AvailabilityZone\": \"$InstanceAZ\"  },  \"NetworkInterfaces\": [    {      \"DeviceIndex\": 0,      \"SubnetId\": \"$Subnet\",      \"Groups\": [ \"$DefaultSecurityGroup\"],      \"AssociatePublicIpAddress\": true    }  ],  \"IamInstanceProfile\": {    \"Name\": \"LoadTesting-Instance-Profile\"  }}" --output json ) 


SPOT_REQUEST_ID=$(echo $RESPONSE | grep SpotInstanceRequestId | egrep -o 'sir-.*"' | sed 's/".*//')

echo "Spot Request Opened:" $SPOT_REQUEST_ID

# poll for request to get fullfilled
echo -ne "extracting instance id(s) "
while true; do
        SPOT_REQUEST_STATUS=`aws ec2 describe-spot-instance-requests --spot-instance-request-ids $SPOT_REQUEST_ID |  grep STATUS | cut -d$'\t' -f2`
        echo -ne "."
        # wait until request is fulfilled
        if [ $SPOT_REQUEST_STATUS == "fulfilled" ]
        then
               # extract the instance id
               InstanceID=`aws ec2 describe-spot-instance-requests --spot-instance-request-ids $SPOT_REQUEST_ID --query SpotInstanceRequests[*].{ID:InstanceId}`

                break
        fi
        sleep 0.7
done



sleep 20
aws ec2 create-tags --resource $InstanceID --tags Key=Name,Value=Slave_$PROJECT

# appending public ip of slaves to the file
#echo -ne `aws ec2 describe-instances --instance-id $InstanceID --output json | grep "PublicIpAddress" | awk '{print $2}' | sed 's/\"//g' | sed 's/\,//g'` >> /usr/share/jmeter/extras/ip.txt

# appending private ip of the slave to the file
echo -ne `aws ec2 describe-instances --instance-id $InstanceID --output json | grep "PrivateIpAddress" | head -1 | awk '{print $2}' | sed 's/\"//g' | sed 's/\,//g'` >> /usr/share/jmeter/extras/ip.txt

echo -ne "," >> /usr/share/jmeter/extras/ip.txt
count=`expr $count - 1`
done
