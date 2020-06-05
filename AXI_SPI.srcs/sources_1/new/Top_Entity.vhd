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
	C_NUM_TRANSFER_BItS	: integer := 8;
	C_BASEADDR          : std_logic_vector(31 downto 0) := X"00000000"
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

signal RESETN               : std_logic;

-------------- SPI Intermediate Signals -----------
signal MODF_level           : std_logic;
signal Slave_MODF_level     : std_logic;
signal slave_m_select_level : std_logic;

------------- AXI Intermediate Signals --------------
signal WSTB                 : std_logic_vector(3 downto 0);
signal AXI_WDATA            : std_logic_vector(31 downto 0);
signal AXI_WADDR            : std_logic_vector(31 downto 0);
signal AXI_RDATA            : std_logic_vector(31 downto 0);
signal AXI_RADDR            : std_logic_vector(31 downto 0);
signal AXI_wrequest         : std_logic;
signal AXI_rrequest         : std_logic;

---------- FIFO Intermediate Signals ------------
signal TXFIFO_data_in       : std_logic_vector(C_NUM_TRANSFER_BITS -1 downto 0);
signal TXFIFO_data_out      : std_logic_vector(C_NUM_TRANSFER_BITS -1 downto 0);
signal RXFIFO_data_in       : std_logic_vector(C_NUM_TRANSFER_BITS -1 downto 0);
signal RXFIFO_data_out      : std_logic_vector(C_NUM_TRANSFER_BITS -1 downto 0);
signal TXFIFO_empty_flag    : std_logic;
signal TXFIFO_full_flag     : std_logic;
signal RXFIFO_empty_flag    : std_logic;
signal RXFIFO_full_flag     : std_logic;
signal TXFIFO_read_pulse    : std_logic;
signal TXFIFO_write_pulse   : std_logic;
signal RXFIFO_read_pulse    : std_logic;
signal RXFIFO_write_pulse   : std_logic;

---------- Register Module Intermediate Signals -----------
signal SRR                  : std_logic_vector(31 downto 0);
signal SPICR                : std_logic_vector(31 downto 0);
signal SPISR                : std_logic_vector(31 downto 0);
signal SPIDTR               : std_logic_vector(31 downto 0);
signal SPIDRR               : std_logic_vector(31 downto 0);
signal SPISSR               : std_logic_vector(31 downto 0);
signal TX_FIFO_OCY          : std_logic_vector(31 downto 0);
signal RX_FIFO_OCY          : std_logic_vector(31 downto 0);
signal DGIER                : std_logic_vector(31 downto 0);
signal IPISR                : std_logic_vector(31 downto 0);
signal IPIER                : std_logic_vector(31 downto 0);
signal Reg_Ack              : std_logic;
signal AXI_Read_Ack         : std_logic;
signal Write_error          : std_logic_vector(1 downto 0);
signal Read_error           : std_logic_vector(1 downto 0);

begin

	SPI: SPI_Module
	generic map(
		C_SCK_RATIO			=> C_SCK_RATIO,
		C_NUM_SS_BITS		=> C_NUM_SS_BITS,
		C_NUM_TRANSFER_BItS	=> C_NUM_TRANSFER_BItS
	)
	port map(
		SYS_CLK				=> S_AXI_ACLK,
		RESETN_I			=> RESETN,
		                     
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
		o_Ready				=> open,
		i_TX_DATA			=> TXFIFO_data_out,
		o_RX_DATA			=> RXFIFO_data_in,
		i_SPISSR		    => SPISSR,
		                     
		-- To/From FIFOs     
		Tx_Empty			=> TXFIFO_empty_flag,
		read_enable			=> TXFIFO_read_pulse,
		write_enable		=> RXFIFO_write_pulse,
		                     
		-- To and from regisers
		i_Reg_Ack			=> Reg_Ack,
		i_SPICR				=> SPICR,
		o_MODF				=> MODF_level,
		o_Slave_MODF        => Slave_MODF_level,
		o_slave_mode_select	=> slave_m_select_level,
		IP2INTC_IRPT		=> 
		);
	
	AXI: AXI_Module
	port map(
		S_AXI_ACLK 		=> S_AXI_ACLK,
		S_AXI_ARESETN	=> RESETN,
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
	
		Error			=> Write_error,
		IntRdy			=> ,                    -- to do
		Wrequest		=> AXI_wrequest,        -- to do
		WSTB			=> WSTB,
		Wdata			=> AXI_WDATA,
		Waddr			=> AXI_WADDR,
		
		-- Internal Read Ports
		
		read_enable		=> AXI_rrequest,
		read_address	=> AXI_RADDR,
		read_data		=> AXI_RDATA,
		read_ack		=> AXI_Read_Ack,
		read_resp		=> Read_error
		);

    Registers: Register_Module
    generic map(
        C_BASEADDR          => C_BASEADDR,
        C_NUM_TRANSFER_BITS => C_NUM_TRANSFER_BITS
        )
    port map(
        i_CLK               => S_AXI_ACLK,
        i_RESETN            => RESETN,
        
        ------------- SPISR internal bits ----------------
        -- SPISR signals are levels coming from the top entity
        i_RX_EMPTY          => RXFIFO_empty_flag,
        i_RX_FULL           => RXFIFO_full_flag,
        i_TX_EMPTY          => TXFIFO_empty_flag,
        i_TX_FULL           => TXFIFO_full_flag,
        i_MODF              => MODF_level,
        i_Slave_Mode_Select => slave_m_select_level,
        
        o_REG_ACk           => Reg_Ack,
        
        ------------------- To/From FIFOs ---------------------
        i_TX_FIFO_OCY       => ,
        i_RX_FIFO_OCY       => ,
        i_RX_FIFO           => RXFIFO_data_out,
        o_RPULSE            => RXFIFO_read_pulse,
        o_WPULSE            => TXFIFO_write_pulse,
        o_TX_FIFO           => TXFIFO_data_in,
        
        ---------------- IPISR toggling strobes ------------------
        -- IPISR signals are pulses coming from the top entity
        i_MODF_INTERRUPT    => ,
        i_Slave_MODF        => ,
        i_DTR_EMPTY         => ,
        i_DTR_UNDERRUN      => ,
        i_DRR_FULL          => ,
        i_DRR_OVERRUN       => ,
        i_TX_FIFO_HALFEMPTY => ,
        i_SLAVE_MODE_SELECT_INTERRUPT => ,
        i_DRR_NOT_EMPTY     => ,
        
        -------------------- Registers -------------------------
        o_SRR               => SRR,
        o_SPICR             => SPICR,
        o_SPISR             => SPISR,
        o_SPIDTR            => SPIDTR,
        o_SPIDRR            => SPIDRR,
        o_SPISSR            => SPISSR,
        o_TX_FIFO_OCY       => TX_FIFO_OCY,
        o_RX_FIFO_OCY       => RX_FIFO_OCY,
        o_DGIER             => DGIER,
        o_IPISR             => IPISR,
        o_IPIER             => IPIER,
        
        -------------------- AXI Ports -------------------------
        i_WREQUEST          => ,
        i_RREQUEST          => AXI_rrequest,
        o_AXI_READ_ACK      => AXI_Read_Ack,
        o_WRITE_ERROR       => Write_error,
        o_READ_ERROR        => Read_error,
        i_WSTB              => WSTB,
        i_WADDR             => AXI_WADDR,
        i_RADDR             => AXI_RADDR,
        i_DATA              => AXI_WDATA,
        o_DATA              => AXI_RDATA
        
        );

    TX_FIFO: FIFO
    generic map(
        depth               => 16,
		width               => C_NUM_TRANSFER_BITS
		)
    port map(
        wdata               => TXFIFO_data_in,
        w_enable            => TXFIFO_write_pulse,
        r_enable            => TXFIFO_read_pulse,
        reset               => RESETN,
        clk                 => S_AXI_ACLK,
        rdata               => TXFIFO_data_out,
        full_flag           => TXFIFO_full_flag,
        empty_flag          => TXFIFO_empty_flag
        );

    RX_FIFO: FIFO
    generic map(
        depth               => 16,
		width               => C_NUM_TRANSFER_BITS
		)
    port map(
        wdata               => RXFIFO_data_in,
        w_enable            => RXFIFO_write_pulse,
        r_enable            => RXFIFO_read_pulse,
        reset               => RESETN,
        clk                 => S_AXI_ACLK,
        rdata               => RXFIFO_data_out,
        full_flag           => RXFIFO_full_flag,
        empty_flag          => RXFIFO_empty_flag
        );

end RTL;