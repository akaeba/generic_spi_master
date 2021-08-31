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
-- @file:           generic_spi_master_HC594_HC165_tb.vhd
-- @date:           2021-01-27
--
-- @see:            https://github.com/akaeba/generic_spi_master
-- @brief:          SPI master w/ HC594 and HC165 SFR register
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
entity generic_spi_master_HC594_HC165_tb is
generic (
            DO_ALL_TEST : boolean := false  --! switch for enabling all tests
        );
end entity generic_spi_master_HC594_HC165_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of generic_spi_master_HC594_HC165_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant SPI_MODE       : integer range 0 to 3  := 2;
        constant NUM_CS         : integer               := 1;
        constant DW_SFR         : integer               := 8;
        constant CLK_HZ         : positive              := 50_000_000;
        constant SCK_HZ         : positive              := 25_000_000;
        constant RST_ACTIVE     : bit                   := '0';
        constant MISO_SYNC_STG  : natural               := 0;
        constant MISO_FILT_STG  : natural               := 0;
        -- Clock
        constant tclk   : time  := 1 sec / CLK_HZ;  --! period of source clock
        constant tskew  : time  := tclk / 50;       --! data skew
        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! Test1: Send/receive single bytes
        constant do_test_1  : boolean := false; --! Test1: Send/receive random bytes
    -----------------------------


    -----------------------------
    -- Signal
        -- DUT
        signal CLK      : std_logic;
        signal SCK      : std_logic;
        signal CSN      : std_logic_vector(NUM_CS-1 downto 0);
        signal MOSI     : std_logic;
        signal MISO     : std_logic;
        signal DI       : std_logic_vector(DW_SFR-1 downto 0);
        signal DO       : std_logic_vector(DW_SFR-1 downto 0);
        signal EN       : std_logic;
        signal BSY      : std_logic;
        signal DO_WR    : std_logic_vector(NUM_CS-1 downto 0);
        signal DI_RD    : std_logic_vector(NUM_CS-1 downto 0);
        -- TB
        signal XRST     : std_logic;
        signal XSCK     : std_logic;
        signal XCSN     : std_logic;                    --! complementary low active chip-select (high-active)
        signal par_out  : std_logic_vector(7 downto 0); --! parallel SFR out (HC594)
        signal par_in   : std_logic_vector(7 downto 0); --! parallel SFR in (HC165)
        signal CLKENA   : std_logic := '1';             --! clock gating
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.generic_spi_master
        generic map (
                        SPI_MODE        => SPI_MODE,        --! SPI transfer Mode
                        NUM_CS          => NUM_CS,          --! Number of Channels (chip-selects)
                        DW_SFR          => DW_SFR,          --! data width shift register
                        CLK_HZ          => CLK_HZ,          --! clock frequency
                        SCK_HZ          => SCK_HZ,          --! Shift clock rate; minimal frequency - can be higher due numeric rounding effects
                        RST_ACTIVE      => RST_ACTIVE,      --! Reset active level
                        MISO_SYNC_STG   => MISO_SYNC_STG,   --! number of MISO sync stages, 0: not implemented
                        MISO_FILT_STG   => MISO_FILT_STG    --! number of bit length for hysteresis, 0: not implemented
                    )
        port map    (
                        RST   => XRST,  --! asynchronous reset
                        CLK   => CLK,   --! clock, rising edge
                        CSN   => CSN,   --! chip select
                        SCK   => SCK,   --! Shift forward clock
                        MOSI  => MOSI,  --! serial data out;    master-out / slave-in
                        MISO  => MISO,  --! serial data in;     master-in  / slave-out
                        DI    => DI,    --! Parallel data-in, transmitted via MOSI
                        DO    => DO,    --! Parallel data-out, received via MISO
                        EN    => EN,    --! if in idle master starts receive and transmission
                        BSY   => BSY,   --! transmission is active
                        DO_WR => DO_WR, --! DO segment contents new data
                        DI_RD => DI_RD  --! DI segment transfered into MOSI shift forward register
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- Shift regs
    ----------------------------------------------
        -- 8-bit shift register with output register
        i_HC594 : entity work.HC594
            port map    (
                            SHCP => XSCK,   --! shift register clock input (rising-edge)
                            STCP => CSN(0), --! storage register clock input (rising-edge)
                            SHRN => XRST,   --! shift register reset (low-active)
                            STRN => XRST,   --! storage register reset (low-active)
                            DS   => MOSI,   --! serial data input
                            Q7S  => open,   --! serial data output
                            Q    => par_out --! Parallel data output
                        );
            -- help
            XSCK <= not SCK;    --! latches on first edge

        -- 8-Bit Parallel-Load Shift Registers
        i_HC165 : entity work.HC165
            port map    (
                            SH_XLD  => XCSN,        --! Shift or Load input, When High Data, shifted. When Low data is loaded from parallel inputs
                            CLK     => SCK,         --! Clock input
                            CLK_INH => CSN(0),      --! Clock Inhibit, when High No change in output
                            SER     => '0',         --! Serial Input
                            QH      => MISO,        --! Serial Output
                            XQH     => open,        --! Complementary Serial Output
                            A       => par_in(0),   --! Parallel Input
                            B       => par_in(1),   --! Parallel Input
                            C       => par_in(2),   --! Parallel Input
                            D       => par_in(3),   --! Parallel Input
                            E       => par_in(4),   --! Parallel Input
                            F       => par_in(5),   --! Parallel Input
                            G       => par_in(6),   --! Parallel Input
                            H       => par_in(7)    --! Parallel Input
                        );
            -- help
            XCSN <= not CSN(0);
    ----------------------------------------------


    ----------------------------------------------
    -- Performs tests
    p_stimuli_process : process
        -- tb help variables
            variable good           : boolean := true;
        -- variables for random number generator
            variable seed1, seed2   : positive;
            variable rand           : real;
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            XRST    <= '0';
            EN      <= '0';
            par_in  <= (others => '0');
            DI      <= (others => '0');
            wait for 5*tclk;
            wait until rising_edge(CLK); wait for tskew;
            XRST    <=  '1';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Send/receive single byte
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Send/receive single byte";
            wait until rising_edge(CLK); wait for tskew;
            EN      <= '1';
            DI      <= x"55";
            par_in  <= x"AA";
            wait until rising_edge(CLK); wait for tskew;
            EN      <= '0';
            -- wait for transmission
            while ( '1' = BSY ) loop
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            wait until rising_edge(CLK); wait for tskew;    --! propagation delay of SFR
            -- compare MOSI
            assert ( DI = par_out ) report "  MOSI expected 0x55" severity warning;
            if not ( DI = par_out ) then good := false; end if;
            -- compare MISO
            assert ( DO = par_in ) report "  MISO expected 0xAA" severity warning;
            if not ( DO = par_in ) then good := false; end if;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Test1: Send/receive random bytes
        -------------------------
        if ( DO_ALL_TEST or do_test_1 ) then
            Report "Test1: Send/receive random bytes";
            wait until rising_edge(CLK); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            -- performs multi word send
            for i in 0 to loop_iter-1 loop
                -- test data
                UNIFORM(seed1, seed2, rand);    --! random number
                DI      <= std_logic_vector(to_unsigned(integer(round(rand*(2.0**DI'length-1.0))), DI'length));
                UNIFORM(seed1, seed2, rand);    --! random number
                par_in  <= std_logic_vector(to_unsigned(integer(round(rand*(2.0**par_in'length-1.0))), par_in'length));
                EN      <=  '1';
                wait until rising_edge(CLK); wait for tskew;
                EN      <=  '0';
                -- wait for transmission
                while ( '1' = BSY ) loop
                    wait until rising_edge(CLK); wait for tskew;
                end loop;
                wait until rising_edge(CLK); wait for tskew;    --! propagation delay of SFR
                -- compare MOSI
                assert ( DI = par_out ) report "  MOSI failed" severity warning;
                if not ( DI = par_out ) then good := false; end if;
                -- compare MISO
                assert ( DO = par_in ) report "  MISO failed" severity warning;
                if not ( DO = par_in ) then good := false; end if;
            end loop;
            wait for 10*tclk;
        end if;
        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     --! sim finished
            if (good) then
                Report "Test SUCCESSFUL";
            else
                Report "Test FAILED" severity failure;
            end if;
            wait until falling_edge(CLK); wait for tskew;
            CLKENA <= '0';          --! allows GHDL to stop sim
            wait;                   --! stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------


    ----------------------------------------------
    -- clock
    p_clk : process
        variable v_clk : std_logic := '0';
    begin
        while ( '1' = CLKENA ) loop
            CLK     <= v_clk;
            v_clk   := not v_clk;
            wait for tclk/2;
        end loop;
        wait;
    end process p_clk;
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
