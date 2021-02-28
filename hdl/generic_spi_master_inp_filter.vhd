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
-- @file:           generic_spi_master_inp_filter.vhd
-- @date:           2021-02-14
--
-- @see:            https://github.com/akaeba/generic_spi_master
-- @brief:          MOSI synchronization and hysteresis
--
--                  synchronizes MOSI data input and applies an hysteresis
--                  function to filter out false-latches caused by ESD
--                  events
--************************************************************************



--
-- Hints:
-- ======
--
--




--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_misc.and_reduce;
    use ieee.std_logic_misc.nor_reduce;
    use ieee.math_real.ceil;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Synchronizer and filter stage
entity generic_spi_master_inp_filter is
generic (
            SYNC_STAGES     : integer range 0 to 3  := 2;       --! synchronizer stages;                                                                        0: not implemented
            VOTER_STAGES    : natural range 0 to 11 := 3;       --! number of ff stages for voter; if all '1' out is '1', if all '0' out '0', otherwise hold;   0: not implemented
            RST_STRBO       : bit                   := '0';     --! STRBO output in reset
            RST_ACTIVE      : bit                   := '1'      --! Reset active level
        );
port    (
            -- Management
            RST     : in    std_logic;      --! asynchronous reset
            CLK     : in    std_logic;      --! clock, rising edge
            -- Data
            FILTI   : in    std_logic;      --! filter input
            FILTO   : out   std_logic;      --! filter output
            STRBI   : in    std_logic;      --! data strobe input
            STRBO   : out   std_logic       --! data strobe output, not filtered only delayed like filter delay, strobe is center aligned to filter chain
        );
end entity generic_spi_master_inp_filter;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of generic_spi_master_inp_filter is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------
        constant c_strobe_dly : integer := SYNC_STAGES + integer(ceil(real(VOTER_STAGES)-1.0)/2.0);
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        signal rsff_set     : std_logic;                                    --! sets RSFF
        signal rsff_reset   : std_logic;                                    --! reset RSFF
        signal sync_ffs     : std_logic_vector(SYNC_STAGES-1 downto 0);     --! synchronization flip flops
        signal synced       : std_logic;                                    --! synchronizer stage output
        signal voter_ffs    : std_logic_vector(VOTER_STAGES-1 downto 0);    --! SFR for voter input
        signal strobe_ffs   : std_logic_vector(c_strobe_dly-1 downto 0);    --! SFR for strobe
    ----------------------------------------------

begin

    ----------------------------------------------
    -- Sync stage
    ----------------------------------------------

        --***************************
        -- Implemented
        g_sync : if SYNC_STAGES > 0 generate
            -- flip flop
            p_sync_ff : process( RST, CLK )
            begin
                if ( RST = to_stdulogic(RST_ACTIVE) ) then
                    sync_ffs <= (others => to_stdulogic(RST_STRBO));
                elsif ( rising_edge(CLK) ) then
                    sync_ffs <= sync_ffs(sync_ffs'left-1 downto sync_ffs'right) & FILTI;
                end if;
            end process p_sync_ff;
            -- output
            synced <= sync_ffs(sync_ffs'left);
        end generate g_sync;
        --***************************

        --***************************
        -- Skipped
        g_skip_sync : if SYNC_STAGES = 0 generate
            synced <= FILTI;
        end generate g_skip_sync;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Voter stage
    ----------------------------------------------

        --***************************
        -- Implemented
        g_voter : if VOTER_STAGES > 1 generate
            -- filter flip flop
            p_voter_ff : process( RST, CLK )
            begin
                if ( RST = to_stdulogic(RST_ACTIVE) ) then
                    voter_ffs <= (others => to_stdulogic(RST_STRBO));
                elsif ( rising_edge(CLK) ) then
                    voter_ffs <= voter_ffs(voter_ffs'left-1 downto voter_ffs'right) & synced;
                end if;
            end process p_voter_ff;
            -- voter output
            rsff_set    <= and_reduce(voter_ffs);   --! no ringing on line
            rsff_reset  <= nor_reduce(voter_ffs);
            -- rs-ff
            p_rsff : process( RST, CLK )
            begin
                if ( RST = to_stdulogic(RST_ACTIVE) ) then
                    FILTO <= to_stdulogic(RST_STRBO);
                elsif ( rising_edge(CLK) ) then
                    if ( ('1' = rsff_set) and ('0' = rsff_reset) ) then
                        FILTO <= '1';
                    elsif ( ('0' = rsff_set) and ('1' = rsff_reset) ) then
                        FILTO <= '0';
                    end if;
                end if;
            end process p_rsff;
        end generate g_voter;
        --***************************

        --***************************
        -- Skipped
        g_skip_voter : if VOTER_STAGES <= 1 generate
            FILTO <= synced;
        end generate g_skip_voter;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Strobe signal delay
    ----------------------------------------------

        --***************************
        -- Implemented
        g_strobe : if c_strobe_dly > 0 generate
            -- SFR
            p_strobe_ff : process( RST, CLK )
            begin
                if ( RST = to_stdulogic(RST_ACTIVE) ) then
                    strobe_ffs <= (others => '0');
                elsif ( rising_edge(CLK) ) then
                    strobe_ffs <= strobe_ffs(strobe_ffs'left-1 downto strobe_ffs'right) & STRBI;
                end if;
            end process p_strobe_ff;
            -- output
            STRBO <= strobe_ffs(strobe_ffs'left);
        end generate g_strobe;
        --***************************

        --***************************
        -- Skipped
        g_skip_strobe : if c_strobe_dly <= 0 generate
            STRBO <= STRBI;
        end generate g_skip_strobe;
        --***************************

    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
