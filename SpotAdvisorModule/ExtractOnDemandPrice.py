import threading
import urllib2
import re
import json

class ExtractOnDemandPrice(threading.Thread):
    princing_only = {}

    def __init__(self):
        threading.Thread.__init__(self)

    def run(self):
        self.parseData()

    def jsToDict(self, url):
        jsonp_string = urllib2.urlopen(url).read()
        json_string = re.sub(r"(\w+):", r'"\1":', jsonp_string[jsonp_string.index('callback(') + 9: -2])
        pricing = json.loads(json_string)
        return pricing

    def parseData(self):
        pricing_urls = ['http://a0.awsstatic.com/pricing/1/ec2/previous-generation/linux-od.min.js',
                        'http://a0.awsstatic.com/pricing/1/ec2/linux-od.min.js']

        princing_only = {}
        for url in pricing_urls:
            dict_pricing = self.jsToDict(url)

            for region_wise_info in dict_pricing["config"]["regions"]:
                # print region_wise_info["region"]

                if not princing_only.get(region_wise_info["region"]):
                    princing_only.update({region_wise_info["region"]: {}})

                for instance_types in region_wise_info["instanceTypes"]:
                    for size_info in instance_types["sizes"]:
                        # print "%s\t%s" % (size_info["size"], size_info["valueColumns"][0]["prices"]["USD"])
                        princing_only[region_wise_info["region"]].update(
                            {size_info["size"]: size_info["valueColumns"][0]["prices"]["USD"]})

        ExtractOnDemandPrice.princing_only = princing_only


    def getInstanceInfo(self, instance_type, region):
        region_info_dict = ExtractOnDemandPrice.princing_only.get(region)
        return region_info_dict.get(instance_type)

