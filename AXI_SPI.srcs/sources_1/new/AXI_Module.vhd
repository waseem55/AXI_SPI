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
	
	Error			: in std_logic_vector(1 downto 0);		-- Repsonse code from top entity
	IntRdy			: in std_logic;							-- Ready to write from top entity
	Wrequest		: out std_logic;						-- request to write to registers
	WSTB			: out std_logic_vector(1 downto 0);
	Wdata			: out std_logic_vector(31 downto 0);
	Waddr			: out std_logic_vector(31 downto 0)
	
	);
end AXI_Module;

architecture behavior of AXI_Module is

type write_state is (idle, ready, write, response); 
signal wstate 					: write_state;		-- State machine
signal awready, wready, bvalid	: std_logic;		-- Temp signals for output
signal got_addr, got_data 		: std_logic;		-- To latch data and addr when VALID is received
signal got_rdy					: std_logic;		-- To let BVALID be set and reset in response state
signal wdata_temp, waddr_temp 	: std_logic_vector(31 downto 0);	-- temp storage for addr and data

begin
	
	S_AXI_AWREADY <= awready;
	S_AXI_WREADY  <= wready;
	S_AXI_BVALID  <= bvalid;
	WSTB		  <= S_AXI_WSTB;
	
	State_Machine: process(S_AXI_ACLK, S_AXI_ARESETN)
	begin
		if S_AXI_ARESETN = '0' then
			wstate <= idle;
		elsif rising_edge(S_AXI_ACLK) then
			case wstate is
			when idle =>						-- Idle state
				if S_AXI_ARESETN = '1' then
					wstate <= ready;
				end if;
			when ready =>						-- Default state when resetn is '1', ready signals are '1'
				if (got_addr = '1' and got_data = '1') then
					wstate <= write;
				end if;
			when write =>						-- Send data to register when top entity is ready
				if IntRdy = '1' then
					wstate <= response;
				end if;
			when response =>					-- Sending response signal
				if (S_AXI_BREADY = '1' and bvalid = '1') then
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
				awready <= '0';
				wready  <= '0';
				S_AXI_BRESP <= "00";
				bvalid <= '0';
				Wrequest <= '0';
				got_addr <= '0';
				got_data <= '0';
				got_rdy  <= '0';
				waddr_temp <= (others => '0');
				wdata_temp <= (others => '0');
				waddr <= (others => '0');
				wdata <= (others => '0');
			when ready =>
				got_rdy <= '0';
				bvalid <= '0';
				if got_addr = '0' then
					if (S_AXI_AWVALID = '1' and awready = '1') then
						got_addr <= '1';
						waddr_temp <= S_AXI_AWADDR;
						awready <= '0';
					else
						awready <= '1';
					end if;
				end if;
				if got_data = '0' then
					if (S_AXI_WVALID = '1' and wready = '1') then
						got_data <= '1';
						wdata_temp <= S_AXI_WDATA;
						wready <= '0';
					else
						wready <= '1';
					end if;
				end if;
			when write =>
				Wrequest <= '1';
				if IntRdy = '1' then
					waddr <= waddr_temp;
					wdata <= wdata_temp;
				end if;
				got_addr <= '0';
				got_data <= '0';
			when response =>
				Wrequest <= '0';
				S_AXI_BRESP <= Error;
				if (S_AXI_BREADY = '1' and bvalid = '1') then
					bvalid <= '0';
				else
					bvalid <= '1';
				end if;
			end case;
		end if;
	end process;
	
end behavior;