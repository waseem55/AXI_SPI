library ieee;
use ieee.std_logic_1164.all;

entity SPI_Module is
generic(
	C_SCK_RATIO			: integer;
	C_NUM_SS_BITS		: integer;
	C_NUM_TRANSFER_BItS	: integer
	);
port(
	SCK_I				: in std_logic;
	MOSI_I				: in std_logic;
	MISO_I				: in std_logic;
	SPISEL				: in std_logic;
	SCK_O				: out std_logic;
	SCK_T				: out std_logic;
	MOSI_O				: out std_logic;
	MOSI_T				: out std_logic;
	MISO_O				: out std_logic;
	MISO_T				: out std_logic;
	SS_O				: out std_logic;
	SS_T				: out std_logic;
	IP2INTC_IRPT		: out std_logic
	);
end SPI_Module;

architecture behaviour of SPI_Module is
begin
