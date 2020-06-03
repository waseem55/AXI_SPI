library ieee;
use ieee.std_logic_1164.all;

entity TB_SPI_Module is
end TB_SPI_Module;


architecture Test of TB_SPI_Module is

component SPI_Module
generic(
	C_SCK_RATIO			: integer := 4;
	C_NUM_SS_BITS		: integer := 1;
	C_NUM_TRANSFER_BItS	: integer := 8
	);
port(
	SYS_CLK				: in std_logic;
	RESETN_I			: in std_logic;
	
	-- SPI Ports --
	SPISEL				: in std_logic;
	SCK_I				: in std_logic;
	SCK_O				: inout std_logic;
	SCK_T				: out std_logic;
	MOSI_I				: in std_logic;
	MOSI_O				: out std_logic;
	MOSI_T				: inout std_logic;
	MISO_I				: in std_logic;
	MISO_O				: out std_logic;
	MISO_T				: out std_logic;
	SS_O				: out std_logic_vector(C_NUM_SS_BITS-1 downto 0);
	SS_T				: out std_logic_vector(C_NUM_SS_BITS-1 downto 0);
	
	-- Internal Ports --
	o_Ready				: inout std_logic;
	i_TX_DATA			: in std_logic_vector(C_NUM_TRANSFER_BItS-1 downto 0);
	o_RX_DATA			: out std_logic_vector(C_NUM_TRANSFER_BItS-1 downto 0);
	i_SSR				: in std_logic_vector(31 downto 0);
--	i_TX_Valid			: in std_logic;
	
	-- To/From FIFOs
	Tx_Empty			: in std_logic;
	read_enable			: out std_logic;
	write_enable		: out std_logic;
	inhibit             : out std_logic;
	-- To and from registers
	i_Reg_Ack			: in std_logic;			-- used to latch SPICR input
	i_SPICR				: in std_logic_vector(31 downto 0);
	o_MODF				: out std_logic;        -- level '1' to signal error
	o_Slave_MODF        : out std_logic;        -- Level '1' to signal error
	o_slave_mode_select	: out std_logic;
	IP2INTC_IRPT		: out std_logic												-- to do: figure out what to use it for
	);

end component;

constant C_NUM_TRANSFER_BItS: integer := 8;
constant C_NUM_SS_BITS: integer := 1;
constant C_SCK_RATIO: integer :=4;

signal SYS_CLK: std_logic :='0';
signal RESETN_I: std_logic := '0';
signal SPISEL: std_logic :='1';
signal SCK_I: std_logic := '0';
signal SCK_O: std_logic :='0';
signal SCK_T: std_logic :='1';
signal MOSI_I: std_logic := '0';
signal MOSI_O: std_logic := '0';
signal MOSI_T: std_logic := '1';
signal MISO_I: std_logic := '0';
signal MISO_O: std_logic := '0';
signal MISO_T: std_logic := '1';
signal SS_O: std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal SS_T: std_logic_vector(C_NUM_SS_BITS-1 downto 0) := (others => '1');
signal o_Ready: std_logic := '1';
signal i_TX_DATA: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0) := (others=>'0');
signal o_RX_DATA: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0) := (others=>'0');
signal i_SSR: std_logic_vector(31 downto 0) := (others=>'1'); 
signal Tx_Empty: std_logic :='1';
signal read_enable: std_logic :='0';
signal write_enable: std_logic :='0';
signal i_Reg_Ack: std_logic :='0';
signal i_SPICR: std_logic_vector(31 downto 0) := "00000000000000000000000110000000";
signal o_MODF: std_logic := '0';
signal o_Slave_MODF: std_logic :='0';
signal o_slave_mode_select: std_logic := '0'; -- initializations for the flags might be wrong
signal IP2INTC_IRPT: std_logic := '0';
signal inhibit: std_logic;

begin



	DUT : SPI_Module port map(SYS_CLK=>SYS_CLK, RESETN_I=>RESETN_I, SPISEL=>SPISEL, SCK_I=>SCK_I, SCK_O=>SCK_O, SCK_T=>SCK_T, MOSI_I=>MOSI_I, MOSI_O=>MOSI_O, MOSI_T=>MOSI_T, 
	MISO_T=>MISO_T, MISO_I=>MISO_I, MISO_O=>MISO_O, SS_O=>SS_O, SS_T=>SS_T, o_Ready=>o_Ready,i_TX_DATA=>i_TX_DATA, o_RX_DATA=>o_RX_DATA, i_SSR=>i_SSR, Tx_Empty=>Tx_Empty, read_enable=>read_enable, write_enable=>write_enable, 
	i_Reg_Ack=>i_Reg_Ack, i_SPICR=>i_SPICR,o_MODF=>o_MODF, o_Slave_MODF=>o_Slave_MODF, o_slave_mode_select=>o_slave_mode_select, IP2INTC_IRPT=>IP2INTC_IRPT, inhibit=>inhibit);

SYS_CLK<=not SYS_CLK after 5ns;
RESETN_I<= '0', '1' after 20ns;
process 
begin

-------------------------------SPI_TEST_CASE_1------------------------------------------------
wait for 5ns;
assert o_RX_DATA = "00000000" and read_enable = '0' and write_enable = '0' and MISO_T = '1' and MOSI_T = '1' and o_Ready='0' and MOSI_O = '0' and SCK_O = '0' 
report "Reset failed"
severity failure;
wait until RESETN_I = '1';
wait until rising_edge(SYS_CLK);
-------------------------------END_SPI_TEST_CASE_1--------------------------------------------

-------------------------------SPI_TEST_CASE_2------------------------------------------------
i_SPICR <= "00000000000000000000000000000110";
i_Reg_Ack<='1';
i_TX_DATA<="11101111";
Tx_Empty <='0';
i_SSR<="00000000000000000000000000000000";
wait until rising_edge(SYS_CLK); -- i_SPICR becomes SPICR in SPI module
wait until rising_edge(SYS_CLK); -- recognized by master
wait for 1ns;
assert read_enable = '1' and o_Ready = '0'
report "Master transaction not initiated properly" 
severity failure;
-------------------------------END_SPI_TEST_CASE_2--------------------------------------------

-------------------------------SPI_TEST_CASE_3------------------------------------------------
wait until rising_edge(SYS_CLK); 
wait for 1ns;
assert read_enable = '0' and o_Ready= '0'
report "Master transaction does not send read pulse properly" 
severity failure;
-------------------------------END_SPI_TEST_CASE_3--------------------------------------------

-------------------------------SPI_TEST_CASE_4------------------------------------------------
wait until rising_edge(SYS_CLK); 
wait until rising_edge(SYS_CLK); 
wait for 1ns;
assert MOSI_O = '1' and read_enable = '0' and SS_O = "0" -- confirms that no other parts of the state machine are running, state machine is in the proper state
report "Data has not been read and serialized properly for current transaction" 
severity failure;
-------------------------------END_SPI_TEST_CASE_4--------------------------------------------

-------------------------------SPI_TEST_CASE_5------------------------------------------------
--bit 1 
MISO_I <= '1';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 2
MISO_I <= '1';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 3
MISO_I <= '1';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 4 
MISO_I <= '1';
wait until SCK_O = '1';
assert MOSI_O = '0'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 5
MISO_I <= '0';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 6 
MISO_I <= '0';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 7
MISO_I <= '0';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
--bit 8
MISO_I <= '0';
wait until SCK_O = '1';
assert MOSI_O = '1'
report "data transmission error"
severity failure;
wait until SCK_O = '0';
wait for 1ns;
assert write_enable = '1' and o_RX_DATA = "00001111" -- MSB style transaction but master assumes slave sends in opposite order as it
report "write pulse not initiated or data receive operations failed"
severity failure;

-------------------------------END_SPI_TEST_CASE_5--------------------------------------------

-------------------------------SPI_TEST_CASE_6------------------------------------------------
wait for 30ns;
assert o_Ready = '0' and SS_O = "1"
report "delay between transactions not occuring"
severity failure;
i_SPICR <= "00000000000000000000000000000100";
-------------------------------END_SPI_TEST_CASE_6--------------------------------------------

-------------------------------SPI_TEST_CASE_7------------------------------------------------
wait until o_Ready = '1';
wait for 50ns;
assert o_Ready = '1'
report "SPICR not controlling transaction flow properly" 
severity failure;
i_SPICR <= "00000000000000000000000000000110";
-------------------------------END_SPI_TEST_CASE_7--------------------------------------------

-------------------------------SPI_TEST_CASE_8------------------------------------------------
wait for 50ns;
i_SPICR  <= "00000000000000000000000100000110";
wait until rising_edge(SYS_CLK); 
wait until rising_edge(SYS_CLK); 
wait for 1ns;
assert inhibit = '1' 
report "Inhibit/Abort unsuccessful" 
severity failure;
i_SPICR  <= "00000000000000000000000100000110";
-------------------------------END_SPI_TEST_CASE_8--------------------------------------------

-------------------------------SPI_TEST_CASE_9------------------------------------------------
--onto slave test procedures  
-------------------------------END_SPI_TEST_CASE_9--------------------------------------------

-------------------------------SPI_TEST_CASE_10------------------------------------------------

-------------------------------END_SPI_TEST_CASE_10--------------------------------------------
wait;
end process;
end Test;
