library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Register_Module is
    generic(
        C_BASEADDR : std_logic_vector(31 downto 0) := X"00000000";
        C_NUM_TRANSFER_BITS : integer := 8);
    
    port(
        i_CLK               : in std_logic;
        i_RESETN            : in std_logic;
        
        ------------- SPISR internal bits ----------------
        -- SPISR signals are levels coming from the top entity
        i_RX_EMPTY          : in std_logic;
        i_RX_FULL           : in std_logic;
        i_TX_EMPTY          : in std_logic;
        i_TX_FULL           : in std_logic;
        i_MODF              : in std_logic;
        i_Slave_Mode_Select : in std_logic;
        
        o_REG_ACk           : out std_logic;        -- To SPI to latch SPICR data
        ------------------- To/From FIFOs ---------------------
        i_TX_FIFO_OCY       : in std_logic_vector(3 downto 0);
        i_RX_FIFO_OCY       : in std_logic_vector(3 downto 0);
        i_RX_FIFO           : in std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
        o_RPULSE            : out std_logic;
        o_WPULSE            : out std_logic;
        o_TX_FIFO           : out std_logic_vector(C_NUM_TRANSFER_BITS-1 downto 0);
        
        ---------------- IPISR toggling strobes ------------------
        -- IPISR signals are pulses coming from the top entity
        i_MODF_INTERRUPT    : in std_logic;
        i_Slave_MODF        : in std_logic;
        i_DTR_EMPTY         : in std_logic;
        i_DTR_UNDERRUN      : in std_logic;
        i_DRR_FULL          : in std_logic;
        i_DRR_OVERRUN       : in std_logic;
        i_TX_FIFO_HALFEMPTY : in std_logic;
        i_SLAVE_MODE_SELECT_INTERRUPT : in std_logic;
        i_DRR_NOT_EMPTY     : in std_logic;
        
        -------------------- Registers -------------------------
        o_SRR               : out std_logic_vector(31 downto 0);
        o_SPICR             : out std_logic_vector(31 downto 0);
        o_SPISR             : out std_logic_vector(31 downto 0);
        o_SPIDTR            : out std_logic_vector(31 downto 0);
        o_SPIDRR            : out std_logic_vector(31 downto 0);
        o_SPISSR            : out std_logic_vector(31 downto 0);
        o_TX_FIFO_OCY       : out std_logic_vector(31 downto 0);
        o_RX_FIFO_OCY       : out std_logic_vector(31 downto 0);
        o_DGIER             : out std_logic_vector(31 downto 0);
        o_IPISR             : out std_logic_vector(31 downto 0);
        o_IPIER             : out std_logic_vector(31 downto 0);
        
        -------------------- AXI Ports -------------------------
        i_WREQUEST          : in std_logic;
        i_RREQUEST          : in std_logic;
        o_AXI_READ_ACK       : out std_logic;            -- to AXI to latch read data
        o_WRITE_ERROR       : out std_logic_vector(1 downto 0);
        o_READ_ERROR        : out std_logic_vector(1 downto 0);
        i_WSTB              : in std_logic_vector(3 downto 0);
        i_WADDR             : in std_logic_vector(31 downto 0);
        i_RADDR             : in std_logic_vector(31 downto 0);
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
    
    signal t_RADDR : unsigned(31 downto 0);
    signal t_WADDR : unsigned(31 downto 0);
    signal clear_SPISR4 : std_logic;
    signal toggle_IPISR : std_logic;
    
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
    
    o_SRR                 <= SRR;
    o_SPICR               <= SPICR;
    o_SPISR               <= SPISR;
    o_SPIDTR              <= SPIDTR;
    o_SPIDRR              <= SPIDRR;
    o_SPISSR              <= SPISSR;
    o_TX_FIFO_OCY         <= TX_FIFO_OCY;
    o_RX_FIFO_OCY         <= RX_FIFO_OCY;
    o_DGIER               <= DGIER;
    o_IPISR               <= IPISR;
    o_IPIER               <= IPIER;
    
    t_RADDR <= (unsigned(i_RADDR) - unsigned(C_BASEADDR));
    t_WADDR <= (unsigned(i_WADDR) - unsigned(C_BASEADDR));
    SPIDRR <= i_RX_FIFO;
    o_TX_FIFO <= SPIDTR;
    
    AXI_Read_Write: process(i_CLK, i_RESETN)
    begin
        if i_RESETN = '0' then
            SRR         <= (others => '0');
            SPICR       <= X"00000180";
            SPIDTR      <= (others => '0');
            SPISSR      <= (others => '1');
            DGIER       <= (others => '0');
            IPIER       <= (others => '0');
            
            o_AXI_READ_ACK <= '0';
            o_REG_ACk <= '0';
            toggle_IPISR <= '0';
            clear_SPISR4 <= '0';            -- purspose is to clear SPISR(4) bit when SPISR is read
            o_RPULSE <= '0';
            o_WPULSE <= '0';
        elsif rising_edge(i_CLK) then
            
            
            o_RPULSE <= '0';
            o_WPULSE <= '0';
            o_REG_ACk <= '0';
            o_AXI_READ_ACK <= '0';
            toggle_IPISR <= '0';
            if clear_SPISR4 = '1' then      -- purspose is to clear SPISR(4) bit when SPISR is read
                clear_SPISR4 <= i_MODF;
            end if;
            
            ------------ Write Request Handling ------------
            if i_WREQUEST = '1' then
                case t_WADDR(7 downto 0) is
                when SRR_ADR =>
                    if i_DATA = X"0000000A" then
                        SRR <= i_DATA;
                        o_WRITE_ERROR <= "00";
                    else 
                        o_WRITE_ERROR <= "10";
                    end if;
                    
                when SPICR_ADR =>
                    SPICR(9 downto 0) <= i_DATA(9 downto 0);
                    o_REG_ACk <= '1';
                    o_WRITE_ERROR <= "00";
                    
                when SPISR_ADR =>
                    o_WRITE_ERROR <= "00";
                
                when SPIDTR_ADR =>
                    if i_TX_FULL = '1' then
                        o_WRITE_ERROR <= "10";
                    else
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
                        o_WRITE_ERROR <= "00";
                        o_WPULSE <= '1';
                    end if;
                    
                when SPIDRR_ADR =>
                    o_WRITE_ERROR <= "00";
                    
                when SPISSR_ADR =>
                    SPISSR(C_NUM_TRANSFER_BITS-1 downto 0) <= i_DATA(C_NUM_TRANSFER_BITS-1 downto 0);
                    o_WRITE_ERROR <= "00";
                    
                when TX_FIFO_OCY_ADR =>
                    o_WRITE_ERROR <= "00";
                
                when RX_FIFO_OCY_ADR =>
                    o_WRITE_ERROR <= "00";
                    
                when DGIER_ADR =>
                    DGIER(31) <= i_DATA(31);
                    o_WRITE_ERROR <= "00";
                    
                when IPISR_ADR =>
                    toggle_IPISR <= '1';        -- Toggle on Write operation
                    o_WRITE_ERROR <= "00";
                        
                when IPIER_ADR =>
                    IPIER <= i_DATA;
                    o_WRITE_ERROR <= "00";
                    
                when others =>
                    o_WRITE_ERROR <= "10";
                end case;
            end if;
            
            ------------ Read Request Handling ------------
            if i_RREQUEST = '1' then
                o_AXI_READ_ACK <= '1';
                case t_RADDR(7 downto 0) is
                    
                when SPICR_ADR =>
                    o_DATA <= SPICR;
                    o_READ_ERROR <= "00";
                    
                when SPISR_ADR =>
                    o_DATA <= SPISR;
                    clear_SPISR4 <= '1';
                    o_READ_ERROR <= "00";
                    
                when SPIDRR_ADR =>
                    o_DATA <= SPIDRR;
                    o_RPULSE <= '1';
                    o_READ_ERROR <= "00";
                    
                when SPISSR_ADR =>
                    o_DATA <= SPISSR;
                    o_READ_ERROR <= "00";
                    
                when TX_FIFO_OCY_ADR =>
                    o_DATA <= TX_FIFO_OCY;
                    o_READ_ERROR <= "00";
                
                when RX_FIFO_OCY_ADR =>
                    o_DATA <= RX_FIFO_OCY;
                    o_READ_ERROR <= "00";
                    
                when DGIER_ADR =>
                    o_DATA <= DGIER;
                    o_READ_ERROR <= "00";
                    
                when IPISR_ADR =>
                    o_DATA <= IPISR;
                    o_READ_ERROR <= "00";
                    
                when IPIER_ADR =>
                    o_DATA <= IPIER;
                    o_READ_ERROR <= "00";
                
                when others =>
                    o_DATA <= (others => '0');
                    o_READ_ERROR <= "10";
                end case;
            end if;
        end if;
    end process;
    
    Setting_Readonly_registers:process(i_CLK, i_RESETN)
    begin
        if i_RESETN = '0' then
            IPISR <= (others => '0');
            SPISR <= X"00000025";
            TX_FIFO_OCY <= (others => '0');
            RX_FIFO_OCY <= (others => '0');
        elsif rising_edge(i_CLK) then
            TX_FIFO_OCY <= "0000000000000000000000000000" & i_TX_FIFO_OCY;
            RX_FIFO_OCY <= "0000000000000000000000000000" & i_RX_FIFO_OCY;
            if clear_SPISR4 = '1' then              -- purspose is to clear SPISR(4) bit when SPISR is read
                SPISR <= (0 => i_RX_EMPTY,
                          1 => i_RX_FULL,
                          2 => i_TX_EMPTy,
                          3 => i_TX_FULL,
                          4 => '0',
                          5 => i_Slave_Mode_Select,
                          others => '0');
            else
                SPISR <= (0 => i_RX_EMPTY,
                          1 => i_RX_FULL,
                          2 => i_TX_EMPTy,
                          3 => i_TX_FULL,
                          4 => i_MODF,
                          5 => i_Slave_Mode_Select,
                          others => '0');
            end if;
            
            if toggle_IPISR = '1' then
                IPISR(8 downto 0) <= IPISR(8 downto 0) xor i_DATA(8 downto 0);
            else
                IPISR(0) <= IPISR(0) or i_MODF_INTERRUPT;
                IPISR(1) <= IPISR(1) or i_Slave_MODF;
                IPISR(2) <= IPISR(2) or i_DTR_EMPTY;
                IPISR(3) <= IPISR(3) or i_DTR_UNDERRUN;
                IPISR(4) <= IPISR(4) or i_DRR_FULL;
                IPISR(5) <= IPISR(5) or i_DRR_OVERRUN;
                IPISR(6) <= IPISR(6) or i_TX_FIFO_HALFEMPTY;
                IPISR(7) <= IPISR(7) or i_SLAVE_MODE_SELECT_INTERRUPT;
                IPISR(8) <= IPISR(8) or i_DRR_NOT_EMPTY;
                IPISR(31 downto 9) <= (others => '0');
            end if;   
        end if;
    end process;
    
end behavior;            










