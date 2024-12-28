import cocotb
import cocotb.clock
import random
import cocotb.handle
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.clock import Clock

def to7bin(x):
    y = []
    for i in range(7):
        y.append(int((f"{x:07b}")[i]))
    return y

def to16bin(x):
    y = []
    for i in (f"{x:016b}"):
        y.append(int(i))
    return y

class dumy_slave:
    def __init__(self, dut):
        self.clk = dut.clk
        self.sclk = dut.sclk
        self.reset_n = dut.reset_n
        self.sdi = dut.sdi
        self.sdo = dut.sdo
        self.csz = dut.csz


class customClock:
    def __init__(self, pin, period):    #period in sec
        self.pin = pin
        self.period = period

    # Genrator function of clock
    async def clockGenrater(self, startWith):
        while True:
            self.pin.value = startWith
            await Timer(1e9*self.period/2, units="ns")
            self.pin.value = 1 - startWith
            await Timer(1e9*self.period/2, units="ns")

    # Function to start the clock with high/low
    async def On(self, startWith):    
        self.task = cocotb.create_task(self.clockGenrater(startWith))
        await cocotb.start(self.task)
    
    # Function to stop the clk genration with a stable high/low
    async def Off(self, value):        
        self.task.cancel()
        self.pin.value = value


class create_master:
    def __init__(self, slave, clk_freq):
        self.slave = dumy_slave(slave)
        self.slave.sclk.value = 1
        self.clk_freq = clk_freq
    
    async def operate(self, slave_address, rwb, slave_data=0):
        # Select the chip
        self.slave.csz.value = 0

        # Set master clock and turn it ON
        master_clk = customClock(self.slave.sclk, 1/self.clk_freq)
        await master_clk.On(1)  
        await FallingEdge(self.slave.sclk)

        # Cahnge the address to binary array to send bit by bit
        for i in to7bin(slave_address):
            self.slave.sdi.value = i
            await FallingEdge(self.slave.sclk)
        
        # Pass the read/write signal
        self.slave.sdi.value = 1 if rwb else 0
        await FallingEdge(self.slave.sclk)
        
        # Brach for wither READ or WRITE
        if rwb == 0 :
            for i in to16bin(slave_data):
                self.slave.sdi.value = i
                await FallingEdge(self.slave.sclk)

            # Set the sdi to 1 for no further opration
            self.slave.sdi.value = 1
            # Turn off the master clk
            await master_clk.Off(1)
            await Timer(0.5*1e9/self.clk_freq, "ns")
            # Deselect the slave
            self.slave.csz.value = 1
            await Timer(1e9/self.clk_freq, "ns")
        else :
            received_data = 0
            for i in range(16):
                received_data = received_data << 1
                received_data += int(self.slave.sdo.value)
                await FallingEdge(self.slave.sclk)
            
            # Turn off the master clk
            await master_clk.Off(1)
            await Timer(0.5*1e9/self.clk_freq, "ns")
            # Deselect the slave
            self.slave.csz.value = 1
            await Timer(1e9/self.clk_freq, "ns")

            return received_data
        
    async def check_read_write_at(self, slave_address, data=0xF0F7):
        await self.operate(slave_address, rwb = 0, slave_data = data)
        assert (await self.operate(slave_address, rwb = 1)) == data, f"Read/Write Fail for ADD:0x{slave_address:02x} & DATA:0x{data:04x}"


slave_period = 250      #ns
master_period = 10000   #ns

# Init function to set the master and slave period and POWER ON RESET
async def init_slave(dut):
    global slave_period, master_period
    slave = dumy_slave(dut)
    slave.csz.value = 1
    slave.sdi.value = 1
    slave.reset_n.value = 0

    master = create_master(slave, clk_freq=1e9/master_period)
    slave_clk = Clock(slave.clk, slave_period, "ns")
    await cocotb.start(slave_clk.start())

    # PO-Reset --------------------------------------------------
    slave.reset_n.value = 1
    await Timer(0.75*slave_period, "ns")
    slave.reset_n.value = 0
    await Timer(slave_period, "ns")
    slave.reset_n.value = 1
    await Timer(slave_period, "ns")

    return master

# To test user defined ADD & DATA
@cocotb.test()
async def master_read_write(dut):
    master = (await init_slave(dut))

    # await master.operate(slave_address=0x01, rwb = 0, slave_data = 0x0800)
    # assert (await master.operate(slave_address=0x01, rwb = 1)) == 0x0800, f"Read Fail"
    
    await master.check_read_write_at(slave_address=0x01, data=0x0001)
    await master.check_read_write_at(slave_address=0x37, data=0x8000)
    await master.check_read_write_at(slave_address=0x7F, data=0x7FFC)
    await master.check_read_write_at(slave_address=0x02, data=0xFAE9)
    await Timer(10, units="us")


# To write and read random 100 data
@cocotb.test()
async def Random_data(dut):
    master = (await init_slave(dut))

    for i in range(100):
        data = random.randint(0x0000, 0xFFFF)
        await master.check_read_write_at(slave_address=0x58, data=data)

    await Timer(1, units="us")


# To check all the possible address
@cocotb.test()
async def All_address(dut):
    master = (await init_slave(dut))

    for address in range(128):
        await master.check_read_write_at(slave_address=address, data=0x70F9)

    await Timer(1, units="us")
