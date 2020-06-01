library ieee;
use ieee.std_logic_1164.all;

entity Master_Block is

	generic (C_NUM_TRANSFER_BITS: integer :=8; -- sets expected number of bits in a transfer and size of shift register
			C_NUM_SS_BITS: integer := 8); -- size of slave select output
	
	
	
	port (	
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
--			MOSI_T: inout std_logic;
			
			-- slave select line output 
			SS_O: out std_logic_vector(C_NUM_SS_BITS-1 downto 0);
			
			--SCK pulse output
			SCK_O: inout std_logic; 
			
			-- signals master is ready for SW to start a new transaction
			ready_for_transaction: inout std_logic;
			
			--read_enable for TX_FIFO
			read_enable: out std_logic;
			
			--write_enable for RX_FIFO
			write_enable: out std_logic;
			
			--data valid pulse from the Tx_FIFO
			TX_Valid: in std_logic
		
			
			);
	
end Master_Block;

architecture behavioral of Master_Block is
type state_type is (idle,begin_transaction,read_enable_recognize, read_data_from_line, initialize,transmit_receive, delay); --state machine
signal state : state_type;

signal TX_BUFFER: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal RX_BUFFER: std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
signal transaction_style: std_logic;
signal slave_select_style: std_logic;
signal t_count: integer;
signal r_count: integer;
signal count: integer;
signal rising: std_logic;
signal SPI_CLK_COUNT: integer;
signal SPI_CLK_EDGES: integer;

begin 

process(S_AXI_ACLK, RESETN) 
begin
if RESETN = '0' then 
t_count<=0;
r_count<=0;
SS_O<=(others=>'1');
MOSI_O<='0';
Data_Out_Parallel<=(others=>'0');
ready_for_transaction<='0';
SCK_O<='0';
RX_BUFFER<=(others=>'0');
TX_BUFFER<=(others=>'0');
count<=0;
transaction_style<='0';
slave_select_style<='1';
rising<='1';
SPI_CLK_EDGES<=0;
SPI_CLK_COUNT<=0;
read_enable<='0';
write_enable<='0';
elsif rising_edge(S_AXI_ACLK) then 
	case(state) is
		when idle => 
			if RESETN = '0' then 
				t_count<=0;
				r_count<=0;
				SS_O<=(others=>'1');
				MOSI_O<='0';
				Data_Out_Parallel<=(others=>'0');
				ready_for_transaction<='0';
				SCK_O<='0';
				RX_BUFFER<=(others=>'0');
				TX_BUFFER<=(others=>'0');
				count<=0;
				transaction_style<='0';
				slave_select_style<='1';
				SPI_CLK_EDGES<=0;
                SPI_CLK_COUNT<=0;
				read_enable<='0';
			elsif RESETN ='1' then 
				ready_for_transaction <='1';
				state<=begin_transaction;
			end if;
			
		when begin_transaction => 
			if (ready_for_transaction = '1' and Master_Inhibit = '0') and Master_or_Slave = '1' and (SPE = '1' and TX_Valid ='1') then 
				--TX_BUFFER<=Data_In_Parallel;
				read_enable<='1';
				state<=read_enable_recognize;
				ready_for_transaction<='0';
				
				if LSB_or_MSB = '1' then -- lSB first 
					transaction_style<=LSB_or_MSB;
					t_count<=0;
					r_count<=(C_NUM_TRANSFER_BITS-1);
					
				elsif LSB_or_MSB = '0' then -- MSB first
					transaction_style<=LSB_or_MSB;
					t_count<=(C_NUM_TRANSFER_BITS-1);
					r_count<=0;
					
				end if;
				
				slave_select_style<=Manual_Slave_Select;
				SS_O<=SSR(C_NUM_SS_BITS-1 downto 0);
			end if;
		
	    when read_enable_recognize =>
	        state<=read_data_from_line;
	        read_enable<='0';
	    when read_data_from_line =>
	        TX_BUFFER<=Data_In_Parallel;
			state<=initialize;
		when initialize =>
			if transaction_style = '1' and Master_Inhibit = '0' then 
				MOSI_O<=TX_BUFFER(t_count);
				t_count<=t_count+1;
				SCK_O<='0';
				rising<='1';
				SPI_CLK_COUNT<=0;
				SPI_CLK_EDGES <= (2 * C_NUM_TRANSFER_BITS) -1;
				state<=transmit_receive;
			elsif transaction_style = '0'  and Master_Inhibit = '0'  then 
				SCK_O<='0';
				rising<='1';
				SPI_CLK_COUNT<=0;
				SPI_CLK_EDGES <= (2 * C_NUM_TRANSFER_BITS) -1;
				MOSI_O<=TX_BUFFER(t_count);
				t_count<=t_count-1;
				state<=transmit_receive;
			elsif Master_Inhibit = '1' then 
				state<=delay;
				count<=0;
			end if;
		
		when transmit_receive =>
			if Master_Inhibit = '0' then 
				if SPI_CLK_EDGES>0 then 
					if SPI_CLK_COUNT = 3 then 
						SCK_O <= not SCK_O;
						SPI_CLK_EDGES<=SPI_CLK_EDGES-1;
						SPI_CLK_COUNT<=0;
						rising<=not rising;
						if rising = '1' then 
							if transaction_style = '1' then 
								RX_BUFFER(r_count)<=MISO_I;
								r_count<=r_count-1;
							elsif transaction_style = '0' then 
								RX_BUFFER(r_count)<=MISO_I;
								r_count<=r_count+1;
							end if;
						elsif rising ='0' then 
							if transaction_style = '1' then 
								MOSI_O<=TX_BUFFER(t_count);
								t_count<=t_count+1;
							elsif transaction_style = '0' then 
								MOSI_O<=TX_BUFFER(t_count);
								t_count<=t_count-1;
							end if;
						end if;
						
					elsif SPI_CLK_COUNT = 1 then 
						SCK_O<= not SCK_O; 
						SPI_CLK_EDGES<=SPI_CLK_EDGES-1;
						rising<=not rising;
						if rising = '1' then 
							if transaction_style = '1' then 
								RX_BUFFER(r_count)<=MISO_I;
								r_count<=r_count-1;
							elsif transaction_style = '0' then 
								RX_BUFFER(r_count)<=MISO_I;
								r_count<=r_count+1;
							end if;
						elsif rising ='0' then 
							if transaction_style = '1' then 
								MOSI_O<=TX_BUFFER(t_count);
								t_count<=t_count+1;
							elsif transaction_style = '0' then 
								MOSI_O<=TX_BUFFER(t_count);
								t_count<=t_count-1;
							end if;
						end if;
						
					else 
						SPI_CLK_COUNT<=SPI_CLK_COUNT+1;
						
					end if;
				elsif SPI_CLK_EDGES = 0 and slave_select_style = '0' then 
					rising<=not rising;
					SCK_O<= not SCK_O;
					SS_O<=(others=>'1');
					Data_Out_Parallel<=RX_Buffer;
					write_enable<='1';
					state<=delay;
					count<=0;
				elsif SPI_CLK_EDGES = 0 and slave_select_style = '1' then 
					rising <=not rising; 
					SCK_O <= not SCK_O;	
					Data_Out_Parallel<=RX_Buffer;
					write_enable<='1';
					state<=delay;
					count<=0;
				end if;
				
			elsif Master_Inhibit = '1' then 
				state<=delay;
				count<=0;
				
			end if;
			
		when delay => 
			if count<6 then
				count<=count+1;
				write_enable<='0';
			elsif count =6 then 
				count<=0;
				state<=idle;
			end if;

	end case;
end if;
end process;
end behavioral;