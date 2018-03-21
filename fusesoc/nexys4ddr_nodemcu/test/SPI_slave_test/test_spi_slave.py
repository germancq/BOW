import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure
from cocotb.clock import Clock


#SPI MODE 0
CLK_PERIOD = 10
TEST_VALUE = "11111010"
SCLK_PERIOD = 200

def setup_dut(dut):
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

@cocotb.test()
def test_read_byte(dut):
    dut.MOSI <= 0
    setup_dut(dut)
    #seleccionar CS
    dut.SSEL <= 0
    #enviar por MOSI
    yield send_byte(dut,TEST_VALUE)
    #terminar envio
    dut.SSEL <= 1

    yield Timer(SCLK_PERIOD)

    if dut.byte_received:
        if str(dut.byte_data_received) == TEST_VALUE:
            dut._log.info("Ok!")
        else:
            raise TestFailure("result is incorrect: %s" % str(dut.byte_data_received))
    else:
        raise TestFailure("byte received is not set")

@cocotb.coroutine
def send_byte(dut,byte_value):
    for i in range(0,8):
        #dut._log.info("for")
        yield send_bit(dut,byte_value[i])

@cocotb.coroutine
def send_bit(dut,bit_value):
    dut.SCK <= 0
    dut.MOSI <= int(bit_value)
    yield Timer(SCLK_PERIOD/2)
    dut.SCK <= 1
    yield Timer(SCLK_PERIOD/2)
