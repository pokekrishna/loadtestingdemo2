class UserChoice:

    # instances --> list of instances
    def __init__(self, instances_list):
        self.instances_list  = instances_list


    def getChoice(self, message):


        # # create a single list
        # for instance_family in self.instances:
        #     self.instances_list.extend(self.instances[instance_family])


        while True:
            choice = 1
            for instance in self.instances_list:
                print ("%d.\t%s" % (choice, instance))
                choice +=1
            choice =  raw_input(message)



            # validate choice
            if self.validateInput(choice, 1, len(self.instances_list)):
                # return choice
                return self.instances_list[int(choice)-1]
                break
            else:
                pass

    def validateInput(self, input, lower_limit, upper_limit):
        #validate if input is an integer
        try:
            input = int(input)
        except ValueError:
            print ("Not an integer value.")
            # data is not integer, return false
            return False

        # input is integr. move ahead and check the limit.
        if lower_limit <= input <= upper_limit:
            return True
        else:
            return False

