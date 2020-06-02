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
	
end AXI_Module;

architecture behavior of AXI_Module is

type write_state is (idle, ready, write, response); 
signal wstate 					: write_state;		-- Write state machine
signal awready, wready, bvalid	: std_logic;		-- Temp signals for output
signal got_addr, got_data 		: std_logic;		-- To latch data and addr when VALID is received
signal wdata_temp, waddr_temp 	: std_logic_vector(31 downto 0);	-- temp storage for addr and data

type read_state is (idle, wait_for_address_valid, wait_for_ack, wait_master_read_ready); -- Read state machine
signal rstate : read_state;

begin
	
	S_AXI_AWREADY <= awready;
	S_AXI_WREADY  <= wready;
	S_AXI_BVALID  <= bvalid;
	WSTB		  <= S_AXI_WSTB;
	
	---------------------- Write Operation ---------------------
	
	Write_state_Machine: process(S_AXI_ACLK, S_AXI_ARESETN)	-- State transition conditions
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
		if S_AXI_ARESETN = '0' then		-- Asynchronous reset
			awready <= '0';
				wready  <= '0';
				S_AXI_BRESP <= "00";
				bvalid <= '0';
				Wrequest <= '0';
				got_addr <= '0';
				got_data <= '0';
				waddr_temp <= (others => '0');
				wdata_temp <= (others => '0');
				waddr <= (others => '0');
				wdata <= (others => '0');
		elsif rising_edge(S_AXI_ACLK) then
			case wstate is
			when idle =>
				awready <= '0';
				wready  <= '0';
				S_AXI_BRESP <= "00";
				bvalid <= '0';
				Wrequest <= '0';
				got_addr <= '0';		-- Used to be able to latch address in Ready state
				got_data <= '0';		-- Used to be able to latch data in Ready state
				waddr_temp <= (others => '0');
				wdata_temp <= (others => '0');
				waddr <= (others => '0');
				wdata <= (others => '0');
			when ready =>
				bvalid <= '0';
				if got_addr = '0' then	-- If didn't latch an address last clk
					if (S_AXI_AWVALID = '1' and awready = '1') then	-- Condition to latch address
						got_addr <= '1';
						waddr_temp <= S_AXI_AWADDR;		-- Latch address
						awready <= '0';					-- Deassert AWREADY signal
					else
						awready <= '1';					-- Default state (when no valid address is present on the line)
					end if;
				end if;
				if got_data = '0' then	-- If didn't latch any data last clk
					if (S_AXI_WVALID = '1' and wready = '1') then -- Condition to latch data
						got_data <= '1';
						wdata_temp <= S_AXI_WDATA;		-- Latch data
						wready <= '0';					-- Deassert WREADY signal
					else
						wready <= '1';					-- Default state (when no valid data is present on the line)
					end if;
				end if;
			when write =>
				Wrequest <= '1';						-- Request to write data on the addressed register
				if IntRdy = '1' then					-- Input from top module indicating that it's ready to write to register
					waddr <= waddr_temp;
					wdata <= wdata_temp;
				end if;
				got_addr <= '0';						-- Reset for next transaction
				got_data <= '0';						-- Reset for next transaction
			when response =>
				Wrequest <= '0';						-- Reset for next transaction
				S_AXI_BRESP <= Error;					-- Send Error info through Response channel
				if (S_AXI_BREADY = '1' and bvalid = '1') then	-- Condition to reset BVALID
					bvalid <= '0';
				else
					bvalid <= '1';
				end if;
			end case;
		end if;
	end process;
	
	---------------------- Read Operation ---------------------
	
	process (S_AXI_ACLK, S_AXI_ARESETN)
	begin
		if S_AXI_ARESETN = '0' then -- asynchronous reset
			read_enable <= '0';
			S_AXI_ARREADY <= '0';
			read_address <= (others => '0');
			S_AXI_RDATA  <= (others => '0');
			S_AXI_RVALID <= '0';
			S_AXI_RRESP <= "00";
			rstate <= idle;
			
		elsif rising_edge(S_AXI_ACLK) then 
			case (rstate) is 
					when idle => 
						if S_AXI_ARESETN='0' then -- prevents unwanted behavior if reset gets triggered mid transaction and state becomes idle.  
							read_enable<='0';
							S_AXI_ARREADY<='0';
							read_address<=(others => '0');
							S_AXI_RVALID<='0';
							S_AXI_RRESP<="00";
							S_AXI_RDATA <= (others => '0');
							rstate<=idle;
						elsif S_AXI_ARESETN = '1' then -- exits reset state on the nearest clock edge
							S_AXI_ARREADY<='1'; -- makes AXI interface ready to receive address and initiate new transaction
							rstate<=wait_for_address_valid;
						
						end if;
						
					when wait_for_address_valid => 
						if S_AXI_ARVALID = '1' then --next stage of transaction occurs when a valid address becomes available
							read_address<=S_AXI_ARADDR; -- stores incoming address on outgoing address line to register module
							read_enable<='1'; -- read enable to signal a read request to register module
							S_AXI_ARREADY<='0'; -- prevents another address from being accepted until the current transaction is completed
							rstate<=wait_for_ack; 
							
						end if;
						
					when wait_for_ack => 
					    read_enable<='0';
						if read_ack = '1' then --read_ack signals new valid data on the line.  registers/top entity must make signal must go low before next transaction initiated.  
							S_AXI_RDATA<=read_data; -- puts data incoming from register onto the read data line 
							S_AXI_RVALID<='1'; -- tells master that valid data is on the line
							S_AXI_RRESP<=read_resp;
							read_address<= (others => '0');
							rstate<=wait_master_read_ready;
						end if;
					when wait_master_read_ready => 
						if S_AXI_RREADY ='1' then -- waits until the master says it is ready to receive data 
							S_AXI_RVALID <='0'; -- rvalid goes low and both slave and master recognize the end of the current transaction.  
							
							rstate<=idle; -- back to idle and normal operation. RDATA and RRESP stay the same until changed in the next transaction.  
						end if;
			end case;
		end if;
	end process;

end behavior;