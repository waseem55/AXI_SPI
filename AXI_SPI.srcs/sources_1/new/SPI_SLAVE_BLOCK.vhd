library ieee;
use ieee.std_logic_1164.all;

entity Slave_Block is
	generic(
	C_NUM_TRANSFER_BITS	: integer := 8
	);
	
	port ( S_AXI_ACLK: std_logic;
			SCK_I: in std_logic;--input clock from master
			RESETN: std_logic;
			
			--Lines for communicating with TX_FIFO
			TX_Valid: in std_logic;
			TX_DATA_IN: in std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
			
			
			--MOSI/MISO serial data lines
			MOSI_I: in std_logic;
			MISO_O: out std_logic;
			
			--tri-state buffer enable 
			MISO_T: out std_logic;
			
			--Lines for communicating with RX_FIFO
			RX_DATA_OUT: out std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
			
			--read_enable for TX FIFO
			read_enable: out std_logic;
			
			--write_enable for RX_FIFO
			write_enable: out std_logic;
			
			--control bits
			SPISEL: in std_logic;
			SPE: in std_logic;
			LSB_MSB: in std_logic;
			master_or_slave: in std_logic
					
);
	
end Slave_Block;

architecture same_communication of Slave_Block is

type state_type is (idle,get_transmit_data, reset_enable,read_data, hold_till_buffer_empty); --state machine
signal state : state_type;

type state_type_two is (idle,enable, disable); --state machine
signal state_two : state_type_two;

signal TX_BUFFER: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal TX_COUNT_MSB: integer;
signal TX_COUNT_LSB: integer;
signal RX_BUFFER: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal RX_COUNT_MSB: integer;
signal RX_COUNT_LSB: integer;
signal SPI_CLK_FALLING_EDGES: integer;
signal SPI_CLK_RISING_EDGES: integer;
signal write_enable_latch: std_logic;
signal rx_data_out_latch: std_logic;
signal data_in_TX_Buffer: std_logic;
signal new_transaction: std_logic;


begin 
process(S_AXI_ACLK, RESETN)
begin 
if RESETN = '0' then 
read_enable<='0';
TX_BUFFER<=(others=>'0');
data_in_TX_Buffer<='0';
write_enable<='0';
elsif rising_edge(S_AXI_ACLK) then 
	case(state) is 
		when idle => 
			if RESETN = '0' then 
				
				TX_BUFFER<=(others=>'0');
				data_in_TX_Buffer<='0';
				write_enable<='0';
			elsif RESETN = '1' then 
				state<=get_transmit_data;
				data_in_TX_Buffer<='0';
				TX_BUFFER<=(others=>'0');
				write_enable<='0';
			end if;
			read_enable<='0';
		when get_transmit_data => 
			if SPI_CLK_FALLING_EDGES = C_NUM_TRANSFER_BITS and TX_VALID = '1' and SPE = '1' and master_or_slave = '0' then 
				read_enable<='1';
				state<=reset_enable;
				write_enable<='0';
			end if;
			data_in_TX_Buffer<='0';
			TX_BUFFER<=(others=>'0');
			write_enable<='0';
		when reset_enable => 
			read_enable<='0';
			state<=read_data;
			data_in_TX_Buffer<='0';
			TX_BUFFER<=(others=>'0');
			write_enable<='0';
		when read_data => 
			TX_BUFFER<=TX_DATA_IN;
			state<=hold_till_buffer_empty;
			data_in_TX_Buffer<='0';
			write_enable<='0';
		when hold_till_buffer_empty => 	
		    data_in_TX_Buffer<='1';
		    write_enable<='0';
			if SPI_CLK_FALLING_EDGES = 1 then 
				state <=idle;
				data_in_TX_Buffer<='0';
				TX_BUFFER<=(others=>'0');
				write_enable<='1';
				RX_DATA_OUT<=RX_BUFFER;
			end if;
			
	end case;

end if;
end process;

-- still need to implement sending zeros from TX_FIFO functionality 
process(SCK_I, RESETN, SPISEL)
begin --finished 
if SPISEL = '0' and SPI_CLK_RISING_EDGES = C_NUM_TRANSFER_BITS and  SPE='1' and master_or_slave = '0' and new_transaction = '0'  then 

	if LSB_MSB = '0' then 
		MISO_O<=TX_BUFFER(TX_COUNT_MSB);
		TX_COUNT_MSB<=TX_COUNT_MSB-1;
		new_transaction<='1';
	elsif LSB_MSB = '1' then 
		MISO_O<=TX_BUFFER(TX_COUNT_LSB);
		TX_COUNT_LSB<=TX_COUNT_LSB+1;
		new_transaction<='1';
	end if;
	
elsif SPISEL = '1' and SPI_CLK_RISING_EDGES = C_NUM_TRANSFER_BITS and  SPE='1' and master_or_slave = '0' and new_transaction = '1'  then
    new_transaction <='0';

end if;

if RESETN = '0' then 
TX_COUNT_MSB<=(C_NUM_TRANSFER_BITS-1);
TX_COUNT_LSB<=0;
SPI_CLK_FALLING_EDGES<=C_NUM_TRANSFER_BITS;
new_transaction <='0';
elsif falling_edge(SCK_I) and SPISEL='0' and SPE= '1' then 

		if LSB_MSB = '0' and SPI_CLK_FALLING_EDGES > 1 then 
		    SPI_CLK_FALLING_EDGES<=SPI_CLK_FALLING_EDGES-1;
			MISO_O<=TX_BUFFER(TX_COUNT_MSB); -- could probably just add another if statement in this part of the logic where it pulls from a zeroed buffer if necessary
			if TX_COUNT_MSB>0 then
				TX_COUNT_MSB<=TX_COUNT_MSB-1;
			end if;
		elsif LSB_MSB = '1' and SPI_CLK_FALLING_EDGES > 1 then 
		    SPI_CLK_FALLING_EDGES<=SPI_CLK_FALLING_EDGES-1;
			MISO_O<=TX_BUFFER(TX_COUNT_LSB);
			if TX_COUNT_LSB < (C_NUM_TRANSFER_BITS-1) then 
				TX_COUNT_LSB<=TX_COUNT_LSB+1;
			end if;
		end if;
		
		if SPI_CLK_FALLING_EDGES = 1 then 
			SPI_CLK_FALLING_EDGES<=C_NUM_TRANSFER_BITS;
			TX_COUNT_LSB<=0;
			TX_COUNT_MSB<=(C_NUM_TRANSFER_BITS-1);
		end if;
		
end if;

end process;

--finished 
process(SCK_I, RESETN)
begin 
if RESETN = '0' then 
RX_COUNT_MSB<=C_NUM_TRANSFER_BITS-1;
RX_COUNT_LSB<=0; 
SPI_CLK_RISING_EDGES<=C_NUM_TRANSFER_BITS;
RX_BUFFER<=(others=>'0');

elsif rising_edge(SCK_I) and SPISEL='0' and SPE='1' then 
	if SPI_CLK_RISING_EDGES > 0 then 
		if LSB_MSB = '0' then 
			RX_BUFFER(RX_COUNT_MSB)<=MOSI_I;
			
			if SPI_CLK_RISING_EDGES > 1 then 
				SPI_CLK_RISING_EDGES<=SPI_CLK_RISING_EDGES-1;
				RX_COUNT_MSB<=RX_COUNT_MSB-1;
			end if;
			
		elsif LSB_MSB = '1' then 
			RX_BUFFER(RX_COUNT_LSB)<=MOSI_I;
			
			if SPI_CLK_RISING_EDGES > 1 then 
				RX_COUNT_LSB<=RX_COUNT_LSB+1;
				SPI_CLK_RISING_EDGES<=SPI_CLK_RISING_EDGES-1;
			end if;
			
		end if;
	end if;

	if SPI_CLK_RISING_EDGES = 1 then 
		SPI_CLK_RISING_EDGES<=C_NUM_TRANSFER_BITS;
		RX_COUNT_MSB<=(C_NUM_TRANSFER_BITS-1);
		RX_COUNT_LSB<=0;
	end if;
	
end if;
end process;

end same_communication;

