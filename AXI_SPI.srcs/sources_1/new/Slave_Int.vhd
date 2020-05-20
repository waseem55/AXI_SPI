library ieee;
use ieee.std_logic_1164.all;

entity slave_Int is
generic(
	C_NUM_TRANSFER_BITS	: integer := 8
	);
port(
	i_CLK		: in std_logic;
	i_RESETN	: in std_logic;
	
	-- TX (MISO) ports
	i_TX_DATA	: in std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	i_TX_DV		: in std_logic;
	o_TX_READY	: out std_logic;
	
	-- RX (MOSI) ports
	o_RX_DV		: out std_logic;
	o_RX_DATA	: out std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	
	-- SPIInterface
	i_SPI_CLK	: in std_logic;
	i_SPI_MOSI	: in std_logic;
	i_SPI_SPISEL: in std_logic;
	o_SPI_MISO	: out std_logic;
	o_SPI_MISO_T: out std_logic
	);
end slave_int;

architecture RTL of slave_Int is

	signal enb_shift 	: std_logic;
	signal load, done	: std_logic;
	signal buff, shift	: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	signal counter		: integer range 0 to C_NUM_TRANSFER_BITS-1;
	
begin

--process(i_CLK, i_RESETN)
--begin





shift_register: process(i_SPI_CLK, i_RESETN)
begin
 	if RESETN = '0' then
 		shift <= (others => '0');
 	else
 		if (load = '1' and done = '1') then
 			shift <= buff;
 		
 		if enb_shift = '0' then
 		
 		elsif rising_edge(i_SPI_CLK) then
 		 