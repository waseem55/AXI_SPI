library ieee;
use ieee.std_logic_1164.all;
use work.component_pckg.all;

entity SPI_Module is
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
	inhibit             : out std_logic;
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
	o_MODF				: out std_logic;        -- level '1' to signal error, top entity should make it a pulse if needed
	o_Slave_MODF        : out std_logic;        -- Level '1' to signal error, top entity should make it a pulse if needed
	o_slave_mode_select	: out std_logic;
	IP2INTC_IRPT		: out std_logic												-- to do: figure out what to use it for
	);
end SPI_Module;

architecture behaviour of SPI_Module is
	
	signal SPE				: std_logic;
	signal Master_or_Slave	: std_logic;
	signal Manual_SS		: std_logic;
	signal LSB_or_MSB		: std_logic;
	signal Ready			: std_logic;
	signal Master_Inhibit	: std_logic;
	signal M_read_enable	: std_logic;
	signal M_write_enable	: std_logic;
	signal S_read_enable	: std_logic;
	signal S_write_enable	: std_logic;
	signal M_RX_DATA		: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	signal S_RX_DATA		: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
	signal loop_i			: std_logic;
	signal loop_o			: std_logic;
	signal SPICR			: std_logic_vector(9 downto 0);
	signal Tx_Not_Empty		: std_logic;
	
begin
	
	Master: MASTER_BLOCK generic map
		(C_NUM_SS_BITS => C_NUM_SS_BITS, C_NUM_TRANSFER_BItS => C_NUM_TRANSFER_BItS)
	port map(
		S_AXI_ACLK				=> SYS_CLK,
		RESETN					=> RESETN_I,
		MISO_I					=> loop_i,
		Data_In_Parallel		=> i_TX_DATA,
		MOSI_O					=> loop_o,
		Data_Out_Parallel		=> M_RX_DATA,
		Master_or_Slave			=> Master_or_Slave,
		Master_Inhibit			=> Master_Inhibit,
		LSB_or_MSB				=> LSB_or_MSB,
		SPE						=> SPE,
		Manual_Slave_Select		=> Manual_SS,
		SSR						=> i_SSR,
		SS_O					=> SS_O,
		SCK_O					=> SCK_O,
		ready_for_transaction	=> o_Ready,
		TX_Valid				=> Tx_Not_Empty,
		read_enable				=> M_read_enable,
		write_enable			=> M_write_enable,
		inhibit                 => inhibit
		);
	
	Slave: Slave_block generic map
		(C_NUM_TRANSFER_BITS)
	port map(
		S_AXI_ACLK			=> SYS_CLK,
		SCK_I				=> SCK_I,
		RESETN				=> RESETN_I,
		TX_Valid			=> Tx_Not_Empty,
		TX_DATA_IN			=> i_TX_DATA,
		MOSI_I				=> MOSI_I,
		MISO_O				=> MISO_O,
		RX_DATA_OUT			=> S_RX_DATA,
		read_enable			=> S_read_enable,
		write_enable		=> S_write_enable,
		SPISEL				=> SPISEL,
		SPE					=> SPE,
		LSB_MSB				=> LSB_or_MSB,
		master_or_slave		=> master_or_slave
		);
		
	
	Tx_Not_Empty <= not Tx_Empty;

	-------------- Interrupts and SPICR latch --------------
	process(SYS_CLK, RESETN_I)
	begin
		if RESETN_I = '0' then
			SPICR <= "0110000000";
			o_MODF <= '0';
			o_Slave_MODF <= '0';
			o_slave_mode_select <= '1';
		
		elsif rising_edge(SYS_CLK) then
			if i_Reg_Ack = '1' then
				SPICR <= i_SPICR(9 downto 0);
			end if;
			
			if (SPICR(2) = '0' and SPISEL = '0') then
				o_slave_mode_select <= '0';
			else
				o_slave_mode_select <= '1';
			end if;
			
			if ((not SPISEL) and SPICR(2)) = '1' then
			    o_MODF <= '1';
			else
			    o_MODF <= '0';
			end if;
			
			if (not SPISEL and not master_or_slave and not SPE) = '1' then
			    o_Slave_MODF <= '1';
			else
			    o_Slave_MODF <= '0';
			end if;
			
		end if;
	end process;
	
	---------------- Master/Slave Mux -----------------
	Read_enable <= M_read_enable when SPICR(2) = '1' else
					S_read_enable;
	write_enable <= M_write_enable when SPICR(2) = '1' else
					S_write_enable;
					
	o_RX_DATA <= M_RX_DATA when SPICR(2) = '1' else
				 S_RX_DATA;
	
	-------------------- T-Ports ----------------------
	--	T-Ports are active-low enables:
	--	when '0' the corresponding signal is enabled
	--	when '1' the corresponding signal is 'Z'

	SCK_T <= not Master_or_Slave or not SPE; 
	MISO_T <= Master_or_Slave or not SPE;
	MOSI_T <= not Master_or_Slave or not SPE;
	SS_T <= (others => (not Master_or_Slave or not SPE));
	
	------------------ Control bits -------------------
	SPE 			<= SPICR(1);
	Master_or_Slave <= SPICR(2);
	Manual_SS 		<= SPICR(7);
	Master_Inhibit 	<= SPICR(8);
	LSB_or_MSB 		<= SPICR(9);
	
	--------------- loop-back operation ----------------
	MOSI_o <= loop_o;
	loop_i <= loop_o when SPICR(0) = '1' else
			  MISO_I;

end behaviour;