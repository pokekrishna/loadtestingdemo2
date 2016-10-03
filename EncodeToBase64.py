import base64
from sys import argv
inputFileName = argv[1]
#outputFileName = argv[2]
f = open(inputFileName)
stringToEncode = f.read()
encoded = base64.b64encode(stringToEncode)
#f = open(outputFileName, 'a')
#writeBuffer = "base64_" + argv[3] + "=" + encoded + "\n"
#f.write(writeBuffer)
#f.close()

print encoded
