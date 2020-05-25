library ieee;
use ieee.std_logic_1164.all;

entity slave_Int is
generic(
	C_NUM_TRANSFER_BITS	: integer := 8
	);
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
end slave_int;

architecture RTL of slave_Int is

	signal done 			: std_logic;
	signal load, t_TX_READY	: std_logic;
	
	signal shift			: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	signal buff_out, buff	: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);	-- buff_out is MISO buffer, buff is temp storage for TX
	signal counter			: integer range 0 to C_NUM_TRANSFER_BITS-1;
	signal prepare_counter	: integer range 0 to 6;
	
	type mystate is (idle, active, transmit);
	signal state : mystate;
	
begin

Latching_TX_Data: process(i_CLK, i_RESETN)
begin
	if i_RESETN = '0' then
		buff <= (others => '0');
	elsif rising_edge(i_CLK) then
		if t_TX_READY = '1' and i_TX_DV = '1' then
			buff <= i_TX_DATA;
		end if;
	end if;
end process;

setting_TX_READY: process(i_CLK, i_RESETN)
begin
	if i_RESETN = '0' then
		t_TX_READY <= '0';
	elsif rising_edge(i_CLK) then
		if i_SPI_SPISEL = '1' then
			t_TX_READY <= '1';
		else
			if t_TX_READY = '1' and i_TX_DV = '1' then
				t_TX_READY <= '0';
			elsif done = '1' then
				t_TX_READY <= '1';
			end if;
		end if;
	end if;
end process;
		

process(i_SPI_CLK, i_RESETN, i_SPI_SPISEL)
begin
	if i_RESETN = '0' then
		counter <= C_NUM_TRANSFER_BITS-1;
		o_RX_DATA <= (others => '0');
		buff_out <= (others => '0');
		o_RX_DV <= '0';
	else
		if i_SPI_SPISEL = '1' then
			buff_out <= buff;
			counter <= C_NUM_TRANSFER_BITS-1;
			o_RX_DV <= '0';
		else
			o_RX_DV <= '0';
			if rising_edge(i_SPI_CLK) then 
				o_RX_DATA(counter) <= i_SPI_MOSI;
				if counter = 0 then
					counter <= C_NUM_TRANSFER_BITS-1;
					o_RX_DV <= '1';
				else
					counter <= counter - 1;
				end if;
			end if;
		end if;
	end if;
end process;

process(i_CLK, i_RESETN)
begin
	if i_RESETN = '0' then
		prepare_counter <= 6;
		done <= '0';
	elsif i_SPI_SPISEL = '0' then
		if rising_edge(i_CLK) then
			if counter = C_NUM_TRANSFER_BITS-1 then
				if i_SPI_CLK = '1' then
					prepare_counter <= 6;
					done <= '1';
				else
					if i_TX_DV = '1' then
						done <= '0';
					elsif prepare_counter = 0 then
						done <= '0';
					else
						prepare_counter <= prepare_counter - 1;
					end if;
				end if;
			end if;
		end if;
	end if;
end process;
			
process(i_SPI_CLK, i_RESETN, i_SPI_SPISEL)
begin
 	if i_RESETN = '0' then
 		o_SPI_MISO <= '0';
 	elsif i_SPI_SPISEL = '1' then
 		o_SPI_MISO <= buff(0);
 	else
 		if falling_edge(i_SPI_CLK) then
 			o_SPI_MISO <= buff_out(counter);
 		end if;
 	end if;
end process;	

o_TX_READY <= t_TX_READY;
--process(i_CLK, i_RESETN)
--begin

--	if i_RESETN = '0' then
--		state <= idle;
--	elsif rising_edge(i_CLK) then
--		case state is
--		when idle =>
--			buff_out <= i_TX_DATA;
--			counter <= C_NUM_TRANSFER_BITS-1;
--			if i_SPI_SPISEL = '0' then
--				state <= active;
--				o_SPI_MISO <= buff_out(counter);
--			end if;
--		when active =>
--			buff_in(counter) <= i_SPI_MOSI;
--			if counter = 0 then
--				counter <= C_NUM_TRANSFER_BITS-1;
end RTL;