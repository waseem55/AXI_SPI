-- For MODF/SlaveMODf/Slave_Select_Mode the SPI generates levels
-- and top entity has to generate pulses out of them if pulses are
-- required by registers for toggling as mentioned in register tables
-- on data sheet            to do
-- example of pulse:
--if MODF = '0' then
--				prev_MODF <= '0';
--				o_MODF <= '0';
--			elsif MODF = '1' then
--				if prev_MODF = '0' then
--					o_MODF <= '1';
--					prev_MODF <= '1';
--				else
--					o_MODF <= '0';
--				end if;
--			end if;


library ieee;
use ieee.std_logic_1164.all;
use work.component_pckg.all;

entity Top_Entity is
generic(
	C_SCK_RATIO			: integer := 4;
	C_NUM_SS_BITS		: integer := 1;
	C_NUM_TRANSFER_BItS	: integer := 8
	);
port(
	--------------- AXI Ports 	--------------- 
	S_AXI_ACLK 		: in std_logic;
	S_AXI_ARESETN	: in std_logic;
	S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	S_AXI_AWVALID	: in std_logic;
	S_AXI_AWREADY	: out std_logic;
	S_AXI_WDATA		: in std_logic_vector(31 downto 0);
	S_AXI_WSTB		: in std_logic_vector(3 downto 0);
	S_AXI_WVALID	: in std_logic;
	S_AXI_WREADY	: out std_logic;
	S_AXI_BRESP		: out std_logic_vector(1 downto 0);
	S_AXI_BVALID	: out std_logic;
	S_AXI_BREADY	: in std_logic;
	S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	S_AXI_ARVALID	: in std_logic;
	S_AXI_ARREADY	: out std_logic;
	S_AXI_RDATA		: out std_logic_vector(31 downto 0);
	S_AXI_RRESP		: out std_logic_vector(1 downto 0);
	S_AXI_RVALID	: out std_logic;
	S_AXI_RREADY	: in std_logic;
	
	--------------- SPI Ports 	--------------- 
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
	SS_T				: out std_logic_vector(C_NUM_SS_BITS-1 downto 0)
	);
end Top_Entity;

architecture RTL of Top_Entity is

begin

	SPI: SPI_Module
	generic map(
		C_SCK_RATIO			=> C_SCK_RATIO,
		C_NUM_SS_BITS		=> C_NUM_SS_BITS,
		C_NUM_TRANSFER_BItS	=> C_NUM_TRANSFER_BItS
	)
	port map(
		SYS_CLK				=> S_AXI_ACLK,
		RESETN_I			=> S_AXI_ARESETN,
		                     
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
		o_Ready				=> ,
		i_TX_DATA			=> ,
		o_RX_DATA			=> ,
		i_SSR				=> ,
		                     
		-- To/From FIFOs     
		Tx_Empty			=> ,
		read_enable			=> ,
		write_enable		=> ,
		                     
		-- To and from regisers
		i_Reg_Ack			=> ,
		i_SPICR				=> ,
		o_MODF				=> ,
		o_slave_mode_select	=> ,
		IP2INTC_IRPT		=> 
		);
	
	AXI: AXI_Module
	port map(
		S_AXI_ACLK 		=> S_AXI_ACLK,
		S_AXI_ARESETN	=> S_AXI_ARESETN,
		S_AXI_AWADDR	=> S_AXI_AWADDR,
		S_AXI_AWVALID	=> S_AXI_AWVALID,
		S_AXI_AWREADY	=> S_AXI_AWREADY,
		S_AXI_WDATA		=> S_AXI_WDATA,
		S_AXI_WSTB		=> S_AXI_WSTB,
		S_AXI_WVALID	=> S_AXI_WVALID,
		S_AXI_WREADY	=> S_AXI_WREADY,
		S_AXI_BRESP		=> S_AXI_BRESP,
		S_AXI_BVALID	=> S_AXI_BVALID,
		S_AXI_BREADY	=> S_AXI_BREADY,
		S_AXI_ARADDR	=> S_AXI_ARADDR,
		S_AXI_ARVALID	=> S_AXI_ARVALID,
		S_AXI_ARREADY	=> S_AXI_ARREADY,
		S_AXI_RDATA		=> S_AXI_RDATA,
		S_AXI_RRESP		=> S_AXI_RRESP,
		S_AXI_RVALID	=> S_AXI_RVALID,
		S_AXI_RREADY	=> S_AXI_RREADY,
		
		-- Internal Write Ports
	
		Error			=> ,
		IntRdy			=> ,
		Wrequest		=> ,
		WSTB			=> ,
		Wdata			=> ,
		Waddr			=> ,
		
		-- Internal Read Ports
		
		read_enable		=> ,
		read_address	=> ,
		read_data		=> ,
		read_ack		=> ,
		read_resp		=> 
		);








end RTL;