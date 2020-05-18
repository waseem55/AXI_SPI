

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
----------------- WT_1: --------------------------
	-- This test has to be done visually using
	-- the simulation waveform because the state
	-- signal is internal
	-- Set 'S_AXI_ARESETN' = '0' and check that wstate = idle
		wait until S_AXI_ARESETN = '1';
		
----------------- WT_2: --------------------------
	-- Prepare address and data on the write address and data channels
	-- This test case tests if 'S_AXI_AWREADY' becomes '0' after 
	-- 'S_AXI_AWVALID' is '1'
	
		wait until S_AXI_ACLK = '0';
		S_AXI_AWADDR <= X"A000000A";	-- preparing arbitrary test address
		S_AXI_WDATA <= X"000FF000";		-- preparing arbitrary test data
		S_AXI_AWVALID <= '0';
		S_AXI_WVALID <= '0';
		S_AXI_BREADY <= '0';
		
		wait for 30 ns;
		
		S_AXI_AWVALID <= '1';			-- write address is valid
		wait until S_AXI_AWREADY = '1' and S_AXI_AWVALID = '1' and rising_edge(S_AXI_ACLK);	-- conditions for WT_2
		wait for 1 ns;
		S_AXI_AWVALID <= '0';
		assert S_AXI_AWREADY = '0'		-- check that 'S_AXI_AWREADY' = '0'
		report "WT_2 failed: S_AXI_AWREADY /= '0'"
		severity warning;
		
----------------- WT_3: --------------------------
		-- This test case tests if 'S_AXI_WREADY' becomes '0' after 
		-- 'S_AXI_WVALID' is '1'
		
		S_AXI_WVALID <= '1';			-- write data is valid
		wait until S_AXI_WREADY = '1' and S_AXI_WVALID = '1' and rising_edge(S_AXI_ACLK);	-- conditions for WT_3
		wait for 1 ns;
		S_AXI_WVALID <= '0';
		assert S_AXI_WREADY = '0'		-- check that 'S_AXI_WREADY' = '0'
		report "WT_3 failed: S_AXI_WREADY /= '0'"
		severity warning;
		
----------------- WT_4: --------------------------
		-- This test case checks that the data and address info have been
		-- passed through to the internal register module
		
		wait until S_AXI_ACLk = '0';
		IntRdy <= '1';					-- indicates that the register module is ready to receive new data
		wait until wrequest = '1';		-- requests writing the data to the register
		wait until S_AXI_ACLK = '1';	
		assert INTWDATA = S_AXI_WDATA	-- check if the data has been passed through
		report "WT_4 failed: WDATA not latched"
		severity warning;
		
----------------- WT_5: --------------------------
		-- This test case tests if 'S_AXI_BVALID' becomes '0' after 
		-- 'S_AXI_BREADY' is '1'
		
		S_AXI_BREADY <= '1';
		wait until S_AXI_BREADY = '1' and S_AXI_BVALID = '1' and rising_edge(S_AXI_ACLK);	-- conditions for WT_5
		S_AXI_BREADY <= '0';
		assert S_AXI_BVALID = '0'		-- check that 'S_AXI_BVALID' = '0'
		report "WT_5 failed: S_AXI_BVALID /= '0'"
		severity warning;
		
	end process;

process 
begin 
--setting comparison values for address and data lines
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
S_AXI_ARADDR<="11111111111111111111111111111111";
read_data<="01010101010101010101010101010101";

----------- READ TEST CASE 1----------------------------------
-- checking reset functionality with no prior activity 
-- RT_1
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
assert (S_AXI_ARREADY = '0') and (S_AXI_RVALID='0') and (read_address="00000000000000000000000000000000") and (read_enable='0') 
report "all outgoing signals not low" severity failure;
------------- END TEST CASE 1 ---------------------------------


------------- READ TEST CASE 2 --------------------------------
--RT_2, RT_7
wait until S_AXI_ARESETN<='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
assert S_AXI_ARREADY = '1' report "S_AXI_ARREADY not properly set in idle state" severity failure;
------------- END TEST CASE 2 ---------------------------------


------------- READ TEST CASE 3 --------------------------------
--RT_3, RT_2, RT_4
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
S_AXI_ARVALID<='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
assert (read_enable='1') and (read_address=S_AXI_ARADDR) and (S_AXI_ARREADY='0') 
report "state transition did not occur or signals not properly changed" 
severity failure;
------------- END TEST CASE 3 --------------------------------


------------- READ TEST CASE 4 --------------------------------
-- RT_8, RT_9, RT_2
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
read_ack<='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
assert (S_AXI_RRESP= read_resp) and (S_AXI_RVALID = '1' ) and (S_AXI_RDATA=read_data) and (read_enable='0') and (read_address="00000000000000000000000000000000")
report "improper transition or lack of proper signal change" severity failure;

------------- END TEST CASE 4 ---------------------------------

------------- READ TEST CASE 5 --------------------------------
--RT_6, RT_5, RT_2
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
S_AXI_RREADY <='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
wait until S_AXI_ACLK'event and S_AXI_ACLK='1';
assert (S_AXI_ARREADY ='1') and (S_AXI_RVALID='0')
report "no proper transition to idle or signal change mistake"
severity failure;
------------- END TEST CASE 5 ---------------------------------

end process;
end test;


