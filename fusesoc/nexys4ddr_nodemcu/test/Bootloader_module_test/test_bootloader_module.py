import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure
from cocotb.clock import Clock
from cocotb.binary import BinaryValue

CLK_PERIOD = 20 #50Mhz
DATA_LENGTH = BinaryValue(512,32)
N_BLOCK = [BinaryValue(10,8),BinaryValue(11,8),BinaryValue(12,8),BinaryValue(13,8)]
DATA = []


def setup_dut(dut):
    dut.i_spi_done = 0
    dut.i_spi_comm = 0
    dut.i_spi_start = 0
    dut.i_spi_eof = 0
    cocotb.fork(Clock(dut.clk, CLK_PERIOD).start())

def setup_data():
    for i in range(0,512):
        DATA.append(BinaryValue(i%32,8))

@cocotb.coroutine
def start_fsm(dut):
    dut.i_spi_start = 1
    while check_state(dut, dut.IDLE) :
        yield Timer(CLK_PERIOD)
    dut.i_spi_start = 0
    if not check_state(dut, dut.IDLE_BLOCK):
        raise TestFailure("State Machine incorrect state is %s",str(dut.current_state))

@cocotb.coroutine
def n_block(dut):
    dut.i_spi_comm = 1
    yield Timer(CLK_PERIOD)
    dut.i_spi_comm = 0
    yield send_word(dut,N_BLOCK)

    while not check_state(dut, dut.IDLE_TOTAL_BYTES) :
        yield Timer(CLK_PERIOD)
    yield Timer(CLK_PERIOD * 10)
    if not check_state(dut, dut.IDLE_TOTAL_BYTES):
        raise TestFailure("State Machine incorrect IDLE_TOTAL_BYTES state is : %s", str(dut.current_state))
    n_block_str = str(N_BLOCK[0])+str(N_BLOCK[1])+str(N_BLOCK[2])+str(N_BLOCK[3])
    if str(dut.reg_block_bumber) != n_block_str :
        raise TestFailure("N_BLOCK error value is %s and N_BLOCK is: %s",str(dut.reg_block_bumber),n_block_str)


@cocotb.coroutine
def send_word(dut,word_value):
    for i in range(0,4):
        yield send_byte(dut,N_BLOCK[i])

@cocotb.coroutine
def send_byte(dut, byte_value):
    dut.i_spi_data = byte_value
    while not check_state(dut, dut.READ_BYTE) :
        yield Timer(CLK_PERIOD)
    if not check_state(dut, dut.READ_BYTE):
        raise TestFailure("State Machine incorrect READ BYTE state is: %s", str(dut.current_state))
    while check_state(dut, dut.READ_BYTE) :
        dut.i_spi_done = 1
        yield Timer(CLK_PERIOD)
    dut.i_spi_done = 0
    yield Timer(CLK_PERIOD)

def check_state(dut, state):
    if str(dut.current_state) == str(state) :
        return True
    else :
        return False

@cocotb.coroutine
def reset(dut):
    dut.reset = 1
    yield Timer(CLK_PERIOD*20)
    dut.reset = 0
    if not check_state(dut, dut.IDLE):
        raise TestFailure("State Machine incorrect AFTER RESET state is %s",str(dut.current_state))

@cocotb.test()
def test_boot(dut):

    setup_data()
    yield reset(dut)
    setup_dut(dut)
    #start FSM
    yield start_fsm(dut)
    yield n_block(dut)
