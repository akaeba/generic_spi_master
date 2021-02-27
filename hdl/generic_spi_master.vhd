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
-- @file:           generic_spi_master.vhd
-- @date:           2021-01-23
--
-- @see:            https://github.com/akaeba/generic_spi_master
-- @brief:          SPI Master
--
--                  Generic SPI master with multiple chip select lines
--                  and a at compile time adjustable transfer rate.
--                  The chip select lines use a round robin arbitration
--                  starting with lowest CSN index.
--************************************************************************



--
-- Important Hints:
-- ================
--
--  Settings (adjustable at compile time)
--  -------------------------------------
--      SPI_MODE:       SPI transmission mode                                   values = 0,1,2,3
--      NUM_CS          number of ch
--      DW_SFR
--      CLK_HZ
--      SCK_HZ
--      RST_ACTIVE
--      DO_SFR_OUT:
--      MISO_SYNC_STG:  number of sync stages; synchronizes MISO data input;    values = 0,2,3
--      MISO_FILT
--
--  Miscellaneous
--  -------------
--      DI/DO:      bit-width of the SFR multiplied by the CS channel number
--                    * the lowest bit indices belonging to the lowest index in CSN
--                    * allows an generic data/channel width w/o defining data types
--                    * slicing into SFR width signals can done with "alias" statement
--
--  SPI Mode
--  --------
--    +----------+------+------+
--    | SPI Mode | CPOL | CPHA |
--    +----------+------+------+
--    | 0        |  0   |   0  |
--    | 1        |  0   |   1  |
--    | 2        |  1   |   0  |
--    | 3        |  1   |   1  |
--    +----------+------+------+
--
--



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.log2;
    use IEEE.math_real.ceil;
    use IEEE.math_real.floor;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Generic SPI Master
entity generic_spi_master is
generic (
            SPI_MODE    : integer range 0 to 3  := 0;           --! SPI transfer Mode
            NUM_CS      : positive              := 1;           --! Number of Channels (chip-selects)
            DW_SFR      : integer               := 8;           --! data width shift register
            CLK_HZ      : positive              := 50_000_000;  --! clock frequency
            SCK_HZ      : positive              := 1_000_000;   --! Shift clock rate; minimal frequency - can be higher due numeric rounding effects
            RST_ACTIVE  : bit                   := '1';         --! Reset active level
            MISO_SYNC   : natural range 0 to 3  := 0;           --! number of MISO sync stages, 0: not implemented
            MISO_FILT   : natural               := 0            --! number of bit length for hysteresis, 0: not implemented
        );
port    (
            -- Clock/Reset
            RST     : in    std_logic;                              --! asynchronous reset
            CLK     : in    std_logic;                              --! clock, rising edge
            -- SPI
            CSN     : out   std_logic_vector(NUM_CS-1 downto 0);    --! chip select
            SCK     : out   std_logic;                              --! Shift forward clock
            MOSI    : out   std_logic;                              --! serial data out;    master-out / slave-in
            MISO    : in    std_logic;                              --! serial data in;     master-in  / slave-out
            -- Parallel
            DI      : in    std_logic_vector(DW_SFR-1 downto 0);    --! Parallel data-in, transmitted via MOSI
            DO      : out   std_logic_vector(DW_SFR-1 downto 0);    --! Parallel data-out, received via MISO
            -- Management
            EN      : in    std_logic;                              --! if in idle master starts receive and transmission
            BSY     : out   std_logic;                              --! transmission is active
            DI_RD   : out   std_logic_vector(NUM_CS-1 downto 0);    --! DI segment transfered into MOSI shift forward register
            DO_WR   : out   std_logic_vector(NUM_CS-1 downto 0)     --! DO segment contents new data
        );
end entity generic_spi_master;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of generic_spi_master is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------
        -- SPI Mode
        constant c_spi_mode_slv     : std_logic_vector(1 downto 0) := std_logic_vector(to_unsigned(SPI_MODE, 2));   --! spi mode as slv
        alias    c_cpol             : std_logic is c_spi_mode_slv(1);                                               --! clock polarity; 0: clock idle low,      1: clock idle high
        alias    c_cpha             : std_logic is c_spi_mode_slv(0);                                               --! clock phase;    0: latch on first edge  1: latch on second edge
        -- SCK Clock Divider
        constant c_sck_div_2        : integer                               := integer(floor(real(CLK_HZ)/(2.0*real(SCK_HZ)))); --! 2.0 cause SCK needs half clocks
        constant c_sck_div_width    : integer                               := integer(ceil(log2(real(c_sck_div_2+1))));        --! half lock counter width
        constant c_sck_cntr_init    : unsigned(c_sck_div_width-1 downto 0)  := to_unsigned(c_sck_div_2-1, c_sck_div_width);     --! init value of SCK counter
        -- Counter
        constant c_bit_cntr_width   : integer := integer(ceil(log2(real(DW_SFR+1))));   --! bit counter for SFR
        constant c_cs_cntr_width    : integer := integer(ceil(log2(real(NUM_CS+1))));   --! chip select channel counter
    ----------------------------------------------


    ----------------------------------------------
    -- SPI state machine
    ----------------------------------------------
        type t_spi_master is
            (
                IDLE,           --! Wait for transfer start
                CSN_START,      --! CSN at transmission start
                SCK_CHG,        --! SFR output (MOSI) is changed
                SCK_CAP,        --! SFR captures input (MISO)
                CSN_END,        --! CSN at transmission start
                CSN_FRC         --! ensures wait of half SCK period
            );
    ----------------------------------------------


    ----------------------------------------------
    -- Signals
    ----------------------------------------------
        -- FSM
        signal current_state    : t_spi_master;     --! FSM state
        signal next_state       : t_spi_master;     --! next state
        -- Counter
        signal sck_cntr_cnt     : unsigned(c_sck_div_width-1 downto 0);     --! SCK clock generator counter value
        signal sck_cntr_ld      : std_logic;                                --! load SCK clock generator
        signal sck_cntr_en      : std_logic;                                --! counter decrements
        signal sck_cntr_is_zero : std_logic;                                --! actual count value is zero
        signal sck_cntr_is_init : std_logic;                                --! counter was initialized
        signal bit_cntr_cnt     : unsigned(c_bit_cntr_width-1 downto 0);    --! bit counter, needed for FSMs end of shift
        signal bit_cntr_ld      : std_logic;                                --! preload bit counter
        signal bit_cntr_is_zero : std_logic;                                --! has zero count
        signal bit_cntr_is_init : std_logic;                                --! has load count
        signal bit_cntr_en      : std_logic;                                --! enable counters decrement
        signal cs_cntr_cnt      : unsigned(c_cs_cntr_width-1 downto 0);     --! CS channel selection counter
        signal cs_cntr_zero     : std_logic;                                --! make counter to zero
        signal cs_cntr_en       : std_logic;                                --! enable increment
        signal cs_cntr_is_min   : std_logic;                                --! has minimal value, zero
        signal cs_cntr_is_max   : std_logic;                                --! has maximal value, NUM_CS-1
        -- SFR
        signal sck_tff          : std_logic;                            --! toggle flip-flop for SCK clock generation
        signal sck_tff_ld       : std_logic;                            --! preload register
        signal sck_tff_en       : std_logic;                            --! enable toggle
        signal mosi_sfr         : std_logic_vector(DW_SFR-1 downto 0);  --! MOSI shift register
        signal mosi_load        : std_logic;                            --! load parallel data
        signal mosi_shift       : std_logic;                            --! shift on next clock rise edge
        signal miso_sfr         : std_logic_vector(DW_SFR-1 downto 0);  --! MISO shift register
        signal miso_shift       : std_logic;                            --! shift on next clock rise edge
        signal miso_shift_dly1  : std_logic;                            --! one clock cycle delayed mosi shift
        -- Miscellaneous
        signal csn_ff           : std_logic_vector(CSN'range);  --! CSN registered out
        signal csn_ff_ld        : std_logic;
        signal csn_ff_en        : std_logic;
    ----------------------------------------------

begin

    ----------------------------------------------
    -- Synthesis/Simulator Messages



    ----------------------------------------------


    ----------------------------------------------
    -- SPI Clock generator & control
    ----------------------------------------------

        --***************************
        p_sck : process( RST, CLK )
        begin
            if ( RST = to_stdulogic(RST_ACTIVE) ) then
                sck_tff <= c_cpol;
            elsif ( rising_edge(CLK) ) then
                if ( '1' = sck_tff_ld ) then
                    sck_tff <= c_cpol;
                elsif ( '1' = sck_tff_en ) then
                    sck_tff <= not sck_tff;
                end if;
            end if;
        end process p_sck;
        --***************************

        --***************************
        -- toggle control
        with current_state select               --! preload
            sck_tff_ld  <=  '1' when IDLE,      --! init
                            '1' when CSN_END,   --! SPI Mode 0/2 last toggle skipped, bring to idle
                            '0' when others;    --! counter not needed, reload

        with current_state select                                                                       --! enable
            sck_tff_en  <=  ((c_cpha or (not bit_cntr_is_init)) and sck_cntr_is_init)   when SCK_CHG,   --! SPI Mode 0/2 TFF toggels not on falling edge of CSN
                            sck_cntr_is_init                                            when SCK_CAP,   --! toggle
                            '0'                                                         when others;    --! hold

        --***************************

        --***************************
        -- port assignment
        SCK <= sck_tff;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- CSN Register & Control
    ----------------------------------------------

        --***************************
        p_csn_reg : process( RST, CLK )
        begin
            if ( RST = to_stdulogic(RST_ACTIVE) ) then
                csn_ff  <= (others => '1');
            elsif ( rising_edge(CLK) ) then
                if ( '1' = csn_ff_ld ) then
                    csn_ff  <= (others => '1');
                elsif ( '1' = csn_ff_en ) then
                    csn_ff                                  <= (others => '1'); --! disable all
                    csn_ff(to_integer(to_01(cs_cntr_cnt)))  <= '0';             --! enable selected channel
                end if;
            end if;
        end process p_csn_reg;
        --***************************

        --***************************
        -- Control
        with current_state select                                                                       --! select channel
            csn_ff_en   <=  '1'                                                         when CSN_START, --! SPI Mode 1/3,
                            (((not c_cpha) and bit_cntr_is_init) and sck_cntr_is_init)  when SCK_CHG,   --! SPI Mode 0/2, CSN is enabled at SCK change
                            '0'                                                         when others;    --! hold last value

        with current_state select               --! deselect all
            csn_ff_ld   <=  '1' when IDLE,      --! all slaves disabled
                            '1' when CSN_FRC,   --! deselect all slaves
                            '0' when others;    --! hold last value
        --***************************

        --***************************
        -- port assignment
        CSN <= csn_ff;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- MOSI Shift Register & Control
    ----------------------------------------------

        --***************************
        -- SFR
        p_mosi_sfr : process( RST, CLK )
        begin
            if ( to_stdulogic(RST_ACTIVE) = RST ) then
                mosi_sfr <= (others => '0');
            elsif ( rising_edge(CLK) ) then
                if ( '1' = mosi_load ) then
                    mosi_sfr <= DI; --! load SFR
                elsif ( '1' = mosi_shift ) then
                    mosi_sfr <= mosi_sfr(mosi_sfr'left-1 downto mosi_sfr'right) & '0';  --! shift one bit to left
                end if;
            end if;
        end process p_mosi_sfr;
        --***************************

        --***************************
        -- SFR Control
        with current_state select                                                   --! MOSI load, dominant
            mosi_load   <=  bit_cntr_is_init and sck_cntr_is_init   when SCK_CHG,   --! new value
                            '0'                                     when others;    --!

        with current_state select                               --! MOSI shift
            mosi_shift  <=  sck_cntr_is_init    when SCK_CHG,   --! shift
                            sck_cntr_is_init    when CSN_END,   --! sets line to zero
                            '0'                 when others;    --! no shift
        --***************************

        --***************************
        -- Input selection
        p_di_sel : process( mosi_load, cs_cntr_cnt )
        begin
            DI_RD                                   <= (others => '0');
            DI_RD(to_integer(to_01(cs_cntr_cnt)))   <= mosi_load;
        end process p_di_sel;
        --***************************

        --***************************
        -- Output
        MOSI <= mosi_sfr(mosi_sfr'left);    --! MSB is shifted out first
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- MISO Shift Register
    ----------------------------------------------

        --***************************
        -- SFR
        p_miso_sfr : process( RST, CLK )
        begin
            if ( to_stdulogic(RST_ACTIVE) = RST ) then
                miso_sfr        <= (others => '0');
                miso_shift_dly1 <= '0';
            elsif ( rising_edge(CLK) ) then
                -- SFR
                if ( '1' = miso_shift ) then    --! TODO, major vote MISO
                    miso_sfr <= miso_sfr(miso_sfr'left-1 downto miso_sfr'right) & MISO; --! shift one bit to left
                end if;
                -- DFF
                miso_shift_dly1 <= miso_shift;
            end if;
        end process p_MISO_sfr;
        --***************************

        --***************************
        -- SFR Control
        with current_state select                               --! MOSI shift
            miso_shift  <=  sck_cntr_is_init    when SCK_CAP,   --! when SCK_CAP,   --! shift
                            '0'                 when others;    --! no shift
        --***************************

        --***************************
        -- Output Capturing
        p_do_sel : process( miso_shift_dly1, cs_cntr_cnt, bit_cntr_is_zero )
        begin
            DO_WR                                   <= (others => '0');
            DO_WR(to_integer(to_01(cs_cntr_cnt)))   <= miso_shift_dly1 and bit_cntr_is_zero;    --! SFR data complete received
        end process p_do_sel;
        --***************************

        --***************************
        -- Output
        DO <= miso_sfr;     --! Captured Serial data is released
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- SCK counter & control
    ----------------------------------------------

        --***************************
        -- c_sck_div_2 > 2 -> go in wait state, and count divider down
        --
        g_sck_cntr : if c_sck_div_2 > 2 generate
            -- registered counter
            p_sck_cntr : process( RST, CLK )
            begin
                if ( to_stdulogic(RST_ACTIVE) = RST ) then
                    -- Reset
                    sck_cntr_cnt <= (others => '0');
                elsif ( rising_edge(CLK) ) then
                    -- SCK Clock generator
                    if ( '1' = sck_cntr_ld ) then
                        -- counter clock divider required?
                        if ( 1 < c_sck_div_2 ) then     --! SCK < CLK/2
                            sck_cntr_cnt <= c_sck_cntr_init;
                        else                            --! SCK = CLK/2
                            sck_cntr_cnt <= (others => '0');
                        end if;
                    elsif ( '1' = sck_cntr_en ) then
                        sck_cntr_cnt <= sck_cntr_cnt-1;
                    end if;
                end if;
            end process p_sck_cntr;

            -- control
            with current_state select                                   --! reload
                sck_cntr_ld <=  sck_cntr_is_zero    when CSN_START,     --! wait for target shift clock generation, and overflow
                                sck_cntr_is_zero    when SCK_CHG,       --!
                                sck_cntr_is_zero    when SCK_CAP,       --!
                                sck_cntr_is_zero    when CSN_END,       --!
                                sck_cntr_is_zero    when CSN_FRC,       --!
                                '1'                 when others;        --! counter not needed, reload

            with current_state select                   --! enable
                sck_cntr_en <=  '1' when CSN_START,     --! count to achieve target clock
                                '1' when SCK_CHG,       --!
                                '1' when SCK_CAP,       --!
                                '1' when CSN_END,       --!
                                '1' when CSN_FRC,       --!
                                '0' when others;        --! no count

        end generate g_sck_cntr;
        --***************************

        --***************************
        -- c_sck_div_2 = 1 -> SCK toggles at every CLK rising edge, no wait state required
        -- c_sck_div_2 = 2 -> go in wait state, but no counter needed cause divider is by wait state itself realized
        --
        g_skip_sck_cntr : if c_sck_div_2 <= 2 generate
            sck_cntr_cnt <= (others => '0');
        end generate g_skip_sck_cntr;
        --***************************

        --***************************
        -- Flags
        sck_cntr_is_zero <= '1' when ( 0 = to_01(sck_cntr_cnt) ) else '0';
        sck_cntr_is_init <= '1' when ( c_sck_cntr_init = to_01(sck_cntr_cnt) ) else '0';
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- CSN counter & control
    ----------------------------------------------

        --***************************
        -- NUM_CS > 1 -> serve multiple CS in round robin method, starting at low index
        --
        g_csn_cntr : if NUM_CS > 1 generate
            -- registered counter
            p_csn_cntr : process( RST, CLK )
            begin
                if ( to_stdulogic(RST_ACTIVE) = RST ) then
                    -- Reset
                    cs_cntr_cnt <= (others => '0');
                elsif ( rising_edge(CLK) ) then
                    -- CS counter
                    if ( '1' = cs_cntr_zero ) then
                        cs_cntr_cnt <= (others => '0');
                    elsif ( '1' = cs_cntr_en ) then
                        if ( cs_cntr_cnt = NUM_CS-1 ) then  --! overflow, always inside CSN vector
                            cs_cntr_cnt <= (others => '0');
                        else
                            cs_cntr_cnt <= cs_cntr_cnt + 1; --! increment
                        end if;
                    end if;
                end if;
            end process p_csn_cntr;

            -- control
            with current_state select                   --! clears counter
                cs_cntr_zero    <=  '1' when IDLE,      --! clear
                                    '0' when others;    --! hold

            with current_state select                                               --! enable
                cs_cntr_en  <=  (not c_cpha) and sck_cntr_is_init   when CSN_END,   --! next channel, SPI Mode 0/2
                                c_cpha and sck_cntr_is_init         when CSN_FRC,   --! next channel, SPI Mode 1/3
                                '0'                                 when others;    --! hold

            -- flags
            cs_cntr_is_min  <= '1' when ( 0 = to_01(cs_cntr_cnt) ) else '0';
            cs_cntr_is_max  <= '1' when ( to_unsigned(NUM_CS-1, cs_cntr_cnt'length) = to_01(cs_cntr_cnt) ) else '0';

        end generate g_csn_cntr;
        --***************************

        --***************************
        -- NUM_CS = 1 -> no counter necessary
        --
        g_skip_csn_cntr : if NUM_CS <= 1 generate
            cs_cntr_cnt <= (others => '0');
        end generate g_skip_csn_cntr;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Counter registers & Control
    ----------------------------------------------

        --***************************
        p_bit_cntr : process( RST, CLK )
        begin
            if ( to_stdulogic(RST_ACTIVE) = RST ) then
                -- Reset
                bit_cntr_cnt    <= (others => '0');
            elsif ( rising_edge(CLK) ) then
                -- Bit counter
                if ( '1' = bit_cntr_ld ) then
                    bit_cntr_cnt <= to_unsigned(DW_SFR, bit_cntr_cnt'length);
                elsif ( '1' = bit_cntr_en ) then
                    bit_cntr_cnt <= bit_cntr_cnt-1;
                end if;
            end if;
        end process p_bit_cntr;
        --***************************

        --***************************
        -- Bit counter
        with current_state select               --! reload
            bit_cntr_ld <=  '1' when IDLE,      --! preload
                            '1' when CSN_FRC,   --! reload counter in SPI Mode 0/2, cause CSN_START is bypassed
                            '1' when CSN_START, --! preload counter
                            '0' when others;    --! counter not needed, reload

        with current_state select                               --! enable
            bit_cntr_en <=  sck_cntr_is_init    when SCK_CHG,   --! decrement counter
                            '0'                 when others;    --! hold

        -- Flags
        bit_cntr_is_zero <= '1' when ( 0 = to_01(bit_cntr_cnt) ) else '0';
        bit_cntr_is_init <= '1' when ( to_unsigned(DW_SFR, bit_cntr_cnt'length) = to_01(bit_cntr_cnt) ) else '0';
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Miscellaneous
    ----------------------------------------------

        --***************************
        -- SPI activity
        with current_state select       --! SPI active
            BSY <=  '0' when IDLE,      --! idle
                    '1' when others;    --! busy
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- FSM state registers
    p_fsm_reg : process( RST, CLK )
    begin
        if ( to_stdulogic(RST_ACTIVE) = RST ) then
            current_state <= IDLE;
        elsif ( rising_edge(CLK) ) then
            current_state <= next_state;
        end if;
    end process p_fsm_reg;
    ----------------------------------------------


    ----------------------------------------------
    -- next state calculation
    p_next_state : process  (
                                current_state,      --! current FSM state
                                EN,                 --! module inputs, enables transceiver
                                sck_cntr_is_zero,   --! sck counter expired
                                bit_cntr_is_zero,   --! count shifted times
                                cs_cntr_cnt         --! selects active CS channel
                            )
    begin
        -- default assignment
        next_state  <= current_state;   --! default assignment

        -- state transitions
        case current_state is

            --***************************
            -- wait for start
            when IDLE =>
                if ( '1' = EN ) then
                    if ( '0' = c_cpha ) then        --! SPI mode 0/2
                        next_state <= SCK_CHG;
                    else
                        next_state <= CSN_START;
                    end if;
                else
                    next_state <= IDLE;
                end if;
            --***************************

            --***************************
            -- Chip select is asserted
            when CSN_START =>
                if ( '1' = sck_cntr_is_zero ) then  --! wait done
                    next_state <= SCK_CHG;
                else                                --! clock division
                    next_state <= CSN_START;
                end if;
            --***************************

            --***************************
            -- MOSI changes
            when SCK_CHG =>
                if ( '1' = sck_cntr_is_zero ) then  --! wait done
                    next_state <= SCK_CAP;
                else                                --! SCK clock division
                    next_state <= SCK_CHG;
                end if;
            --***************************

            --***************************
            -- MISO captured
            when SCK_CAP =>
                if ( '1' = sck_cntr_is_zero ) then
                    if ( '1' = bit_cntr_is_zero ) then
                        if ( '0' = c_cpha ) then    --! SPI mode 0/2
                            next_state <= CSN_END;  --! waits half clock SCK cycle before CS disabling
                        else                        --! SPI mode 1/3
                            next_state <= CSN_FRC;  --! de-select SPI slave
                        end if;
                    else
                        next_state <= SCK_CHG;
                    end if;
                else                                --! clock division
                    next_state <= SCK_CAP;
                end if;
            --***************************

            --***************************
            -- Wait for CSN half SCK cycle before deassert
            when CSN_END =>
                if ( '1' = sck_cntr_is_zero ) then
                    next_state <= CSN_FRC;
                else
                    next_state <= CSN_END;
                end if;
            --***************************

            --***************************
            -- Limits CSN disable/enable to half SCK
            when CSN_FRC =>
                if ( '1' = sck_cntr_is_zero ) then  --! go on
                    if ( '0' = c_cpha ) then                --! SPI Mode 0/2
                        if ( 0 = cs_cntr_cnt ) then         --! all CSN channels served
                            if ( '1' = EN ) then            --! continuous run
                                next_state <= SCK_CHG;      --! next frame
                            else
                                next_state <= IDLE;         --! all channels served
                            end if;
                        else
                            next_state <= SCK_CHG;          --! CSN channels pending
                        end if;
                    else                                    --! SPI Mode 1/3
                        if ( NUM_CS-1 = cs_cntr_cnt ) then  --! all CSN channels served
                            if ( '1' = EN ) then            --! continuous run
                                next_state <= CSN_START;    --! next CS selected channel
                            else
                                next_state <= IDLE;         --! all channels served
                            end if;
                        else                                --! CSN channels pending
                            next_state <= CSN_START;        --! next CS selected channel
                        end if;
                    end if;
                else                                        --! clock division
                    next_state <= CSN_FRC;
                end if;

                -- if ( 1 < c_sck_div_2 ) then                 --! clock division required
                    -- next_state <= CSN_FRC_WT;
                -- else                                        --! SCK = CLK/2 speed
                    -- if ( '0' = c_cpha ) then                --! SPI Mode 0/2
                        -- if ( 0 = cs_cntr_cnt ) then         --! all CSN channels served
                            -- if ( '1' = EN ) then            --! continuous run
                                -- next_state <= SCK_CHG;      --! next frame
                            -- else
                                -- next_state <= IDLE;         --! all channels served
                            -- end if;
                        -- else
                            -- next_state <= SCK_CHG;          --! CSN channels pending
                        -- end if;
                    -- else                                    --! SPI Mode 1/3
                        -- if ( NUM_CS-1 = cs_cntr_cnt ) then  --! all CSN channels served
                            -- if ( '1' = EN ) then            --! continuous run
                                -- next_state <= CSN_START;    --! next CS selected channel
                            -- else
                                -- next_state <= IDLE;         --! all channels served
                            -- end if;
                        -- else                                --! CSN channels pending
                            -- next_state <= CSN_START;        --! next CS selected channel
                        -- end if;
                    -- end if;
                -- end if;
            --***************************

            --***************************
            -- CSN SCK division wait
            -- when CSN_FRC_WT =>
                -- if ( '1' = sck_cntr_is_zero ) then
                    -- if ( '0' = c_cpha ) then                --! SPI Mode 0/2
                        -- if ( 0 = cs_cntr_cnt ) then         --! all CSN channels served
                            -- if ( '1' = EN ) then            --! continuous run
                                -- next_state <= SCK_CHG;      --! next frame
                            -- else
                                -- next_state <= IDLE;         --! all channels served
                            -- end if;
                        -- else
                            -- next_state <= SCK_CHG;          --! CSN channels pending
                        -- end if;
                    -- else                                    --! SPI Mode 1/3
                        -- if ( 0 = cs_cntr_cnt ) then         --! all CSN channels served, in case of CSN_FRC_WT, cs_cntr is increment/overflows in CSN_FRC, therefore check here for zero
                            -- if ( '1' = EN ) then            --! continuous run
                                -- next_state <= CSN_START;    --! next CS selected channel
                            -- else
                                -- next_state <= IDLE;         --! all channels served
                            -- end if;
                        -- else                                --! CSN channels pending
                            -- next_state <= CSN_START;        --! next CS selected channel
                        -- end if;
                    -- end if;
                -- else
                    -- next_state <= CSN_FRC_WT;
                -- end if;
            --***************************

            --***************************
            -- Recovering from illegal state transitions
            when others =>
                next_state <= IDLE;
            --***************************

        end case;
    end process p_next_state;
    ----------------------------------------------

end architecture rtl;
--------------------------------------------------------------------------
