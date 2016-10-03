#!/bin/bash
PROJECT=testidgpfxlgdq;BUCKET_INSTALL=LoadTesting_testidgpfxlgdq;BUCKET_RESULT=LoadTestingResults_testidgpfxlgdq;
Region=us-east-1;Output=text;

############# PASSED AS USER DATA TO JMETER MASTER SERVER TO INSTALL JMETER & AWSCLI AND DOWNLOAD ALL FILES FROM S3

sudo apt-get update
sudo apt-get install openjdk-7-jdk --fix-missing -yy

#install jmeter and ant
sudo apt-get install jmeter -y
sudo apt-get install ant -y
sudo apt-get install python-pip -y; sudo pip install --upgrade awscli;

#remove loopback address from jmeter.properties
sudo sed -i 's/remote_hosts=127/#remote_hosts=127/' /usr/share/jmeter/bin/jmeter.properties

sudo chown -R ubuntu:ubuntu /usr/share/jmeter/
sudo mkdir /usr/share/jmeter/extras

wget https://s3.amazonaws.com/$BUCKET_INSTALL/conversion.xml -O /usr/share/jmeter/extras/conversion.xml
wget https://s3.amazonaws.com/$BUCKET_INSTALL/jmeter-results-detail-report_21.xsl -O /usr/share/jmeter/extras/jmeter-results-detail-report_21.xsl
wget https://s3.amazonaws.com/$BUCKET_INSTALL/File.jmx -O /usr/share/jmeter/extras/File.jmx
wget https://s3.amazonaws.com/$BUCKET_INSTALL/configJMeterSlave.sh -O /usr/share/jmeter/extras/configJMeterSlave.sh
wget https://s3.amazonaws.com/$BUCKET_INSTALL/createSlave.sh -O /usr/share/jmeter/extras/createSlave.sh
wget https://s3.amazonaws.com/$BUCKET_INSTALL/EC2instanceproperties.sh -O /usr/share/jmeter/extras/EC2instanceproperties.sh
wget https://s3.amazonaws.com/$BUCKET_INSTALL/JMetertestproperties.sh -O /usr/share/jmeter/extras/JMetertestproperties.sh
wget https://s3.amazonaws.com/$BUCKET_INSTALL/JMeterMasterRunTest.sh -O /usr/share/jmeter/extras/JMeterMasterRunTest.sh

source /usr/share/jmeter/extras/EC2instanceproperties.sh
source /usr/share/jmeter/extras/JMetertestproperties.sh
mkdir /home/ubuntu/.aws
chown -R ubuntu:ubuntu /home/ubuntu/.aws
> ~/.aws/config
cat<<here >> /home/ubuntu/.aws/config
[default]
region=$Region
output=$Output
here

