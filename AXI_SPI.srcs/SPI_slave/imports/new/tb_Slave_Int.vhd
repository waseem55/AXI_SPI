library ieee;
use ieee.std_logic_1164.all;

entity tb_Slave_Int is
end tb_Slave_Int;

architecture Test of tb_Slave_Int is

component Slave_Int
generic(C_NUM_TRANSFER_BITS : integer := 8);
port(
	i_CLK		: in std_logic;
	i_RESETN	: in std_logic;
	i_LSB_first : in std_logic;
	
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
	o_SPI_MISO	: out std_logic
	);
end component;

signal i_CLK	: std_logic := '0';
signal i_RESETN	: std_logic := '0';
signal i_LSB_first : std_logic := '1';
	
	-- TX (MISO) ports
signal i_TX_DATA	: std_logic_vector(7 downto 0);
signal i_TX_DV		: std_logic;
signal o_TX_READY	: std_logic;
	
	-- RX (MOSI) ports
signal o_RX_DV		: std_logic;
signal o_RX_DATA	: std_logic_vector(7 downto 0);
	
	-- SPIInterface
signal i_SPI_CLK	: std_logic := '0';
signal i_SPI_MOSI	: std_logic;
signal i_SPI_SPISEL: std_logic := '1';
signal o_SPI_MISO	: std_logic;

begin

DUT: Slave_Int generic map(8)
port map(i_CLK, i_RESETN, i_LSB_first, i_TX_DATA, i_TX_DV, o_TX_READY, o_RX_DV, o_RX_DATA,
i_SPI_CLK, i_SPI_MOSI, i_SPI_SPISEL, o_SPI_MISO);

i_clk <= not i_clk after 5 ns;
i_RESETN <= '0', '1' after 20 ns;

process
begin

	wait until i_RESETN = '1';
	wait until i_CLK = '1';
	wait until i_CLK = '0';

	i_TX_DATA <= X"f0";
	i_TX_DV <= '1';
	wait until i_CLK = '1';
	i_TX_DV <= '0';
	
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	
	i_SPI_MOSI <= '0';
	i_SPI_SPISEL <= '0';
	
	wait until i_SPI_CLK = '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '1';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '1';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	
	i_SPI_SPISEL <= '1';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	wait until i_CLK = '0';
	wait until i_CLK = '1';
	
	i_SPI_MOSI <= '1';
	i_SPI_SPISEL <= '0';
	
	wait until i_SPI_CLK = '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '1';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '0';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '1';
	wait until i_SPI_CLK = '1';
	wait until i_SPI_CLK = '0';
	i_SPI_MOSI <= '0';
	
end process;
	
process
begin
	
	wait until i_SPI_SPISEL = '0';
	wait until i_CLK = '0';
	for i in 0 to 15 loop
		wait until i_CLK = '1';
		wait until i_CLK = '1';
		wait until i_CLK = '1';
		wait until i_CLK = '1';
		i_SPI_CLK <= not i_SPI_CLK;
	end loop;
	
	wait until i_SPI_SPISEL = '1';
	wait until i_SPI_SPISEL = '0';
	wait until i_CLK = '0';
	for i in 0 to 15 loop
		wait until i_CLK = '1';
		wait until i_CLK = '1';
		wait until i_CLK = '1';
		wait until i_CLK = '1';
		i_SPI_CLK <= not i_SPI_CLK;
	end loop;
end process;

end test;