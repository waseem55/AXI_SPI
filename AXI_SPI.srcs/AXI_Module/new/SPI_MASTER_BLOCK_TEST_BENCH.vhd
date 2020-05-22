library ieee;
use ieee.std_logic_1164.all;

entity TB_AXI_Module is
end TB_AXI_Module;

architecture Test of TB_AXI_Module is

component Master_Block
	generic (C_NUM_TRANSFER_BITS: integer := 32; -- sets expected number of bits in a transfer and size of shift register
			C_NUM_SS_BITS: integer := 32); -- size of slave select output
	
	
	
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
			
end component;

constant C_NUM_TRANSFER_BITS : integer := 32;
constant C_NUM_SS_BITS : integer := 32;

signal S_AXI_ACLK: std_logic; 
signal RESETN: std_logic; 
signal MISO_I: std_logic;
signal Data_In_Parallel: std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); 
signal MOSI_O: std_logic; 
signal Data_Out_Parallel: std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); 
signal Master_or_Slave: std_logic; 
signal Master_Inhibit: std_logic; 
signal LSB_or_MSB: std_logic; 
signal SPE: std_logic; 
signal Manual_Slave_Select: std_logic; 
signal SSR: std_logic_vector(31 downto 0);
signal MOSI_T: std_logic;
signal SS_O: std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal SCK_O: std_logic;  
signal load_new_data: std_logic; 
signal TX_Valid: std_logic; 
signal Initiate_New: std_logic; 




begin 

S_AXI_ACLK <= not S_AXI_ACLK after 5ns;
RESETN <= '1', '0' after 20ns;

dut: Master_Block 
generic map (C_NUM_SS_BITS=> C_NUM_SS_BITS,
C_NUM_TRANSFER_BITS=>C_NUM_TRANSFER_BITS)

port map (S_AXI_ACLK=>S_AXI_ACLK, RESETN=>RESETN, MISO_I=>MISO_I, Data_In_Parallel=>Data_In_Parallel, 
Data_Out_Parallel=>Data_Out_Parallel, 
MOSI_O=>MOSI_O, Master_or_Slave=>Master_or_Slave, Master_Inhibit=>Master_Inhibit, LSB_or_MSB=>LSB_or_MSB, SPE=>SPE, 
Manual_Slave_Select=>Manual_Slave_Select, 
SSR=>SSR, MOSI_T=>MOSI_T, SS_O=>SS_O, SCK_O=>SCK_O, load_new_data=>load_new_data, TX_Valid=>TX_Valid, 
Initiate_New=>Initiate_New);

process

begin 
---------------------- SPI_MASTER_TEST_CASE_1 ----------------------------------
wait until RESETN= '0';
assert MOSI_O = '0' and Data_Out_Parallel = "00000000000000000000000000000000" and load_new_data = '0' and Initiate_New = '0' 
report "Not putting all signals in proper reset level" 
severity failure;
---------------------- END_SPI_MASTER_TEST_CASE_1 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_2 ----------------------------------
---------------------- END_SPI_MASTER_TEST_CASE_2 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_3 ----------------------------------
---------------------- END_SPI_MASTER_TEST_CASE_3 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_4 ----------------------------------
---------------------- END_SPI_MASTER_TEST_CASE_4 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_5 ----------------------------------
---------------------- END_SPI_MASTER_TEST_CASE_5 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_6 ----------------------------------
---------------------- END_SPI_MASTER_TEST_CASE_6 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_7 ----------------------------------
---------------------- END_SPI_MASTER_TEST_CASE_7 ------------------------------
end process;

end Test;
