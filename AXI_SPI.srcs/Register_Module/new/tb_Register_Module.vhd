library ieee;
use ieee.std_logic_1164.all;

entity tb_Register_Module is
end tb_Register_Module;

architecture test of tb_Register_Module is

component Register_Module
generic(
        C_BASEADDR : std_logic_vector(31 downto 0) := X"00000000");
port(
    i_CLK       : in std_logic;
    i_RESETN    : in std_logic;
    i_WREQUEST  : in std_logic;
    i_RREQUEST  : in std_logic;
    
    i_WSTB      : in std_logic_vector(3 downto 0);
    i_ADDR      : in std_logic_vector(31 downto 0);
    i_DATA      : in std_logic_vector(31 downto 0);
    o_DATA      : out std_logic_vector(31 downto 0)
    );
end component;

signal i_CLK        : std_logic := '0';
signal i_RESETN     : std_logic := '0';
signal i_WREQUEST   : std_logic := '0';
signal i_RREQUEST   : std_logic := '0';

signal i_WSTB       : std_logic_vector(3 downto 0);
signal i_ADDR       : std_logic_vector(31 downto 0);
signal i_DATA       : std_logic_vector(31 downto 0);
signal o_DATA       : std_logic_vector(31 downto 0);


begin

    DUT: Register_Module generic map((others => '0'))
    port map(
    i_CLK        => i_CLK,
    i_RESETN     => i_RESETN,
    i_WREQUEST   => i_WREQUEST,
    i_RREQUEST   => i_RREQUEST,

    i_WSTB       => i_WSTB,
    i_ADDR       => i_ADDR,
    i_DATA       => i_DATA,
    o_DATA       => o_DATA
    );
    
    i_CLK <= not i_CLK after 5 ns;
    i_RESETN <= '0', '1' after 10 ns;
    
    process
    begin
    
    wait until i_RESETN = '1';
    wait until i_CLK = '0';
    wait;
    end process;
end test;