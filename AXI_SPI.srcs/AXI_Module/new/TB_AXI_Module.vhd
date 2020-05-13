library ieee;
use ieee.std_logic_1164.all;

entity TB_AXI_Module is
end TB_AXI_Module;

architecture Test of TB_AXI_Module is

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
	
	-- Internal Ports
	
	Error			: in std_logic_vector(1 downto 0);		-- Repsonse code from top entity
	IntRdy			: in std_logic;							-- Ready to write from top entity
	Wrequest		: out std_logic;						-- request to write to registers
	Wdata			: out std_logic_vector(31 downto 0);
	Waddr			: out std_logic_vector(31 downto 0)
	
	);
end component;

signal ACLK, ARESETN, AWVALID, WVALID, AWREADY, WREADY, BVALID, BREADY : std_logic := '0';
signal IntRdy, Wrequest	 	: std_logic := '0';
signal AWADDR, WDATA 		: std_logic_vector(31 downto 0) := (others => '0');
signal INTAWADDR, INTWDATA 	: std_logic_vector(31 downto 0) := (others => '0');
signal WSTB 				: std_logic_vector(3 downto 0) := (others => '0');
signal BRESP, Error			: std_logic_vector(1 downto 0) := (others => '0');

begin

	DUT : AXI_Module port map(
	S_AXI_ACLK 		=> ACLK, 
	S_AXI_ARESETN	=> ARESETN,
	S_AXI_AWADDR	=> AWADDR,
	S_AXI_AWVALID	=> AWVALID,
	S_AXI_AWREADY	=> AWREADY,
	S_AXI_WDATA		=> WDATA,
	S_AXI_WSTB		=> "0000",
	S_AXI_WVALID	=> WVALID,
	S_AXI_WREADY	=> WREADY,
	S_AXI_BRESP		=> BRESP,
	S_AXI_BVALID	=> BVALID,
	S_AXI_BREADY	=> BREADY,
	S_AXI_ARADDR	=> X"FFFFFFFF",
	S_AXI_ARVALID	=> '0',
	S_AXI_ARREADY	=> open,
	S_AXI_RDATA		=> open,
	S_AXI_RRESP		=> open,
	S_AXI_RVALID	=> open,
	S_AXI_RREADY	=> '0',
	
	-- Internal Ports
	
	Error			=> Error,
	IntRdy			=> IntRdy,
	Wrequest		=> Wrequest,
	Wdata			=> INTWDATA,
	Waddr			=> INTAWADDR
	);

	ACLK <= not ACLK after 5 ns;
	ARESETN <= '0', '1' after 20 ns;
	
	process
	begin
		wait until ARESETN = '1';
		wait until ACLK = '0';
		AWADDR <= X"A000000A";
		WDATA <= X"000FF000";
		AWVALID <= '0';
		WVALID <= '0';
		BREADY <= '0';
		
		wait for 30 ns;
		
		AWVALID <= '1';
		wait until AWREADY = '1' and ACLK = '1';
		AWVALID <= '0';
		WVALID <= '1';
		wait until WREADY = '1' and ACLK = '1';
		WVALID <= '0';
		wait until ACLk = '0';
		IntRdy <= '1';
--		wait for 30 ns;
		BREADY <= '1';
		wait for 45 ns;
		BREADY <= '0';
		
	end process;
end test;
		
