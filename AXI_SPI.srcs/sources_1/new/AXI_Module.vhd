library ieee;
use ieee.std_logic_1164.all;

entity AXI_Module is 
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
	
	Error			: in std_logic_vector(1 downto 0);
	IntRdy			: in std_logic;
	Wdata			: out std_logic_vector(31 downto 0);
	Waddr			: out std_logic_vector(31 downto 0)
	
	);
end AXI_Module;

architecture behavior of AXI_Module is

type write_state is (idle, ready, write, response); 
signal wstate 					: write_state;		-- State machine
signal got_addr, got_data 		: std_logic;		-- To signal receiving VALID for addr and data
signal wdata_temp, waddr_temp 	: std_logic_vector(31 downto 0);	-- temp storage for addr and data

begin

	State_Machine: process(S_AXI_ACLK, S_AXI_ARESETN)
	begin
		if S_AXI_ARESETN = '0' then
			wstate <= idle;
		elsif rising_edge(S_AXI_ACLK) then
			case wstate is
			when idle =>
				if S_AXI_ARESETN = '1' then
					wstate <= ready;
				end if;
			when ready =>
				if (got_addr = '1' and got_data = '1') then
					wstate <= write;
				end if;
			when write =>
				if IntRdy = '1' then
					wstate <= response;
				end if;
			when response =>
				if S_AXI_BREADY = '1' then
					wstate <= ready;
				end if;
			end case;
		end if;
	end process;
	
	process(S_AXI_ACLK, S_AXI_ARESETN)
	begin
		if rising_edge(S_AXI_ACLK) then
			case wstate is
			when idle =>
				S_AXI_AWREADY <= '0';
				S_AXI_WREADY <= '0';
				S_AXI_BRESP <= "00";
				S_AXI_BVALID <= '0';
				got_addr <= '0';
				got_data <= '0';
				waddr_temp <= (others => '0');
				wdata_temp <= (others => '0');
				waddr <= (others => '0');
				wdata <= (others => '0');
			when ready =>
				if (S_AXI_AWVALID = '1' and got_addr = '0') then
					got_addr <= '1';
					waddr_temp <= S_AXI_AWADDR;
				end if;
				if (S_AXI_WVALID = '1' and got_data = '0') then
					got_data <= '1';
					wdata_temp <= S_AXI_WDATA;
				end if;
			when write =>
				if IntRdy = '1' then
					waddr <= waddr_temp;
					wdata <= wdata_temp;
				end if;
			when response =>
				S_AXI_BRESP <= Error;
				S_AXI_BVALID <= '1';
			end case;
		end if;
	end process;
			
				
	
	
	
	
	
	
	
	
	
	
end behavior;