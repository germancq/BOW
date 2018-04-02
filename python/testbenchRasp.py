# Design: testbenchRasp.py
# Description:
# Author: German Cano Quiveu <germancq@dte.us.es>
# Copyright Universidad de Sevilla, Spain
# test for running on Raspberry pi 3
import os
import sys
import time
import numpy
import RPi.GPIO as GPIO
import client_

measures = []
failures = []
pinout_list = [31,32,33,35,36,37,38,40]
transmission_with_errors = []

def main():
    setupGPIO()
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
        #check led values from FPGA
        checkGPIO(k)

    print(failures)
    print(transmission_with_errors)
    GPIO.cleanup()

def setupGPIO():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)
    GPIO.setup(pinout_list, GPIO.IN)


def checkGPIO(k):
    value_leds=[]
    testA = [1,0,1,0,1,0,1,0]
    testB = [1,0,1,1,1,0,1,1]
    for i in pinout_list:
        value_leds.insert(0,GPIO.input(i))

    if(k%2 == 0):
        if value_leds != testA :
            failures.append(k)
            print ('Error')
    else:
        if value_leds != testB :
            failures.append(k)
            print ('Error')


if __name__ == "__main__":
    main()
