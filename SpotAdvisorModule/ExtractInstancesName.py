import configparser
class ExtractInstancesName:

    # empty dict for holding instance types


    def __init__(self, config_file_name, section_name):
        self.config_file_name = config_file_name
        self.section_name = section_name
        self.instances_list = []
        # call a function to read the file
        # read the

    def parseConfigFile(self):
        config = configparser.ConfigParser()
        config.read(self.config_file_name)

        # read the instance  with value yes and make a dictionary with empty values
        # values against the keys would be a list having all the instance types in that family
        # exampledict = {'m1' : ['m1.large', 'm1.xlarge'], 'm4' : ['m4.large', 'm4.xlarge']}

        for key in config[self.section_name]:
            if config[self.section_name][key] == "yes":
                self.instances_list.append(str(key))

    def showInstances(self):
        print (self.instances_list)

    def getInstances(self):
        return self.instances_list
