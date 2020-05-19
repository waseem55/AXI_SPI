library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BRG is
generic(
	C_SCK_RATIO	: integer := 32
	);
port(
	RESETN		: in std_logic;
	ENB			: in std_logic;
	CPOL		: in std_logic;		-- 0: clk idles low, 1: clk idles high
	AXI_CLK		: in std_logic;
	SPI_CLK		: out std_logic
	);
end BRG;

architecture behaviour of BRG is
signal counter : unsigned(4 downto 0);
signal temp_clk: std_logic;
begin

	process(RESETN, AXI_CLK)
	begin
		if (RESETN = '0' or ENB = '0') then
			counter <= (others => '0');
		elsif rising_edge(AXI_CLK) then
			if ENB = '1' then
				counter <= counter + 1;
			end if;
		end if;
	end process;
	
	with C_SCK_RATIO select
		SPI_CLK <= counter(0) xor CPOL when 2,
				   counter(1) xor CPOL when 4,
				   counter(2) xor CPOL when 8,
				   counter(3) xor CPOL when 16,
				   counter(4) xor CPOL when 32,
				   '0' when others;

end behaviour;