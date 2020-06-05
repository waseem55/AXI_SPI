library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIFO is
generic( depth : integer range 4 to 32 := 16;
		 width : integer range 8 to 32 := 8);
port( wdata : in std_logic_vector(width - 1 downto 0);
      w_enable, r_enable, reset : in std_logic;
      clk : in std_logic;
      rdata : out std_logic_vector(width - 1 downto 0);
      full_flag, empty_flag : out std_logic;
	  occupancy_flag: std_logic_vector(3 downto 0);
	  half_full_flag: out std_logic);
	  
end FIFO;

architecture behavior of FIFO is
type FIFO_array is array (0 to depth - 1) of std_logic_vector(width - 1 downto 0);
signal fifo : FIFO_array;
signal wpointer, rpointer : integer range 0 to (depth-1);
signal r_round, w_round, fflag_temp, eflag_temp : std_logic;
signal integer_occupancy_flag: integer;

begin
 
Read_Write:
process(clk, reset)
begin
    if reset = '1' then
        fifo <= (others => (others => '0'));
        r_round <= '0';
        w_round <= '0';
        wpointer <= 0;
        rpointer <= 0;
        rdata <= (others => '0');
		half_full_flag<='0';
		occupancy_flag<='0';
		integer_occupancy_flag<=0;
    else
        if rising_edge(clk) then
            if w_enable = '1' and fflag_temp /= '1' then
                fifo(wpointer) <= wdata;
                if wpointer = depth-1 then
                    wpointer <= 0;
                    w_round <= not w_round;
                else
                    wpointer <= wpointer + 1;
                end if;
            end if;
            if r_enable = '1' and eflag_temp /= '1' then
                rdata <= fifo(rpointer);
                if rpointer = depth-1 then
                    rpointer <= 0;
                    r_round <= not r_round;
                else
                    rpointer <= rpointer + 1;
                end if;
            end if;
       
		--add occupancy_flag logic here 
			if w_round /= r_round then 
				if fflag_temp = '0' then 
					if w_enable = '1' and r_enable = '1' then 
						integer_occupancy_flag<=((wpointer+1) + (depth-1-rpointer)-1);
					elsif w_enable = '1' and r_enable = '0' then 
						integer_occupancy_flag<=((wpointer+1) + (depth-1-rpointer));
					elsif w_enable = '0' and r_enable = '1' then 
						integer_occupancy_flag<=((wpointer+1) + (depth-1-rpointer)-2)
					elsif w_enable = '0' and r_enable = '0' then 
						integer_occupancy_flag<=((wpointer)+(depth-rpointer)-1);
					end if;
				elsif fflag_temp = '1' then 
					if w_enable = '1' and r_enable = '1' then 
						integer_occupancy_flag<=depth-2;
					elsif w_enable = '1' and r_enable = '0' then 
						integer_occupancy_flag<=depth-1;
					elsif w_enable = '0' and r_enable = '1' then 
						integer_occupancy_flag<=depth-2;
					elsif w_enable = '0' and r_enable = '0' then 
						integer_occupancy_flag<=depth - 1;--because must be one less than true value to be translated to binary format in the register
					end if;
				end if;
			elsif w_round = r_round then 
				if eflag_temp = '0' then 
					if w_enable = '1' and r_enable = '1' then 
						integer_occupancy_flag<=wpointer-rpointer-1;
					elsif w_enable = '1' and r_enable = '0' then 
						integer_occupancy_flag<=wpointer-rpointer;
					elsif w_enable = '0' and r_enable = '1' then 
						integer_occupancy_flag<=wpointer-rpointer-2;
					elsif w_enable = '0' and r_enable = '0' then 
						integer_occupancy_flag<=wpointer-rpointer-1;
					end if;
				elsif eflag_temp = '1' then 
					if w_enable = '1' and r_enable = '1' then 
						integer_occupancy_flag<=0;
					elsif w_enable = '1' and r_enable = '0' then 
						integer_occupancy_flag<=0;
					elsif w_enable = '0' and r_enable = '1' then 
						integer_occupancy_flag<=0;
					elsif w_enable = '0' and r_enable = '0' then 
						integer_occupancy_flag<=0;
					end if;
				end if;
			end if;
			
			
			
			if  integer_occupancy_flag = 4 and depth = 8 then 
				if r_enable = '1' and w_enable = '0' then
					half_full_flag<='1';
				else 
					half_full_flag<='0';
				end if;
			elsif integer_occupancy_flag = 8 and depth =16  then 
				if r_enable = '1' and w_enable = '0' then
					half_full_flag<='1';
				else 
					half_full_flag<='0';
				end if;
			elsif integer_occupancy_flag = 16 and depth =32 then 
				if r_enable = '1' and w_enable = '0' then
					half_full_flag<='1';
				else 
					half_full_flag<='0';
				end if;
			else 
				half_full_flag<='0';
			end if;
				
		end if;
    end if;
end process;

fflag_temp <= '1' when (wpointer = rpointer) and (w_round /= r_round)
              else '0';
eflag_temp <= '1' when (rpointer = wpointer) and (w_round = r_round)
              else '0';

full_flag <= fflag_temp;
empty_flag <= eflag_temp;
occupancy_flag<=std_logic_vector(to_unsigned(integer_occupancy_flag, occupancy_flag'length));
end behavior;