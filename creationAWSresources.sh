#!/bin/bash

######## TO CREATE VPC, IGW, ROUTE TABLE, SUBNET, SECURITY GROUP, KEYPAIR

source EC2instanceproperties.sh
source validator.sh --source-only


# run the spot advisor module 
python -u SpotAdvisorModule/Main.py

#output filename -> slave_spot_instance_type4
SPOT_ADVISOR_OUTPUT_FILE="slave_spot_instance_type"
InstanceType=`cut -d' ' -f1 ${SPOT_ADVISOR_OUTPUT_FILE}`
InstanceAZ=`cut -d' ' -f2 ${SPOT_ADVISOR_OUTPUT_FILE}`
OnDemandPrice=`cut -d' ' -f3 ${SPOT_ADVISOR_OUTPUT_FILE}`


while true; do 
	echo -ne "Create VPC (y/n)? "
	read create_VPC
	if `validateInput "^y$|^n$" $create_VPC `; then
		break
	else
		echo "Input seems inaccurate, please check."
	fi
done

if [ $create_VPC == 'y' ]
then
        
        while true; do
		    while true; do 
		    	echo -ne "Enter CIDR Block: "
		    	read cidr

		    	# Dont accept blank entry
		    	if `validateInput "." $cidr`; then
		    		break
		    	else
		    		echo "Input seems inaccurate, please check."
		    	fi
		    done

	        VPC=$(aws ec2 create-vpc --cidr-block $cidr | grep -o "vpc-[0-9,a-z,A-Z]*")
	        if [[ $? -eq 0 ]]; then
	        	break
	        fi
	    done


        aws ec2 create-tags --resources $VPC --tags Key=Name,Value=VPC_$PROJECT
        echo "VPC created, VpcId= "$VPC
		echo "Creating Internet Gateway!"
        IGW=`aws ec2 create-internet-gateway | grep -o "igw-[0-9,a-z,A-Z]*"`
        aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
        RTB=`aws ec2 create-route-table --vpc-id $VPC | grep -o "rtb-[0-9,a-z,A-Z]*"`
        echo "Done!"
else
	while true; do 
		echo -ne "Enter VpcID: "
		read VPC
		if `validateInput "." $`; then
			if `aws ec2 describe-vpcs --vpc-ids ${VPC} 2>/dev/null 1>/dev/null`; then
				break
			fi
		else
			echo "Input seems inaccurate, please check."
		fi
	done
	
fi

while true; do 
	echo -ne "Create Subnet (y/n)? "
	read create_subnet
	if `validateInput "^y$|^n$" $create_subnet`; then
		break
	else
		echo "Input seems inaccurate, please check."
	fi
done


if [ $create_subnet == 'y' ]
then
	while true; do
		echo -ne "Enter CIDR Block: "
	    read cidr
		Subnet=$(aws ec2 create-subnet --availability-zone $InstanceAZ --vpc-id $VPC --cidr-block $cidr | grep -o "subnet-[0-9,a-z,A-Z]*")
		if [[ $? -eq 0 ]]; then
			break
		fi

	done


	aws ec2 create-tags --resources $Subnet --tags Key=Name,Value=Subnet_$PROJECT
        echo "Subnet created, Subnet Id= "$Subnet
	aws ec2 associate-route-table --route-table-id $RTB --subnet-id $Subnet
	aws ec2 create-route --route-table-id $RTB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
	
else
    while true; do 
    	echo -ne "Enter SubnetId: "
    	read Subnet
    	if `validateInput "." $Subnet`; then
    		if `aws ec2 describe-subnets --subnet-ids ${Subnet} 2>/dev/null 1>/dev/null`; then
    			break
    		fi
    	else
    		echo "Input seems inaccurate, please check."
    	fi
    done    
    
fi


while true; do 
	echo -ne "Create Security Group (y/n)? "
	read create_sg

	if `validateInput "^y$|^n$" $create_sg`; then
		break
	else
		echo "Input seems inaccurate, please check."
	fi
done


if [ $create_sg == 'y' ]
then
	# create a security group
	
	while true; do
		echo -ne "Enter name of Security Group: "
		read SG
		SecurityGroup=$(aws ec2 create-security-group --group-name $SG --description "Load Testing Security Group" --vpc-id $VPC | grep -o "sg-[0-9,a-z,A-Z]*")
		if [[ $? -eq 0 ]]; then
			break
		fi
	done
	aws ec2 authorize-security-group-ingress --group-id $SecurityGroup --protocol tcp --port 80 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-id $SecurityGroup --protocol tcp --port 22 --cidr 0.0.0.0/0	
	echo "Security Group created, Security Group ID= "$SecurityGroup

	# getting the ID of the default security group 
	DefaultSecurityGroup=`aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC" --query "SecurityGroups[].[GroupName,GroupId]"  | tr -s ' ' ' ' | tr -s '\t' ' ' | egrep '^default ' | cut -d ' ' -f2`
else
	
	while true; do 
		# use the Security Group entered by the user 
		echo -ne "Enter Security Group Id: "
	    read SecurityGroup
		if `validateInput "." $SecurityGroup`; then
			if `aws ec2 describe-security-groups --group-ids $SecurityGroup 2>/dev/null 1>/dev/null`; then
				break
			fi
		else
			echo "Input seems inaccurate, please check."
		fi
	done


    # assign DefaultSecurityGroup as SecurityGroup.
    DefaultSecurityGroup=$SecurityGroup
fi

while true; do 
	echo -ne "Create Key Pair (y/n)? "
	read create_key

	if `validateInput "^y$|^n$" $create_key`; then
		break
	else
		echo "Input seems inaccurate, please check."
	fi
done

while true; do 
	echo -ne "Enter name of Key pair: "
	read KeyPairName

	if [ $create_key == 'y' ]
	then
		
		aws ec2 create-key-pair --key-name $KeyPairName --query 'KeyMaterial' --output text > ./$KeyPairName.pem

		#validating key creation
		if [[ $? -eq 0 ]]; then
			echo "Saved the key in "$KeyPairName".pem"
			chmod 400 ./$KeyPairName.pem
			break
		fi

	else
		aws ec2 describe-key-pairs --key-names ${KeyPairName}
		if [[ $? -eq 0 ]]; then
			break
		fi	
	fi
done

cat <<here >> EC2instanceproperties.sh
export VPC=$VPC
export Subnet=$Subnet
export SecurityGroup=$SecurityGroup
export DefaultSecurityGroup=$DefaultSecurityGroup
export KeyPairName=$KeyPairName
here








