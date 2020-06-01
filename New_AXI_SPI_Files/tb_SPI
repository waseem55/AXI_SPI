library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_SPI is
end tb_SPI;

architecture Test of tb_SPI is

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
	i_TX_DATA			: in std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	o_RX_DATA			: out std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	i_SSR				: in std_logic_vector(31 downto 0);
--	i_TX_Valid			: in std_logic;
	
	-- To/From FIFOs
	Tx_Empty			: in std_logic;
	read_enable			: out std_logic;
	write_enable		: out std_logic;
	
	-- To and from registers
	i_Reg_Ack			: in std_logic;			-- used to latch SPICR input
	i_SPICR				: in std_logic_vector(31 downto 0);
	o_MODF				: out std_logic;
	o_Slave_MODF        : out std_logic;        -- Level '1' to signal error
	o_slave_mode_select	: out std_logic;
	IP2INTC_IRPT		: out std_logic
	);
end component;

signal SYS_CLK				: std_logic := '0';
signal RESETN_I				: std_logic := '0';
signal SPISEL				: std_logic := '1';
signal SCK_I				: std_logic := '0';
signal SCK_O				: std_logic;
signal SCK_T				: std_logic;
signal MOSI_I				: std_logic := '0';
signal MOSI_O				: std_logic;
signal MOSI_T				: std_logic;
signal MISO_I				: std_logic := '0';
signal MISO_O				: std_logic;
signal MISO_T				: std_logic;
signal SS_O					: std_logic_vector(0 downto 0);
signal SS_T					: std_logic_vector(0 downto 0);
signal o_Ready				: std_logic;
signal i_TX_DATA			: std_logic_vector(7 downto 0) := X"00";
signal o_RX_DATA			: std_logic_vector(7 downto 0);
signal i_SSR				: std_logic_vector(31 downto 0) := X"FFFFFFFE";		-- SSR(0) <= '0'
--signal i_TX_Valid			: std_logic := '0';
signal Tx_Empty				: std_logic := '1';
signal read_enable			: std_logic;
signal write_enable			: std_logic;
signal i_Reg_Ack			: std_logic := '0';
signal i_SPICR				: std_logic_vector(31 downto 0) := X"00000180";		-- Default values for SPICR
signal o_MODF				: std_logic;
signal o_Slave_MODF         : std_logic;
signal o_slave_mode_select	: std_logic;
signal IP2INTC_IRPT			: std_logic;

type FIFO is array (0 to 15) of std_logic_vector(7 downto 0);
signal TX_FIFO : FIFO := (others => X"00");

begin

	DUT: SPI_Module generic map(32, 1, 8)
	port map(
		SYS_CLK				=> SYS_CLK,
		RESETN_I			=> RESETN_I,
		
		-- SPI Ports --
		SPISEL				=> SPISEL,
		SCK_I				=> SCK_I,
		SCK_O				=> SCK_O,
		SCK_T				=> SCK_T,
		MOSI_I				=> MOSI_I,
		MOSI_O				=> MOSI_O,
		MOSI_T				=> MOSI_T,
		MISO_I				=> MISO_I,
		MISO_O				=> MISO_O,
		MISO_T				=> MISO_T,
		SS_O				=> SS_O,
		SS_T				=> SS_T,
		
		-- Internal Ports --
		o_Ready				=> o_Ready,
		i_TX_DATA			=> i_TX_DATA,
		o_RX_DATA			=> o_RX_DATA,
		i_SSR				=> i_SSR,
--		i_TX_Valid			=> i_TX_VALID,
		
		-- To/From FIFOs
		Tx_Empty			=> Tx_Empty,
		read_enable			=> read_enable,
		write_enable		=> write_enable,
		
		-- To and from regis
		i_Reg_Ack			=> i_Reg_Ack,
		i_SPICR				=> i_SPICR,
		o_MODF				=> o_MODF,
		o_Slave_MODF        => o_Slave_MODF,
		o_slave_mode_select	=> o_slave_mode_select,
		IP2INTC_IRPT		=> IP2INTC_IRPT
		);
		
	SYS_CLK <= not SYS_CLK after 5 ns;
	RESETN_I <= '0', '1' after 20 ns;
	
	process
	variable count : integer := 0;
	begin
		-- preparing TX data
		for i in 0 to 15 loop
			TX_FIFO(i) <= std_logic_vector(to_unsigned(count, 8));
			count := count + 1;
		end loop;
		
		wait until RESETN_I = '1';
		wait until SYS_CLK = '0';
		
------------------------Master Mode ----------------------------
		-- Testing the master operation by simulating a typical transaction 
		MISO_I <= '1';              -- Initial MISO input
		i_TX_DATA <= TX_FIFO(5);    -- Data to be sent through MOSI <= 5
		Tx_Empty <= '0';		    -- TxFIFO is not empty
		
		i_SPICR <= X"00000184";	    -- Master Bit <= '1'
		i_Reg_Ack <= '1';		    -- latch SPICR content
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		i_Reg_Ack <= '0';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		
		i_SPICR <= X"00000086";	    -- Master_inhibit <= '0' to start transaction
		i_Reg_Ack <= '1';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		i_Reg_Ack <= '0';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		
		wait for 100 ns;
		MISO_I <= '0';
		wait for 100 ns;
		
--------------------- Slave Mode ------------------------
		-- Testing the master operation by simulating a typical transaction 
		i_SPICR <= X"00000000"; 
		i_Reg_Ack <= '1';		-- latch SPICR content
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		i_Reg_Ack <= '0';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		
		MOSI_I <= '1';
		i_TX_DATA <= TX_FIFO(7);
		i_SPICR <= X"00000002";	-- Master Bit <= '1'
		i_Reg_Ack <= '1';		-- latch SPICR content
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		i_Reg_Ack <= '0';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		
		SPISEL <= '0';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '0';
		wait until SYS_CLK = '1';
--		wait until SYS_CLK = '0';
		
		for i in 0 to 7 loop
			SCK_I <= '1';
			wait until SYS_CLK = '1';
			SCK_I <= '0';
			if i = 4 then
				MOSI_I <= '0';
			end if;
			wait until SYS_CLK = '1';
		end loop;
		
		wait until SYS_CLK = '1';
		wait until SYS_CLK = '1';
		
		SPISEL <= '1';
		
		wait;
		
	end process;
end test;
		