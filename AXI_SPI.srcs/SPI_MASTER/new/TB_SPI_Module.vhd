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

signal SYS_CLK: std_logic;
signal RESETN_I: std_logic;
signal SPISEL: std_logic;
signal SCK_I: std_logic;
signal SCK_O: std_logic;
signal SCK_T: std_logic;
signal MOSI_I: std_logic;
signal MOSI_O: std_logic;
signal MOSI_T: std_logic;
signal MISO_I: std_logic;
signal MISO_O: std_logic;
signal MISO_T: std_logic;
signal SS_O: std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal SS_T: std_logic_vector(C_NUM_SS_BITS-1 downto 0);
signal o_Ready: std_logic;
signal i_TX_DATA: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal o_RX_DATA: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal i_SSR: std_logic_vector(31 downto 0); 
signal Tx_Empty: std_logic;
signal read_enable: std_logic;
signal write_enable: std_logic;
signal i_Reg_Ack: std_logic;
signal i_SPICR: std_logic_vector(31 downto 0);
signal o_MODF: std_logic;
signal o_Slave_MODF: std_logic;
signal o_slave_mode_select: std_logic;
signal IP2INTC_IRPT: std_logic;

begin



	DUT : SPI_Module port map(SYS_CLK=>SYS_CLK, RESETN_I=>RESETN_I, SPISEL=>SPISEL, SCK_I=>SCK_I, SCK_O=>SCK_O, SCK_T=>SCK_T, MOSI_I=>MOSI_I, MOSI_O=>MOSI_O, MOSI_T=>MOSI_T, 
	MISO_T=>MISO_T, MISO_I=>MISO_I, MISO_O=>MISO_O, SS_O=>SS_O, SS_T=>SS_T, o_Ready=>o_Ready,i_TX_DATA=>i_TX_DATA, o_RX_DATA=>o_RX_DATA, i_SSR=>i_SSR, Tx_Empty=>Tx_Empty, read_enable=>read_enable, write_enable=>write_enable, 
	i_Reg_Ack=>i_Reg_Ack, i_SPICR=>i_SPICR,o_MODF=>o_MODF, o_Slave_MODF=>o_Slave_MODF, o_slave_mode_select=>o_slave_mode_select, IP2INTC_IRPT=>IP2INTC_IRPT);

SYS_CLK<=not SYS_CLK after 5ns;
RESETN_I<= '0', '1' after 20ns;
process 
begin
-------------------------------SPI_TEST_CASE_1------------------------------------------------
wait for 5ns;
assert o_RX_DATA = "00000000000000000000000000000000" and read_enable = '0' and write_enable = '0' and MISO_T = '1' and MOSI_T = '1' and o_Ready='0' and MOSI_O = '0' and SCK_O = '0' 
report "Reset failed"
severity failure;
wait until RESETN_I = '1';
wait until rising_edge(SYS_CLK);
-------------------------------END_SPI_TEST_CASE_1--------------------------------------------

-------------------------------SPI_TEST_CASE_2------------------------------------------------
i_SPICR <= "00000000000000000000000000000110";
i_Reg_Ack<='1';
i_TX_DATA<="11111111";
-------------------------------END_SPI_TEST_CASE_2--------------------------------------------

-------------------------------SPI_TEST_CASE_3------------------------------------------------
-------------------------------END_SPI_TEST_CASE_3--------------------------------------------

-------------------------------SPI_TEST_CASE_4------------------------------------------------
-------------------------------END_SPI_TEST_CASE_4--------------------------------------------

-------------------------------SPI_TEST_CASE_5------------------------------------------------
-------------------------------END_SPI_TEST_CASE_5--------------------------------------------

-------------------------------SPI_TEST_CASE_6------------------------------------------------
-------------------------------END_SPI_TEST_CASE_6--------------------------------------------

-------------------------------SPI_TEST_CASE_7------------------------------------------------
-------------------------------END_SPI_TEST_CASE_7--------------------------------------------

-------------------------------SPI_TEST_CASE_8------------------------------------------------
-------------------------------END_SPI_TEST_CASE_8--------------------------------------------
wait;
end process;
end Test;
