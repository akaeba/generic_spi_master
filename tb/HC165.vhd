--************************************************************************
-- @author:         Andreas Kaeberlein
-- @copyright:      Copyright 2021
-- @credits:        AKAE
--
-- @license:        BSDv3
-- @maintainer:     Andreas Kaeberlein
-- @email:          andreas.kaeberlein@web.de
--
-- @note:           VHDL'93
-- @file:           HC165.vhd
-- @date:           2021-02-01
--
-- @brief:          8-Bit Parallel-Load Shift Registers
--
-- @see:            https://www.ti.com/lit/ds/symlink/sn74hc165.pdf
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Shift Register
entity HC165 is
port    (
            -- Clock/Reset
            SH_XLD  : in    std_logic;  --! Shift or Load input, When High Data, shifted. When Low data is loaded from parallel inputs
            CLK     : in    std_logic;  --! Clock input
            CLK_INH : in    std_logic;  --! Clock Inhibit, when High No change in output
            -- Serial
            SER     : in    std_logic;  --! Serial Input
            QH      : out   std_logic;  --! Serial Output
            XQH     : out   std_logic;  --! Complementary Serial Output
            -- Parallel
            A       : in    std_logic;  --! Parallel Input
            B       : in    std_logic;  --! Parallel Input
            C       : in    std_logic;  --! Parallel Input
            D       : in    std_logic;  --! Parallel Input
            E       : in    std_logic;  --! Parallel Input
            F       : in    std_logic;  --! Parallel Input
            G       : in    std_logic;  --! Parallel Input
            H       : in    std_logic   --! Parallel Input
        );
end entity HC165;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of HC165 is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------
        constant tDly : time := 1 ns;   --! regs propagation delay
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        signal sfr_in   : std_logic_vector(7 downto 0);     --! combined inputs
        signal sfr      : std_logic_vector(sfr_in'range);   --! shift register
        signal sck      : std_logic;                        --! shift clock
    ----------------------------------------------

begin

    ----------------------------------------------
    -- Shift register
    p_sfr : process( SH_XLD, sck, sfr_in )  --! inputs are enabled by a low level at the shift/load (SH/LD) input
    begin
        if ( '0' = SH_XLD ) then
            sfr <= sfr_in;
        elsif ( rising_edge(sck) ) then
            sfr <= sfr(sfr'left-1 downto sfr'right) & SER after tDly;
        end if;
    end process p_sfr;
        -- Output
    QH  <= sfr(sfr'left) after tDly;        --! SFR Output
    XQH <= not sfr(sfr'left) after tDly;    --! complementary SFR output
    ----------------------------------------------


    ----------------------------------------------
    -- Misc
    sck     <= CLK or CLK_INH;                              --! shift clock
    sfr_in  <= H & G & F & E & D & C & B & A after tDly;    --! assign to SFR input
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
