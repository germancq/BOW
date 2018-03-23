# Design: client_.py
# Description: 
# Author: German Cano Quiveu <germancq@dte.us.es>
# Copyright Universidad de Sevilla, Spain

import os
import sys
import time
import numpy

#1) 10 test average time is 2.72589647769928
#2) 30 test average time is 2.7871941369155357
#2) 60 test average time is 2.752705925602024

measures = []
def main():		
	for k in range (0, int(sys.argv[1])):
		print('execution instance %i',k)
		start = time.time()
		if(k%2 == 0):
			os.system('python3 client_.py pAA.HEX')
			print ('test A')
		else:
			os.system('python3 client_.py pBB.HEX')
			print ('test B')
		end = time.time()		
		total = end - start
		print('time execution = %i',total)
		measures.append(total)
		print('average time is %i',numpy.average(measures))
		time.sleep(4)
	
	


if __name__ == "__main__":
    main()
