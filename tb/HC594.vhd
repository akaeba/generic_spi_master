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
-- @file:           HC594.vhd
-- @date:           2021-01-31
--
-- @brief:          8-bit shift register with output register
--
-- @see:            https://assets.nexperia.com/documents/data-sheet/74HC_HCT594.pdf
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Shift Register
entity HC594 is
port    (
            -- Clock/Reset
            SHCP    : in    std_logic;                      --! shift register clock input (rising-edge)
            STCP    : in    std_logic;                      --! storage register clock input (rising-edge)
            SHRN    : in    std_logic;                      --! shift register reset (low-active)
            STRN    : in    std_logic;                      --! storage register reset (low-active)
            -- Serial
            DS      : in    std_logic;                      --! serial data input
            Q7S     : out   std_logic;                      --! serial data output
            -- Parallel
            Q       : out   std_logic_vector(7 downto 0)    --! Parallel data output
        );
end entity HC594;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of HC594 is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------
        constant tDly : time := 1 ns;   --! regs propagation delay
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        signal sfr  : std_logic_vector(Q'range);    --! shift register
        signal reg  : std_logic_vector(Q'range);    --! parallel storage register
    ----------------------------------------------

begin

    ----------------------------------------------
    -- Shift register
    p_sfr : process( SHRN, SHCP )
    begin
        if ( SHRN = '0' ) then
            sfr <= (others => '0');
        elsif ( rising_edge(SHCP) ) then
            sfr <= sfr(sfr'left-1 downto sfr'right) & DS after tDly;
        end if;
    end process p_sfr;
        -- Misc
    Q7S <= sfr(sfr'left) after tDly;   --! serial output
    ----------------------------------------------

    ----------------------------------------------
    -- Storage register
    p_storage : process( STRN, STCP )
    begin
        if ( STRN = '0' ) then
            reg <= (others => '0');
        elsif ( rising_edge(STCP) ) then
            reg <= sfr after tDly;
        end if;
    end process p_storage;
        -- Misc
    Q <= reg after tDly;    --! parallel output
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
