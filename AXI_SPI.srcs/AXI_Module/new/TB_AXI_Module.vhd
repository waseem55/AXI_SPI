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
	
	-- Write Internal Ports
	
	Error			: in std_logic_vector(1 downto 0);		-- Repsonse code from top entity
	IntRdy			: in std_logic;							-- Ready to write from top entity
	Wrequest		: out std_logic;						-- request to write to registers
	Wdata			: out std_logic_vector(31 downto 0);
	Waddr			: out std_logic_vector(31 downto 0);
	
	-- Read Internal Ports
	
	read_enable		: out std_logic;
	read_address	: out std_logic_vector(31 downto 0);
	read_data		: in std_logic_vector(31 downto 0);
	read_ack		: in std_logic;
	read_resp		: in std_logic_vector(1 downto 0)
	);
end component;

signal S_AXI_ACLK			: std_logic := '0';
signal S_AXI_ARESETN		: std_logic := '0';
signal S_AXI_AWADDR			: std_logic_vector(31 downto 0) := (others => '0');
signal S_AXI_AWVALID		: std_logic := '0';
signal S_AXI_AWREADY		: std_logic;
signal S_AXI_WDATA			: std_logic_vector(31 downto 0) := (others => '0');
signal S_AXI_WSTB			: std_logic_vector(3 downto 0) := (others => '0');
signal S_AXI_WVALID			: std_logic := '0';
signal S_AXI_WREADY			: std_logic;
signal S_AXI_BRESP			: std_logic_vector(1 downto 0) := "00";
signal S_AXI_BVALID			: std_logic;
signal S_AXI_BREADY			: std_logic := '0';

signal S_AXI_ARADDR			: std_logic_vector(31 downto 0) := (others => '0');
signal S_AXI_ARVALID		: std_logic := '0';
signal S_AXI_ARREADY		: std_logic;
signal S_AXI_RDATA			: std_logic_vector(31 downto 0);
signal S_AXI_RRESP			: std_logic_vector(1 downto 0);
signal S_AXI_RVALID			: std_logic;
signal S_AXI_RREADY			: std_logic := '0';

signal Error				: std_logic_vector(1 downto 0) := "00";
signal IntRdy				: std_logic := '0';
signal Wrequest				: std_logic := '0';
signal INTWDATA				: std_logic_vector(31 downto 0) := (others => '0');
signal INTAWADDR			: std_logic_vector(31 downto 0) := (others => '0');
	
signal read_enable 			: std_logic;
signal read_address			: std_logic_vector(31 downto 0);
signal read_data			: std_logic_vector(31 downto 0);
signal read_ack				: std_logic := '0';
signal read_resp			: std_logic_vector(1 downto 0);

begin

	DUT : AXI_Module port map(
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
	
	-- Write Internal Ports
	
	Error			=> Error,
	IntRdy			=> IntRdy,
	Wrequest		=> Wrequest,
	Wdata			=> INTWDATA,
	Waddr			=> INTAWADDR,
	
	-- Read Internal Ports
	
	read_enable		=> read_enable,
	read_address	=> read_address,
	read_data		=> read_data,
	read_ack		=> read_ack,
	read_resp		=> read_resp
	);

	S_AXI_ACLK <= not S_AXI_ACLK after 5 ns;
	S_AXI_ARESETN <= '0', '1' after 20 ns;
	
	process
	begin
		wait until S_AXI_ARESETN = '1';
		wait until S_AXI_ACLK = '0';
		S_AXI_AWADDR <= X"A000000A";
		S_AXI_WDATA <= X"000FF000";
		S_AXI_AWVALID <= '0';
		S_AXI_WVALID <= '0';
		S_AXI_BREADY <= '0';
		
		wait for 30 ns;
		
		S_AXI_WVALID <= '1';
		wait until S_AXI_AWREADY = '1' and S_AXI_ACLK = '1';
		S_AXI_WVALID <= '0';
		S_AXI_AWVALID <= '1';
		wait until S_AXI_ACLK = '1';
		S_AXI_AWVALID <= '0';
		wait until S_AXI_ACLk = '0';
		IntRdy <= '1';
--		wait for 30 ns;
		S_AXI_BREADY <= '1';
		wait for 45 ns;
		S_AXI_BREADY <= '0';
		
	end process;

	process 
	begin 
		wait for 200ns;
		wait for 6ns;
		wait until S_AXI_ACLK='1';
		wait until S_AXI_ACLK='1';
		wait until S_AXI_ACLK='1';
		wait until S_AXI_ACLK='1';
		S_AXI_ARADDR<="11111111111111111111111111111111";
		S_AXI_ARVALID<='1';
		wait until S_AXI_ACLK='1'; -- address data and read enable is latched to internal signal
		S_AXI_ARVALID<='0';
		wait until S_AXI_ACLK='1'; -- waiting for register to retrieve data
		wait until S_AXI_ACLK='1'; -- on this clock edge it is simulated that register module sets the acknowledge bit.  read enable and address are reset 
		read_data<="01010101010101010101010101010101";
		read_ack<='1';
		read_resp<= "11";
		
		wait until S_AXI_ACLK ='1'; -- at this point valid and rdata and resp should be set to register module returned values.  read enable and read address reset
		S_AXI_RREADY<='1';--setting master ready to recieve data.  one clock edge later sm switches to idle state.  
		wait until S_AXI_ACLK ='1'; -- new transaction should be allowed during these clock cycles
		wait until S_AXI_ACLK ='1'; -- arready back to 1
		wait until S_AXI_ACLK ='1'; -- can begin new transaction
		wait until S_AXI_ACLK ='1'; 
		S_AXI_ARVALID<='1';
		if S_AXI_ARREADY = '1' then
			wait until S_AXI_ACLK = '1';
			S_AXI_ARVALID<='0';
		end if;
		--S_AXI_ARESETN<='0'; -- no new transaction should start from here on.  
		wait;
	
	end process;
	
end test;



