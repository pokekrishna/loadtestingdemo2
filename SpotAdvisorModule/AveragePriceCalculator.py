import threading
import boto3
import traceback
import sys
class AveragePriceCalculator (threading.Thread) :

    # take the instance name
    # take start date and end date
    # region  is taken automcatically from ~/.aws/
    # get the names of AZs
    # fire separate threads for all AZs and get the average price

    # get current price AZ
    average_spot_prices_per_region = {}
    current_spot_prices_per_region = {}
    availability_zone = ""

    def __init__(self, instance_type, start_time, end_time):
        threading.Thread.__init__(self)
        self.instance_type = instance_type
        self.start_time = start_time
        self.end_time = end_time
        self.client= boto3.client('ec2')



    def run(self):
        self.getAveragePricePerAvailabilityZone(self.instance_type, self.availability_zone, self.start_time,
                                                    self.end_time)


    def getAvailabilityZones(self):
        # list to hold all the availability zones under the region
        availability_zones=[]

        response = self.client.describe_availability_zones(
            DryRun= False
        )

        # prepare a list of only azs
        for availability_zone_info in response['AvailabilityZones']:
            if availability_zone_info['State'] == 'available':
                availability_zones.append(availability_zone_info['ZoneName'])
        return availability_zones


    def getAveragePricePerAvailabilityZone(self, instance_type, availability_zone, start_time, stop_time):
        need_to_get_current_spot_price = True

        response = {"NextToken": ""}

        price_total = 0;
        number_of_price_changes = 0;

        type (instance_type)
        while True:
            response = self.client.describe_spot_price_history(
                DryRun=False,
                # start time = 4 hours back from current time
                StartTime=start_time,

                # end time = current time
                EndTime=stop_time,

                InstanceTypes=[
                    str(instance_type)
                ],
                ProductDescriptions=[
                    'Linux/UNIX',
                ],
                AvailabilityZone=str(availability_zone),
                NextToken=response['NextToken']
            )





            #adding total price
            for price_info in response["SpotPriceHistory"]:
                price_total += float(price_info['SpotPrice'])

                # finding current spot price per az
                if need_to_get_current_spot_price:
                    AveragePriceCalculator.current_spot_prices_per_region.update({availability_zone:price_total})
                    need_to_get_current_spot_price=False

            number_of_price_changes += len (response['SpotPriceHistory'])

            if response['NextToken'] is '':
                break
        try:
            AveragePriceCalculator.average_spot_prices_per_region.update({availability_zone:(price_total/number_of_price_changes)})
        except:
            print "Exception while calculating average price. Details below"
            print "availability_zone: ", availability_zone
            print "price_total: ", price_total
            print "number_of_price_changes: ", number_of_price_changes
