#!/bin/bash

########EXECUTED ON JMETER MASTER SERVER TO RUN ALL THE JMETER TESTS

source /usr/share/jmeter/extras/EC2instanceproperties.sh
source /usr/share/jmeter/extras/JMetertestproperties.sh

>slave.log
IFS=','
array=( $users )

########################## for each iteration
for i in ${array[@]}
do
>/usr/share/jmeter/extras/outputFile_$i.xml

#write name of output file in ant build file
sed -i '/<xslt/d' /usr/share/jmeter/extras/conversion.xml
sed -i '/<project/a <xslt in="/usr/share/jmeter/extras/outputFile_'$i'.xml" out="/usr/share/jmeter/extras/outputFile_'$i'.html"' /usr/share/jmeter/extras/conversion.xml

#create slaves
bash -x /usr/share/jmeter/extras/createSlave.sh $i | tee slave.log
echo "-----------------Please wait while Slaves are configured!--------------------"
sleep 300
source /usr/share/jmeter/extras/JMetertestproperties.sh

#read IP of all slaves
IPList=$(cat /usr/share/jmeter/extras/ip.txt  | tr -d '\n'  | sed 's/,$//' )

##############calculate no of users per slave=> ceil(user/slaves)
UsersPerSlave=$(expr $i / $SlavesNeeded)
R=$(expr $i % $SlavesNeeded)
if [ $R -ne 0 ]
then
	UsersPerSlave=$(expr $UsersPerSlave + 1)
fi

#run test
jmeter -n -t /usr/share/jmeter/extras/File.jmx -l /usr/share/jmeter/extras/outputFile_"$i".xml -R "$IPList" -Gusers=$UsersPerSlave;
ant -f /usr/share/jmeter/extras/conversion.xml

#copy result file to S3
aws s3 cp "/usr/share/jmeter/extras/outputFile_$i.html" s3://$BUCKET_RESULT/Result/$OutputFile"_"$i".html" --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers

#check for success threshold
Success=$(grep -o -m 1 '[0-9][0-9]*.[0-9][0-9]%' /usr/share/jmeter/extras/outputFile_$i.html | cut -d. -f1)
echo "No. of users: "$i
echo "Success Rate: "$Success
echo https://s3.amazonaws.com/$BUCKET_RESULT/Result/$OutputFile"_"$i".html"

if [ $Success -ge $Threshold ]
then
	echo "Executing next test"
else
	echo "Aborting!"
	break
fi
done
echo "-----------------------------------------FINISHED--------------------------------------------------------------"
aws s3 cp "/var/log/cloud-init-output.log" s3://$BUCKET_RESULT/Logs/jmeter_logs.log --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
aws s3 cp "slave.log" s3://$BUCKET_RESULT/Logs/slave.log --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers

#####terminating all slave instances
ID="`aws ec2 describe-instances --filters "Name=tag:Name,Values=Slave_$PROJECT" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text | tr -s '\n' ' '"
aws ec2 terminate-instances --instance-ids $ID
