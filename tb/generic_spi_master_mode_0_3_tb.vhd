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
-- @file:           generic_spi_master_mode_0_3_tb.vhd
-- @date:           2021-01-27
--
-- @see:            https://github.com/akaeba/generic_spi_master
-- @brief:          tests in SPI mode 0 to 3, NUMCS=2, CLK_HZ/SCK_HZ=5
--
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use ieee.std_logic_misc.and_reduce;
    use ieee.math_real.all;
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity generic_spi_master_mode_0_3_tb is
generic (
            DO_ALL_TEST : boolean               := false;   --! switch for enabling all tests
            TCLK_NS     : integer               := 20;      --! basic clock period in NS
            CLK_DIV2    : integer               := 1;       --! 1: sck runs with half clock
            SPI_MODE    : integer range 0 to 3  := 0        --! used SPI transfer mode

        );
end entity generic_spi_master_mode_0_3_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of generic_spi_master_mode_0_3_tb is

    -----------------------------
    -- Constant
        -- DUT
        constant NUM_CS         : integer   := 2;
        constant DW_SFR         : integer   := 8;
        constant CLK_HZ         : positive  := integer(round(1.0/(real(TCLK_NS)*10.0**(-9.0))));
        constant SCK_HZ         : positive  := CLK_HZ / (2*CLK_DIV2);
        constant RST_ACTIVE     : bit       := '1';
        constant MISO_SYNC_STG  : natural   := 0;
        constant MISO_FILT_STG  : natural   := 0;
        -- Clock
        constant tclk   : time  := 1 sec / CLK_HZ;  --! 1MHz clock
        constant tskew  : time  := tclk / 50;       --! data skew
        -- Test
        constant loop_iter  : integer := 20;    --! number of test loop iteration
        constant do_test_0  : boolean := true;  --! test0: Send/Receive random data bytes
    -----------------------------


    -----------------------------
    -- Signal
        -- DUT
        signal RST      : std_logic;
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
        signal DI_CS0   : std_logic_vector(DI'range);
        signal DI_CS1   : std_logic_vector(DI'range);
        signal DO_CS0   : std_logic_vector(DI'range);
        signal DO_CS1   : std_logic_vector(DI'range);
        signal miso_reg : std_logic_vector(DI'range);
        signal mosi_reg : std_logic_vector(DI'range);
        signal CLKENA   : std_logic := '1';             --! clock gating
    -----------------------------

begin

    ----------------------------------------------
    -- DUT
    DUT : entity work.generic_spi_master
        generic map (
                        SPI_MODE        => SPI_MODE,
                        NUM_CS          => NUM_CS,
                        DW_SFR          => DW_SFR,
                        CLK_HZ          => CLK_HZ,
                        SCK_HZ          => SCK_HZ,
                        RST_ACTIVE      => RST_ACTIVE,
                        MISO_SYNC_STG   => MISO_SYNC_STG,
                        MISO_FILT_STG   => MISO_FILT_STG
                    )
        port map    (
                        RST   => RST,
                        CLK   => CLK,
                        CSN   => CSN,
                        SCK   => SCK,
                        MOSI  => MOSI,
                        MISO  => MISO,
                        DI    => DI,
                        DO    => DO,
                        EN    => EN,
                        BSY   => BSY,
                        DO_WR => DO_WR,
                        DI_RD => DI_RD
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- Performs tests
    p_stimuli_process : process
        -- tb help variables
            variable good           : boolean := true;
            variable csnCheck       : std_logic_vector(NUM_CS-1 downto 0);
        -- variables for random number generator
            variable seed1, seed2   : positive;
            variable rand           : real;
    begin

        -------------------------
        -- TB Entry Message
        -------------------------
            Report                                                character(LF) &
                    "Generic SPI Master Testbench:"             & character(LF) &
                    "  SPI MODE : " & integer'image(SPI_MODE)   & character(LF) &
                    "  CLK [HZ] : " & integer'image(CLK_HZ)     & character(LF) &
                    "  SCK [HZ] : " & integer'image(SCK_HZ)     & character(LF) &
                    "  CSN      : " & integer'image(NUM_CS)     & character(LF) &
                    "  BIT      : " & integer'image(DW_SFR);
        -------------------------


        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            RST     <=  '1';
            EN      <=  '0';
            DI_CS0  <= (others => '0');     --! send via spi master
            DI_CS1  <= (others => '0');     --! send via spi master
            DO_CS0  <= (others => '0');     --! receive via spi master
            DO_CS1  <= (others => '0');     --! receive via spi master
            wait for 5*tclk;
            wait until rising_edge(CLK); wait for tskew;
            RST     <=  '0';
            wait until rising_edge(CLK); wait for tskew;
            wait until rising_edge(CLK); wait for tskew;
        -------------------------


        -------------------------
        -- Test0: Send/Receive random data bytes
        -------------------------
        if ( DO_ALL_TEST or do_test_0 ) then
            Report "Test0: Send/Receive random data bytes";
            wait until rising_edge(CLK); wait for tskew;
            UNIFORM(seed1, seed2, rand);    --! dummy read, otherwise first rand is zero
            EN  <=  '1'; --! enable core
            -- performs multi data send/receive
            for i in 0 to loop_iter-1 loop
                -- SPI TX, XCS[0]
                UNIFORM(seed1, seed2, rand);
                DI_CS0  <= std_logic_vector(to_unsigned(integer(round(rand*(2.0**DI_CS0'length-1.0))), DI_CS0'length));
                -- SPI TX, XCS[1]
                UNIFORM(seed1, seed2, rand);
                DI_CS1  <= std_logic_vector(to_unsigned(integer(round(rand*(2.0**DI_CS1'length-1.0))), DI_CS1'length));
                -- SPI RX, XCS[0]
                UNIFORM(seed1, seed2, rand);
                DO_CS0  <= std_logic_vector(to_unsigned(integer(round(rand*(2.0**DO_CS0'length-1.0))), DO_CS0'length));
                -- SPI RX, XCS[1]
                UNIFORM(seed1, seed2, rand);
                DO_CS1  <= std_logic_vector(to_unsigned(integer(round(rand*(2.0**DO_CS1'length-1.0))), DO_CS1'length));
                -- all Channels updated -> needed to check
                csnCheck := (others => '0');
                wait until rising_edge(CLK); wait for tskew;
                -- wait for transmission
                while ( '0' = and_reduce(csnCheck) ) loop
                    wait until rising_edge(CLK); wait for tskew;
                    -- check Channel 0
                    if ( '1' = DO_WR(0) ) then
                        -- MOSI
                        assert ( DI_CS0 = mosi_reg ) report "  MOSI Byte CSN0 failed" severity warning;
                        if not ( DI_CS0 = mosi_reg ) then good := false; end if;
                        -- MISO
                        assert ( DO_CS0 = DO ) report "  MISO Byte CSN0 failed" severity warning;
                        if not ( DO_CS0 = DO ) then good := false; end if;
                        -- mark as checked
                        csnCheck(0) := '1';
                    end if;
                    -- check Channel 1
                    if ( '1' = DO_WR(1) ) then
                        -- MOSI
                        assert ( DI_CS1 = mosi_reg ) report "  MOSI Byte CSN1 failed" severity warning;
                        if not ( DI_CS1 = mosi_reg ) then good := false; end if;
                        -- MISO
                        assert ( DO_CS1 = DO ) report "  MISO Byte CSN1 failed" severity warning;
                        if not ( DO_CS1 = DO ) then good := false; end if;
                        -- mark as checked
                        csnCheck(1) := '1';
                    end if;
                end loop;
                wait until rising_edge(CLK); wait for tskew;
            end loop;
            EN  <=  '0';
            wait until rising_edge(CLK); wait for tskew;
            while ( '1' = BSY ) loop
                wait until rising_edge(CLK); wait for tskew;
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
                Report "Test FAILED" severity error;
            end if;
            wait until falling_edge(CLK); wait for tskew;
            CLKENA <= '0';          --! allows GHDL to stop sim
            wait;                   --! stop process continuous run
        -------------------------

    end process p_stimuli_process;
    ----------------------------------------------


    ----------------------------------------------
    -- Selects DI
    DI  <=  DI_CS0              when ( "01" = DI_RD ) else
            DI_CS1              when ( "10" = DI_RD ) else
            (others => 'X');
    ----------------------------------------------


    ----------------------------------------------
    -- MISO SFR
    --  @see: https://de.wikipedia.org/wiki/Serial_Peripheral_Interface#/media/Datei:SPI_timing_diagram2.svg
    p_miso_sfr : process ( SCK, CSN )
        variable bit_cntr : integer range 0 to DW_SFR;
    begin
        if ( (0 = SPI_MODE) or (2 = SPI_MODE) ) then    --! spi mode 0/2
            if ( falling_edge(CSN(0)) ) then
                miso_reg <= DO_CS0;
            elsif( falling_edge(CSN(1)) ) then
                miso_reg <= DO_CS1;
            elsif ( (0 = SPI_MODE) and (falling_edge(SCK)) ) then
                miso_reg <= miso_reg(miso_reg'left-1 downto miso_reg'right) & '0';
            elsif ( (2 = SPI_MODE) and (rising_edge(SCK)) ) then
                miso_reg <= miso_reg(miso_reg'left-1 downto miso_reg'right) & '0';
            end if;
        elsif ( (1 = SPI_MODE) or (3 = SPI_MODE) ) then --! spi mode 1/3
            if ( '1' = CSN(0) and '1' = CSN(1) ) then
                bit_cntr := DW_SFR;
            else
                if ( (1 = SPI_MODE) and (rising_edge(SCK)) ) then
                    if ( DW_SFR = bit_cntr ) then   --! first edge, load
                        if ( '0' = CSN(0) and '1' = CSN(1) ) then       --! CSN0 selected
                            miso_reg <= DO_CS0;
                        elsif ( '1' = CSN(0) and '0' = CSN(1) ) then    --! CSN1 selected
                            miso_reg <= DO_CS1;
                        end if;
                        bit_cntr := bit_cntr - 1;
                    else                            --! following edges, shift
                        if ( '0' = CSN(0) and '1' = CSN(1) ) then       --! CSN0 selected
                            miso_reg <= miso_reg(miso_reg'left-1 downto miso_reg'right) & '0';
                        elsif ( '1' = CSN(0) and '0' = CSN(1) ) then    --! CSN1 selected
                            miso_reg <= miso_reg(miso_reg'left-1 downto miso_reg'right) & '0';
                        end if;
                        bit_cntr := bit_cntr - 1;
                    end if;
                elsif ( (3 = SPI_MODE) and (falling_edge(SCK)) ) then
                    if ( DW_SFR = bit_cntr ) then   --! first edge, load
                        if ( '0' = CSN(0) and '1' = CSN(1) ) then       --! CSN0 selected
                            miso_reg <= DO_CS0;
                        elsif ( '1' = CSN(0) and '0' = CSN(1) ) then    --! CSN1 selected
                            miso_reg <= DO_CS1;
                        end if;
                        bit_cntr := bit_cntr - 1;
                    else                            --! following edges, shift
                        if ( '0' = CSN(0) and '1' = CSN(1) ) then       --! CSN0 selected
                            miso_reg <= miso_reg(miso_reg'left-1 downto miso_reg'right) & '0';
                        elsif ( '1' = CSN(0) and '0' = CSN(1) ) then    --! CSN1 selected
                            miso_reg <= miso_reg(miso_reg'left-1 downto miso_reg'right) & '0';
                        end if;
                        bit_cntr := bit_cntr - 1;
                    end if;
                end if;
            end if;
        else
            Report "Unsupported SPI Mode: " & integer'image(SPI_MODE) severity failure;
        end if;
    end process p_miso_sfr;
    -- output
    MISO <= miso_reg(miso_reg'left) after tskew when ( '0' = CSN(0) or '0' = CSN(1) ) else 'Z'; --! gate output
    MISO <= 'L';                                                                    --! pull down
    ----------------------------------------------


    ----------------------------------------------
    -- MOSI SFR
    --  @see: https://de.wikipedia.org/wiki/Serial_Peripheral_Interface#/media/Datei:SPI_timing_diagram2.svg
    p_mosi_sfr : process ( SCK, CSN )
    begin
        if ( (0 = SPI_MODE) or (2 = SPI_MODE) ) then
            if ( '0' = CSN(0) or '0' = CSN(1) ) then
                if ( (0 = SPI_MODE) and (rising_edge(SCK)) ) then
                    mosi_reg <= mosi_reg(mosi_reg'left-1 downto mosi_reg'right) & MOSI after tskew;
                elsif ( (2 = SPI_MODE) and (falling_edge(SCK)) ) then
                    mosi_reg <= mosi_reg(mosi_reg'left-1 downto mosi_reg'right) & MOSI after tskew;
                end if;
            end if;
        elsif ( (1 = SPI_MODE) or (3 = SPI_MODE) ) then
            if ( '0' = CSN(0) or '0' = CSN(1) ) then
                if ( (1 = SPI_MODE) and (falling_edge(SCK)) ) then
                    mosi_reg <= mosi_reg(mosi_reg'left-1 downto mosi_reg'right) & MOSI after tskew;
                elsif ( (3 = SPI_MODE) and (rising_edge(SCK)) ) then
                    mosi_reg <= mosi_reg(mosi_reg'left-1 downto mosi_reg'right) & MOSI after tskew;
                end if;
            end if;
        else
            Report "Unsupported SPI Mode: " & integer'image(SPI_MODE) severity failure;
        end if;
    end process p_mosi_sfr;
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
