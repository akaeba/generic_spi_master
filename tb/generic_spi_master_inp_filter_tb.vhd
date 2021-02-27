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
-- @file:           generic_spi_master_inp_filter_tb.vhd
-- @date:           2021-02-26
--
-- @see:            https://github.com/akaeba/generic_spi_master
-- @brief:          testbench
--
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use ieee.math_real.all; --! for UNIFORM, TRUNC
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity generic_spi_master_inp_filter_tb is
generic (
            DO_ALL_TEST : boolean := false  --! switch for enabling all tests
        );
end entity generic_spi_master_inp_filter_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of generic_spi_master_inp_filter_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant SYNC_STAGES    : integer range 0 to 3      := 2;
        constant VOTER_STAGES   : natural range 0 to 11     := 5;
        constant RST_STRBO      : bit                       := '0';
        constant RST_ACTIVE     : bit                       := '1';
        -- Clock
        constant tclk   : time  := 20 ns;       --! 50MHz clock
        constant tskew  : time  := tclk / 50;   --! data skew
        -- Test
        constant loop_iter  : integer := 5;     --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0:
        constant do_test_1  : boolean := true;  --! test1:
        constant do_test_2  : boolean := true;  --! test2:
        constant do_test_3  : boolean := true;  --! test3:
    -----------------------------


    -----------------------------
    -- Signal
        -- DUT
        signal RST      : std_logic;
        signal CLK      : std_logic;
        signal FILTI    : std_logic;
        signal FILTO    : std_logic;
        signal STRBI    : std_logic;
        signal STRBO    : std_logic;
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
        DUT : entity work.generic_spi_master_inp_filter
            generic map (
                            SYNC_STAGES     => SYNC_STAGES,
                            VOTER_STAGES    => VOTER_STAGES,
                            RST_STRBO       => RST_STRBO,
                            RST_ACTIVE      => RST_ACTIVE
                        )
            port map    (
                            RST     => RST,
                            CLK     => CLK,
                            FILTI   => FILTI,
                            FILTO   => FILTO,
                            STRBI   => STRBI,
                            STRBO   => STRBO
                        );
    ----------------------------------------------


    ----------------------------------------------
    -- Performs tests
    p_stimuli_process : process
        -- tb help variables
            variable good : boolean := true;
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            RST     <= '1';
            FILTI   <= '0';
            STRBI   <= '0';
            wait for 5*tclk;
            wait until rising_edge(CLK); wait for tskew;
            RST     <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Switch to one/zero
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Switch to one/zero";
            wait until rising_edge(CLK); wait for tskew;
            FILTI   <= '1';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            FILTI   <= '0';
            wait until rising_edge(CLK); wait for tskew;    --! two stages sync chain
            wait until rising_edge(CLK); wait for tskew;    --!
            wait until rising_edge(CLK); wait for tskew;    --! RS-FF set delay
            assert ( '1' = FILTO ) report "  FILTO needs to be one" severity warning;
            if not ( '1' = FILTO  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = FILTO ) report "  FILTO needs to be one" severity warning;
            if not ( '1' = FILTO  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = FILTO ) report "  FILTO needs to be one" severity warning;
            if not ( '1' = FILTO  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = FILTO ) report "  FILTO needs to be one" severity warning;
            if not ( '1' = FILTO  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = FILTO ) report "  FILTO needs to be one" severity warning;
            if not ( '1' = FILTO  ) then good := false; end if;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test1: Switch to one and apply noisy signal
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: Switch to one and apply noisy signal";
            wait until rising_edge(CLK); wait for tskew;
            FILTI   <= '1';
            for i in 0 to 4 loop
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            FILTI   <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = FILTO ) report "  FILTO accidentally toggled" severity warning;
            if not ( '1' = FILTO  ) then good := false; end if;
            for i in 0 to loop_iter-1 loop
                FILTI   <= '1';
                assert ( '1' = FILTO ) report "  FILTO accidentally toggled" severity warning;
                if not ( '1' = FILTO  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
                FILTI   <= '0';
                assert ( '1' = FILTO ) report "  FILTO accidentally toggled" severity warning;
                if not ( '1' = FILTO  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test2: Switch to zero and apply noisy signal
        -------------------------
        if ( DO_ALL_TEST or do_test_2 ) then
            Report "Test2: Switch to zero and apply noisy signal";
            wait until rising_edge(CLK); wait for tskew;
            FILTI   <= '0';
            for i in 0 to 4 loop
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            FILTI   <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '0' = FILTO ) report "  FILTO accidentally toggled" severity warning;
            if not ( '0' = FILTO  ) then good := false; end if;
            for i in 0 to loop_iter-1 loop
                FILTI   <= '1';
                assert ( '0' = FILTO ) report "  FILTO accidentally toggled" severity warning;
                if not ( '0' = FILTO  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
                FILTI   <= '0';
                assert ( '0' = FILTO ) report "  FILTO accidentally toggled" severity warning;
                if not ( '0' = FILTO  ) then good := false; end if;
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test3: Switch to one and check sampling signal
        -------------------------
        if ( DO_ALL_TEST or do_test_3 ) then
            Report "Switch to one and check sampling signal";
            wait until rising_edge(CLK); wait for tskew;
            FILTI   <= '1';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            STRBI   <= '1';
            wait until rising_edge(CLK); wait for tskew;
            STRBI   <= '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '1' = STRBO ) report "  strobe failed" severity warning;
            if not ( '1' = STRBO  ) then good := false; end if;
            wait until rising_edge(CLK); wait for tskew;
            assert ( '0' = STRBO ) report "  strobe failed" severity warning;
            if not ( '0' = STRBO  ) then good := false; end if;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFULL";
            else
                Report "Test FAILED" severity error;
            end if;
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------


    ----------------------------------------------
    -- clock
    p_clk : process
        variable v_clk : std_logic := '0';
    begin
        while true loop
            CLK     <= v_clk;
            v_clk   := not v_clk;
            wait for tclk/2;
            end loop;
    end process p_clk;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
