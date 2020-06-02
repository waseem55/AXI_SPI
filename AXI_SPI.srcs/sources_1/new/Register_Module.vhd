library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Register_Module is
    generic(
        C_BASEADDR : std_logic_vector(31 downto 0) := X"00000000";
        C_NUM_TRANSFER_BITS : integer := 8);
    
    port(
        i_CLK       : in std_logic;
        i_RESETN    : in std_logic;
        i_WREQUEST  : in std_logic;
        i_RREQUEST  : in std_logic;
        
        ------------- SPISR internal bits ----------------
        i_RX_EMPTY          : in std_logic;
        i_RX_FULL           : in std_logic;
        i_TX_EMPTY          : in std_logic;
        i_TX_FULL           : in std_logic;
        i_MODF              : in std_logic;
        i_Slave_Mode_Select : in std_logic;
        
        ------------------- To FIFOs ---------------------
        i_RX_FIFO           : in std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
        o_RPULSE            : out std_logic;
        o_TX_FIFO           : out std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
        o_WPULSE            : out std_logic;
        
        i_WSTB              : in std_logic_vector(3 downto 0);
        i_ADDR              : in std_logic_vector(31 downto 0);
        i_DATA              : in std_logic_vector(31 downto 0);
        o_DATA              : out std_logic_vector(31 downto 0)
        
        );
    
    constant SRR_ADR : unsigned(7 downto 0) := x"40";
    constant SPICR_ADR : unsigned(7 downto 0) := x"60";
    constant SPISR_ADR : unsigned(7 downto 0) := x"64";
    constant SPIDTR_ADR : unsigned(7 downto 0) := x"68";
    constant SPIDRR_ADR : unsigned(7 downto 0) := x"6C";
    constant SPISSR_ADR : unsigned(7 downto 0) := x"70";
    constant TX_FIFO_OCY_ADR : unsigned(7 downto 0) := x"74";
    constant RX_FIFO_OCY_ADR : unsigned(7 downto 0) := x"78";
    constant DGIER_ADR : unsigned(7 downto 0) := x"1C";
    constant IPISR_ADR : unsigned(7 downto 0) := x"20";
    constant IPIER_ADR : unsigned(7 downto 0) := x"28";
    
end Register_Module;

architecture behavior of Register_Module is
    
    signal t_ADDR : unsigned(31 downto 0);
    
    signal SRR : std_logic_vector(31 downto 0);
    signal SPICR : std_logic_vector(31 downto 0);
    signal SPISR : std_logic_vector(31 downto 0);
    signal SPIDTR : std_logic_vector(31 downto 0);
    signal SPIDRR : std_logic_vector(31 downto 0);
    signal SPISSR : std_logic_vector(31 downto 0);
    signal TX_FIFO_OCY : std_logic_vector(31 downto 0);
    signal RX_FIFO_OCY : std_logic_vector(31 downto 0);
    signal DGIER : std_logic_vector(31 downto 0);
    signal IPISR : std_logic_vector(31 downto 0);
    signal IPIER : std_logic_vector(31 downto 0);

begin
    
    t_ADDR <= (unsigned(i_ADDR) - unsigned(C_BASEADDR));
    SPIDRR <= i_RX_FIFO;
    o_TX_FIFO <= SPIDTR;
    
    process(i_CLK, i_RESETN)
    begin
        if i_RESETN = '0' then
            SRR         <= (others => '0');
            SPICR       <= X"00000180";
            SPISR       <= X"00000025";
            SPIDTR      <= (others => '0');
            SPIDRR      <= (others => '0');
            SPISSR      <= (others => '1');
            TX_FIFO_OCY <= (others => '0');
            RX_FIFO_OCY <= (others => '0');
            DGIER       <= (others => '0');
            IPISR       <= (others => '0');
            IPIER       <= (others => '0');
            
            o_RPULSE <= '0';
            o_WPULSE <= '0';
        elsif rising_edge(i_CLK) then
        
            o_RPULSE <= '0';
            o_WPULSE <= '0';
            
            SPISR <= (0 => i_RX_EMPTY,
                          1 => i_RX_FULL,
                          2 => i_TX_EMPTy,
                          3 => i_TX_FULL,
                          4 => i_MODF,
                          5 => i_Slave_Mode_Select,
                          others => '0');
                          
--            TX_FIFO_OCY <= 
            
--            RX_FIFO_OCY <= 
            case t_ADDR(7 downto 0) is
            when SRR_ADR =>
                if i_WREQUEST = '1' then
                    if i_DATA = X"0000000A" then
                        SRR <= i_DATA;
                    end if;
                end if;
                
            when SPICR_ADR =>
                if i_WREQUEST = '1' then
                    SPICR <= i_DATA;
                end if;
                
            when SPISR_ADR =>
                if i_RREQUEST = '1' then
                    o_DATA <= SPISR;
                end if;
            
            when SPIDTR_ADR =>
                if i_WREQUEST = '1' then
                    if i_WSTB(0) = '1' then
                        SPIDTR(7 downto 0) <= i_DATA(7 downto 0);
                    end if;
                    if i_WSTB(1) = '1' then
                        SPIDTR(15 downto 8) <= i_DATA(15 downto 8);
                    end if;
                    if i_WSTB(2) = '1' then
                        SPIDTR(23 downto 16) <= i_DATA(23 downto 16);
                    end if;
                    if i_WSTB(3) = '1' then
                        SPIDTR(31 downto 24) <= i_DATA(31 downto 24);
                    end if;
                    o_WPULSE <= '1';
                end if;
                
            when SPIDRR_ADR =>
                if i_RREQUEST = '1' then
                    o_DATA <= SPIDRR;
                    o_RPULSE <= '1';
                end if;
                
            when SPISSR_ADR =>
                if i_WREQUEST = '1' then
                    SPISSR <= i_DATA;
                elsif i_RREQUEST = '1' then
                    o_DATA <= SPISSR;
                end if;
                
            when TX_FIFO_OCY_ADR =>
                
            
            when RX_FIFO_OCY_ADR =>
            
            when DGIER_ADR =>
            
            when IPISR_ADR =>
            
            when IPIER_ADR =>
            
            end case;
        end if;
    end process;
end behavior;            














