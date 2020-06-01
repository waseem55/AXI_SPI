library ieee;
use ieee.std_logic_1164.all;

package component_pckg is

component Slave_Block
	generic(
		C_NUM_TRANSFER_BITS	: integer := 8
		);
	port(
		S_AXI_ACLK: std_logic;
		SCK_I: in std_logic;
		RESETN: in std_logic;
		
		--Lines for communicating with TX_FIFO
		TX_Valid: in std_logic;
		TX_DATA_IN: in std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
		
		--MOSI/MISO serial data lines
		MOSI_I: in std_logic;
		MISO_O: out std_logic;
		
		--tri-state buffer enable 
--		MISO_T: out std_logic;
		
		--Lines for communicating with RX_FIFO
		RX_DATA_OUT: out std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
		
		--read_enable for TX FIFO
		read_enable: out std_logic;
		
		--write_enable for RX_FIFO
		write_enable: out std_logic;
		
		--control bits
		SPISEL: in std_logic;
		SPE: in std_logic;
		LSB_MSB: in std_logic;
		master_or_slave: in std_logic
		);
end component;

component Master_Block

	generic(
		C_NUM_TRANSFER_BITS: integer := 8; -- sets expected number of bits in a transfer and size of shift register
		C_NUM_SS_BITS: integer := 1); -- size of slave select output
	
	port(
		-- system reset and clock
		S_AXI_ACLK: in std_logic; -- Master and slave coordinated to AXI system clock
		RESETN: in std_logic; -- system reset which is set by SRR reset or S_AXI_ARESETN
			
		--input data ports
		MISO_I: in std_logic; -- serial data in from MISO_I
		Data_In_Parallel: in std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); -- parallel data in from SPIDTR
		
		-- output data ports
		MOSI_O: out std_logic; -- serial data out to MOSI_O
		Data_Out_Parallel: out std_logic_vector((C_NUM_TRANSFER_BITS-1) downto 0); -- parallel output to SPIDRR
		
		-- control inputs
		Master_or_Slave: in std_logic; -- SPICR bit signaling whether device is in master or slave mode
		Master_Inhibit: in std_logic; -- SPICR bit, inhibits master transactions
		LSB_or_MSB: in std_logic; -- SPICR bit controlling whether data is transmitted LSB or MSB first style
		SPE: in std_logic; -- SPI system enable bit from SPICR 
		Manual_Slave_Select: in std_logic; -- bit controlling whether a transaction happens in manual or automatic slave select mode
		
		-- Slave select register contents
		SSR: in std_logic_vector(31 downto 0);
		
		-- tri-state enable output for multi-master bus arbitration and preventing errors in slave mode
--		MOSI_T: inout std_logic;
		
		-- slave select line output 
		SS_O: out std_logic_vector(C_NUM_SS_BITS-1 downto 0);
		
		--SCK pulse output
		SCK_O: inout std_logic; 
		
		-- signals master is ready for SW to start a new transaction
		ready_for_transaction: inout std_logic;
		
		--data valid pulse from the Tx_FIFO
		TX_Valid: in std_logic;
		
		--read_enable for TX_FIFO
        read_enable: out std_logic;
            
        --write_enable for RX_FIFO
        write_enable: out std_logic
		);
end component;

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
	o_Slave_MODF        : out std_logic;
	o_slave_mode_select	: out std_logic;
	IP2INTC_IRPT		: out std_logic
	);
end component;

component AXI_Module
port(
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
	
	-- Internal Write Ports
	
	Error			: in std_logic_vector(1 downto 0);		-- Repsonse code from top entity
	IntRdy			: in std_logic;							-- Ready to write from top entity
	Wrequest		: out std_logic;						-- request to write to registers
	WSTB			: out std_logic_vector(3 downto 0);
	Wdata			: out std_logic_vector(31 downto 0);
	Waddr			: out std_logic_vector(31 downto 0);
	
	-- Internal Read Ports
	
	read_enable		: out std_logic;
	read_address	: out std_logic_vector(31 downto 0);
	read_data		: in std_logic_vector(31 downto 0);
	read_ack		: in std_logic;
	read_resp		: in std_logic_vector(1 downto 0)
	);
end component;

end component_pckg;