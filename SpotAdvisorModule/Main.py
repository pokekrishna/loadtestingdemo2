import traceback
import os
from ExtractInstancesName import ExtractInstancesName
from UserChoice import UserChoice
from AveragePriceCalculator import AveragePriceCalculator
from datetime import datetime, timedelta
from ExtractOnDemandPrice import ExtractOnDemandPrice
import sys
import boto3


def getOnDemandPriceThread():
    try:
        print "Extracting on demand price of all instances\n"
        extract_on_demand_price = ExtractOnDemandPrice()
        extract_on_demand_price.start()
        return extract_on_demand_price
    except:
        print "error in spawning on demand price thrad"
        traceback.print_exc(file=sys.stdout)

on_demand_price_thread_object = getOnDemandPriceThread()
# Variables
config_file = os.path.join(os.path.dirname(__file__), "user_input.ini"

                           )
config_file_section = "SPOT_INSTANCES_FAMILY"
time_delta=4

# todo refactor this main class to make it the entry point in a right way

# operation on instance extraction
extract_instance_name = ExtractInstancesName (config_file, config_file_section)
extract_instance_name.parseConfigFile()
instances_list = extract_instance_name.getInstances()

# print all the instances in ascending order.
# provide user choice to select the instance



user_finalized=False

while not user_finalized:

    user_choice = UserChoice(instances_list)
    slave_instance_type = user_choice.getChoice("Enter your choice of instance for JMeter slaves: ")


    # get the current price of instance in all the az in the region mentioned in aws credentials
    # where the price is lowest,
    current_time = datetime.utcnow()
    time_four_hours_back = current_time - timedelta(hours=time_delta)


    average_price_calculator = AveragePriceCalculator(slave_instance_type, time_four_hours_back, current_time)
    print "Extracting availability zones for the region"
    availability_zones = average_price_calculator.getAvailabilityZones()
    thread_object_list = []
    print "Extracting data for ", slave_instance_type
    for availability_zone in availability_zones:
        try:
            # instantiate
            thread_object_list.append(AveragePriceCalculator(slave_instance_type,time_four_hours_back, current_time))

            # assign AZ
            thread_object_list[len(thread_object_list)-1].availability_zone = availability_zone
            # print thread_object_list[len(thread_object_list)-1].availability_zone

            # fire the thread
            thread_object_list[len(thread_object_list) - 1].start()

        except:
            print '-' * 60
            traceback.print_exc(file=sys.stdout)
            print '-' * 60

    for thread_object in thread_object_list:
        thread_object.join()


    # print AveragePriceCalculator.current_spot_prices_per_region
    # print AveragePriceCalculator.average_spot_prices_per_region
    print("AvailZone%sCurrentSpotPrice\tAverage Spot Price In Last %d hours" % ("\t"*1, time_delta))
    for availability_zone in sorted(AveragePriceCalculator.current_spot_prices_per_region):
        # us-east-1a
        print ("%s\t%5.5f%s%5.5f" % (availability_zone, AveragePriceCalculator.current_spot_prices_per_region[availability_zone],"\t"*4 ,AveragePriceCalculator.average_spot_prices_per_region[availability_zone]))

    # print "back to main thread"

    while True:
        try:
            user_finalized = True if str(raw_input("Do you want to re-try? (y/n): ").lower()) == 'n' else False
            break
        except:
            user_finalized = False

def decideInstance():
    print "\nFinalize the instance"
    user_instance_choice = UserChoice(instances_list)
    slave_instance_type = user_instance_choice.getChoice("Enter your final choice: ")


    user_az_choice = UserChoice(availability_zones)
    final_az = user_az_choice.getChoice("Enter your choice of az: ")

    my_session = boto3.session.Session()
    on_demand_price_thread_object.join()



    file_body = slave_instance_type+" "+final_az+" "+on_demand_price_thread_object.getInstanceInfo(instance_type=slave_instance_type, region=my_session.region_name)
    #write to a file
    file = open("slave_spot_instance_type", "wb")

    file.write(file_body)

    file.close()

decideInstance()

