
library ieee;
use ieee.std_logic_1164.all;

entity Master_Block is
	generic (C_NUM_TRANSFER_BITS: integer; -- sets expected number of bits in a transfer and size of shift register
			C_NUM_SS_BITS: integer); -- size of slave select output
	
	
	
	port (	
			-- system reset and clock
			S_AXI_ACLK: in std_logic; -- Master and slave coordinated to AXI system clock
			RESETN: in std_logic; -- system reset which is set by SRR reset or S_AXI_ARESETN
			
			
			--input data ports
			MISO_I: in std_logic; -- serial data in from MISO_I
			Data_In_Parallel: in std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); -- parallel data in from SPIDTR
			
			-- output data ports
			MOSI_O: out std_logic; -- serial data out to MOSI_O
			Data_Out_Parallel: out std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); -- parallel output to SPIDRR
			
			-- control inputs
			Master_or_Slave: in std_logic; -- SPICR bit signaling whether device is in master or slave mode
			Master_Inhibit: in std_logic; -- SPICR bit, inhibits master transactions
			LSB_or_MSB: in std_logic; -- SPICR bit controlling whether data is transmitted LSB or MSB first style
			SPE: in std_logic; -- SPI system enable bit from SPICR 
			Manual_Slave_Select: in std_logic; -- bit controlling whether a transaction happens in manual or automatic slave select mode
			
			-- Slave select register contents
			SSR: in std_logic_vector(31 downto 0);
			
			-- tri-state enable output for multi-master bus arbitration and preventing errors in slave mode
			MOSI_T: inout std_logic;
			
			-- slave select line output 
			SS_O: out std_logic_vector(C_NUM_SS_BITS-1 downto 0);
			
			--SCK pulse output
			SCK_O: out std_logic; 
			
			
			--load new data bit signaling that master block is ready to buffer new data
			load_new_data: inout std_logic;
			
			--data valid pulse from the Tx_FIFO
			TX_Valid: in std_logic;
			
			-- Master signal for telling SW it is ready for new data and a new transaction to be started 
			Initiate_New: out std_logic 
			
			
			);
	
end Master_Block;

architecture behavioral of Master_Block is

signal TX_Buffer: std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); -- internal buffer used to take in FIFO data
signal RX_Buffer: std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); -- second internal buffer for collecting data from slave
signal begin_transaction: std_logic; -- flag for pushing control flow to next process
signal t_count: integer; -- counter for access TX_Buffer 
signal r_count: integer; -- counter for accessing RX_Buffer
signal transfer_mode: std_logic; -- latched signal for Manual or Auto designation
signal LSB_or_MSB_Internal: std_logic; -- latched signal to make a transaction LSB or MSB style
signal initialized: std_logic; -- another control flow flag 
signal SPI_CLK_COUNT: integer; -- counter for determining spi edges 
signal SPI_CLK_EDGES: integer; -- 32 spi edges per transaction
signal reset_count: std_logic; -- to prevent load_new_data for getting set unecessarilly during other processes 
signal rising: std_logic; -- indicates if edge is rising or falling 
signal SPI_CLK: std_logic; -- internal signal for toggling SCK_O that it is attached to via buffer
signal wait_count: integer; -- creates a 6 cycle wait period after inhibit or end of transaction 
signal load_transaction: std_logic; -- when high new data may be loaded and subsequently a new transaction

begin 
process (S_AXI_ACLK, RESETN)
begin
if RESETN = '0' then 
	MOSI_O <= '0';
	Data_Out_Parallel<=(others=>'0');
	TX_Buffer<=(others=>'0');
	RX_Buffer<=(others=>'0');
	SS_O<=(others=>'1');
	load_new_data<='0';
	SCK_O<='0';
	MOSI_T<='1';
	reset_count<='0';
	wait_count<=6;
elsif rising_edge(S_AXI_ACLK) then 

------------------------------------------------------------------------------------------------------------
-- sets off the transaction, takes two clock cycles of Master_or_Slave, SPE, and Master_Inhibit
-- begin set to the appropriate values (for allowing a master transaction) to get to a point of no return 
-- where the transaction will occur no matter what with the LSB and MSB, manual or auto settings that were set
-- during those two clock edges after load_transaction is seen as high
-------------------------------------------------------------------------------------------------------------
	if load_transaction='1' and TX_Valid= '1' and Master_or_Slave ='1' and SPE ='1' and Master_Inhibit ='0' then 
		load_transaction<='0';
		TX_Buffer<=Data_In_Parallel;
		load_new_data<='0';
		MOSI_T<='0';
	elsif load_new_data ='0' and reset_count='0' then --line for properly exiting an asynchronous reset 
		load_new_data<='1';
		reset_count<='1';
		
	end if;
	
	if Master_Inhibit= '1' then 
		rising<='1';
		begin_transaction<='0';
		SS_O<=(others=>'1');
		load_new_data<='1';
		begin_transaction<='0';
		initialized<='0';
		TX_Buffer<=(others=>'0');
		RX_Buffer<=(others=>'0'); 
		MOSI_T<='1';
		SPI_CLK<='0';
		wait_count<=0;
	end if;
	
end if;

end process;

------------------------------------------------------------------------------------------
-- Latches internal flags so they are held constant for the entirety of the transaction
-- Beyond this point the only way to exit the transaction that is proceeding with the 
-- manual/auto and LSB/MSB settings that are currently active is to use Master_Inhibit
-- otherwise transaction will complete in its entirety
------------------------------------------------------------------------------------------
process (S_AXI_ACLK)
begin 
if rising_edge(S_AXI_ACLK) then 

	if Master_Inhibit = '0' and Master_or_Slave = '1' and SPE ='1' and load_new_data='0' and begin_transaction ='0' and MOSI_T='0' then -- this process will be for setting paramaters of the transaction and signaling its start
		begin_transaction<='1';
		if LSB_or_MSB = '0' then 
			t_count<=(C_NUM_TRANSFER_BITS-1);
			r_count<=0;
			LSB_or_MSB_Internal <='0';
		else 
			t_count<=0;
			r_count<=(C_NUM_TRANSFER_BITS-1);
			LSB_or_MSB_Internal <='1';
		end if;
		
		if Manual_Slave_Select = '1' then 
			transfer_mode<='1';
			
		elsif Manual_Slave_Select = '0' then 
			transfer_mode<='0';
		end if;
		
		
			
	end if;
----------master inhibit statement resets back to load data phase-------------------------------	
	if Master_Inhibit= '1' then 
		rising<='1';
		begin_transaction<='0';
		SS_O<=(others=>'1');
		load_new_data<='1';
		begin_transaction<='0';
		initialized<='0';
		TX_Buffer<=(others=>'0');
		RX_Buffer<=(others=>'0'); 
		MOSI_T<='1';
		SPI_CLK<='0';
		wait_count<=0;
	end if;
----------master inhibit statement resets back to load data phase-------------------------------
end if;
end process;

--------------------------------------------------------------------------------------------------------
-- Process initiates the transaction by putting SPISSR register contents onto the slave select line
-- t_count updated according to transaction style LSB or MSB
-- SPI_CLK, SPI_CLK_EDGES, rising all set to be ready for transmit/receive process next
---------------------------------------------------------------------------------------------------------
process (S_AXI_ACLK)
begin 
if rising_edge(S_AXI_ACLK) then
	if Master_Inhibit ='0' and load_new_data ='0' and begin_transaction='1' and initialized = '0' and MOSI_T='0' then 
		initialized<='1';
		SS_O<=SSR;
		SPI_CLK<='0';
		rising<='1';
		SPI_CLK_COUNT<=0;
		SPI_CLK_EDGES <=31;
		
		if LSB_or_MSB_Internal = '0' then 
			MOSI_O<=TX_Buffer(t_count);
			t_count<=t_count-1;
		elsif LSB_or_MSB_Internal ='1' then 
			MOSI_O<=TX_Buffer(t_count);
			t_count<=t_count+1;
			
		end if;
		
		
	end if;
	
----------master inhibit statement resets back to load data phase-------------------------------
	if Master_Inhibit= '1' then 
		rising<='1';
		begin_transaction<='0';
		SS_O<=(others=>'1');
		load_new_data<='1';
		begin_transaction<='0';
		initialized<='0';
		TX_Buffer<=(others=>'0');
		RX_Buffer<=(others=>'0'); 
		MOSI_T<='1';
		SPI_CLK<='0';
		wait_count<=0;
	end if;
----------master inhibit statement resets back to load data phase-------------------------------
end if;
end process;



-----------------------------------------------------------------------------------------------------------------
-- This process begins with the first data bit on the MOSI_O line and MISO_I lines as required
-- The process then starts clocking the SCK_O to carry out the data transmit/receive
-- Transaction continues for 16 clock edges of the SCK_O clock.  
-- Last clock edge transfers data to the receive register and resets all flags
-- takes six clock cycles for load_transaction to be set again after this process concludes its operations
-----------------------------------------------------------------------------------------------------------------


process(S_AXI_ACLK) -- this process executes an automatic slave select transaction flow
begin
if rising_edge(S_AXI_ACLK) then  
	if Master_Inhibit = '0' and begin_transaction = '1' and load_new_data ='0' and initialized='1' and MOSI_T='0' then 
		if SPI_CLK_EDGES>0 then 
			if SPI_CLK_COUNT = 3 then 
				SPI_CLK<= not SPI_CLK;
				SPI_CLK_EDGES<=SPI_CLK_EDGES-1;
				SPI_CLK_COUNT<=0;
				rising<=not rising;
				if rising = '1' then 
					if LSB_or_MSB_Internal = '1' then 
						RX_Buffer(r_count)<=MISO_I;
						r_count<=r_count-1;
					elsif LSB_or_MSB_Internal = '0' then 
						RX_Buffer(r_count)<=MISO_I;
						r_count<=r_count+1;
					end if;
				elsif rising ='0' then 
					if LSB_or_MSB_Internal = '1' then 
						MOSI_O<=TX_Buffer(t_count);
						t_count<=t_count+1;
					elsif LSB_or_MSB_Internal = '0' then 
						MOSI_O<=TX_Buffer(t_count);
						t_count<=t_count-1;
					end if;
				end if;
				
			elsif SPI_CLK_COUNT = 1 then 
				SPI_CLK<= not SPI_CLK; -- needs to be changed to SCK_O 
				SPI_CLK_EDGES<=SPI_CLK_EDGES-1;
				rising<=not rising;
				if rising = '1' then 
					if LSB_or_MSB_Internal = '1' then 
						RX_Buffer(r_count)<=MISO_I;
						r_count<=r_count-1;
					elsif LSB_or_MSB_Internal = '0' then 
						RX_Buffer(r_count)<=MISO_I;
						r_count<=r_count+1;
					end if;
				elsif rising ='0' then 
					if LSB_or_MSB_Internal = '1' then 
						MOSI_O<=TX_Buffer(t_count);
						t_count<=t_count+1;
					elsif LSB_or_MSB_Internal = '0' then 
						MOSI_O<=TX_Buffer(t_count);
						t_count<=t_count-1;
					end if;
				end if;
				
			else 
				SPI_CLK_COUNT<=SPI_CLK_COUNT+1;
			end if;
		elsif SPI_CLK_EDGES = 0 and transfer_mode = '0' then 
			rising<=not rising;
			SPI_CLK<= not SPI_CLK;
			SS_O<=(others=>'1');
			load_new_data<='1';
			begin_transaction<='0';
			initialized<='0';
			Data_Out_Parallel<=RX_Buffer;
			MOSI_T<='1';
			wait_count<=0;
		elsif SPI_CLK_EDGES = 0 and transfer_mode = '1' then 
			rising<=not rising;
			SPI_CLK<= not SPI_CLK;	
			load_new_data<='1';
			begin_transaction<='0';
			initialized<='0';
			Data_Out_Parallel<=RX_Buffer;
			MOSI_T<='1';
			wait_count<=0;
		end if;
		
----------master inhibit statement resets back to load data phase-------------------------------			
	elsif Master_Inhibit= '1' then 
		rising<='1';
		begin_transaction<='0';
		SS_O<=(others=>'1');
		load_new_data<='1';
		begin_transaction<='0';
		initialized<='0';
		TX_Buffer<=(others=>'0');
		RX_Buffer<=(others=>'0'); 
		MOSI_T<='1';
		SPI_CLK<='0';
		wait_count<=0;
	end if;
-------------master inhibit statement resets back to load data phase-------------------------------
end if;
end process;




-----------------------------------------------------------------------------------------------------------------------------------------
-- Increments a counter so that upon Master_Inhibit being high or the end of a data transmit/receive cycle there is a six clock cycle delay until 
-- the master will accept new data
------------------------------------------------------------------------------------------------------------------------------------------
process (S_AXI_ACLK)
begin 
if rising_edge(S_AXI_ACLK) then 
	if wait_count<6 then
	wait_count<=wait_count+1;
	end if;
	
----------master inhibit statement resets back to load data phase-------------------------------
	if Master_Inhibit= '1' then 
		rising<='1';
		begin_transaction<='0';
		SS_O<=(others=>'1');
		load_new_data<='1';
		begin_transaction<='0';
		initialized<='0';
		TX_Buffer<=(others=>'0');
		RX_Buffer<=(others=>'0'); 
		MOSI_T<='1';
		SPI_CLK<='0';
		wait_count<=0;
	end if;
----------master inhibit statement resets back to load data phase-------------------------------
end if;

end process;


-----------------------------------------------------------------------------------------------------------------------------------------------
--This process creates a signal that when high indicates that a brand new transaction can begin
--The signal is set six rising clock edges after Master_Inhibit is high or after the end of a transaction or one clock cycle after a reset
-----------------------------------------------------------------------------------------------------------------------------------------------------
process(S_AXI_ACLK)
begin 
if rising_edge(S_AXI_ACLK) then 
	if load_new_data = '1' and wait_count = 6 then 
		load_transaction<='1'; 
	end if;
end if;
end process;

Initiate_New<=load_transaction;
SCK_O<=SPI_CLK; -- connects the SPI_CLK from the data transmit and receive process directly to the output.  

end behavioral;


