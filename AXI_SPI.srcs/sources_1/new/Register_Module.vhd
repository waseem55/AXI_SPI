library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Register_Module is
    generic(
        C_BASEADDR : std_logic_vector(31 downto 0) := X"00000000");
    
    port(
        i_CLK       : in std_logic;
        i_RESETN    : in std_logic;
        i_WREQUEST  : in std_logic;
        i_WSTB      : in std_logic_vector(3 downto 0);
        i_DATA      : in std_logic_vector(31 downto 0);
        o_DATA      : out std_logic_vector(31 downto 0);
        
        );
    
    constant SRR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"40");
    constant SPICR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"60");
    constant SPISR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"64");
    constant SPIDTR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"68");
    constant SPIDRR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"6C");
    constant SPISSR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"70");
    constant TXFIFO_OR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"74");
    constant RXFIFO_OR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"78");
    constant DGIER_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"1C");
    constant IPISR_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"20");
    constant IPIER_ADR : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(C_BASEADDR) + x"28");
    
    
    
    
end Register_Module;