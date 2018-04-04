# Design: testbench.py
# Description:
# Author: German Cano Quiveu <germancq@dte.us.es>
# Copyright Universidad de Sevilla, Spain

import os
import sys
import time
import numpy
import client_


measures = []
transmission_with_errors = []
def main():
	for k in range (0, int(sys.argv[1])):
		print('execution instance %i',k)
		start = time.time()
		if(k%2 == 0):
			#os.system('python3 client_.py pAA.HEX')
			client_.maintask('pAA.HEX')
			print ('test A')
		else:
			#os.system('python3 client_.py pBB.HEX')
			client_.maintask('pBB.HEX')
			print ('test B')

		if len(client_.error_packets) > 0:
			transmission_with_errors.append(k)

		end = time.time()
		total = end - start
		print('time execution = %i',total)
		measures.append(total)
		print('average time is %i',numpy.average(measures))
		time.sleep(1)

	print(transmission_with_errors)


if __name__ == "__main__":
    main()
