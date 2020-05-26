----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/22/2020 02:45:39 PM
-- Design Name: 
-- Module Name: SPI_MASTER_BLOCK_TEST_BENCH - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity SPI_MASTER_BLOCK_TEST_BENCH is
end SPI_MASTER_BLOCK_TEST_BENCH;

architecture Test of SPI_MASTER_BLOCK_TEST_BENCH is

component Master_Block
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
			
			--signals readiness to accept new data of size C_NUM_TRANSFER_BITS and begin new transaction to FIFO and top level entity
			ready_for_transaction: inout std_logic;
			
			--data valid pulse from the Tx_FIFO
			TX_Valid: in std_logic
		
			
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
signal TX_Valid: std_logic; 
signal ready_for_transaction: std_logic;






begin 

S_AXI_ACLK <= not S_AXI_ACLK after 5ns;
RESETN<= '0', '1' after 20ns;

dut: Master_Block 
generic map (C_NUM_SS_BITS=> C_NUM_SS_BITS,
C_NUM_TRANSFER_BITS=>C_NUM_TRANSFER_BITS)

 port map (S_AXI_ACLK=>S_AXI_ACLK, RESETN=>RESETN, MISO_I=>MISO_I, Data_In_Parallel=>Data_In_Parallel, 
 Data_Out_Parallel=>Data_Out_Parallel, MOSI_O=>MOSI_O, Master_or_Slave=>Master_or_Slave, Master_Inhibit=>Master_Inhibit, 
 LSB_or_MSB=>LSB_or_MSB, SPE=>SPE, Manual_Slave_Select=>Manual_Slave_Select, SSR=>SSR, MOSI_T=>MOSI_T, SS_O=>SS_O, SCK_O=>SCK_O, 
 TX_Valid=>TX_Valid
);
process

begin 
---------------------- SPI_MASTER_TEST_CASE_1 ----------------------------------
wait until ready_for_transaction = '1';
assert MOSI_T = '1' and MOSI_O = '0' and Data_Out_Parallel = (others=>'0')
report "reset not handled correctly" 
severity failure;
---------------------- END_SPI_MASTER_TEST_CASE_1 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_2 ----------------------------------
Master_Inhibit<='0';
Master_or_Slave<='1';
SPE<='1';
TX_Valid<='1';
LSB_or_MSB<='1';
Manual_Slave_Select<='1';
Data_In_Parallel<="11010101010101010101010101010101";
wait until rising_edge(S_AXI_ACLK);
assert ready_for_transaction = '0' and SS_O /= (others=>'1')
report "transition into beginning of transaction didn't occur properly" 
severity failure;
---------------------- END_SPI_MASTER_TEST_CASE_2 ------------------------------

---------------------- SPI_MASTER_TEST_CASE_3 ----------------------------------
wait until rising_edge(S_AXI_ACLK);
assert MOSI_O = '1'
report "transaction not initialized properly"  
severity failure;
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

