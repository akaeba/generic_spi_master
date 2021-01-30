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
-- @brief:          SPI Master
--
--                  Generic SPI master with multiple chip select lines
--                  and a at compile time adjustable transfer rate.
--					The chip select lines use a round robin arbitration 
--					starting with lowest CSN index.
--************************************************************************



--
-- Important Hints:
-- ================
--
--  Settings (adjustable at compile time)
--  -------------------------------------
--      SPI_MODE:		SPI transmission mode									values = 0,1,2,3	
--		NUM_CS			number of ch
--		DW_SFR			
--		CLK_HZ      	
--		SCK_HZ			
--		RST_ACTIVE		
--		DO_SFR_OUT:				
--		MISO_SYNC_STG:	number of sync stages; synchronizes MISO data input;	values = 0,2,3
--		MISO_HYS_STG
--
--  Miscellaneous
--  -------------
--      DI/DO:     	bit-width of the SFR multiplied by the CS channel number
--					  * the lowest bit indices belonging to the lowest index in CSN
--					  * allows an generic data/channel width w/o defining data types
--					  * slicing into SFR width signals can done with "alias" statement
--
--	SPI Mode
--	--------
--	  +----------+------+------+
--	  | SPI Mode | CPOL	| CPHA |
--	  +----------+------+------+
--	  |	0		 |	0	|	0  |
--	  |	1		 |	0	|	1  |
--	  |	2		 |	1	|	0  |
--	  |	3		 |	1	|	1  |
--	  +----------+------+------+
--
--



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.math_real.log2;
	use IEEE.math_real.ceil;
	use IEEE.math_real.floor;
    use IEEE.math_real.round;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- Generic SPI Master
entity generic_spi_master is
generic (
            SPI_MODE		: integer range 0 to 3	:= 0;			--! SPI transfer Mode
			NUM_CS			: positive				:= 1;			--! Number of Channels (chip-selects)
			DW_SFR			: integer  				:= 8;           --! data width shift register
            CLK_HZ      	: positive              := 50_000_000;  --! clock frequency
            SCK_HZ			: positive				:= 1_000_000;	--! Shift clock rate; minimal frequency - can be higher due numeric rounding effects
			RST_ACTIVE		: bit					:= '1';			--! Reset active level
			MISO_SYNC_STG	: natural				:= 2;			--! number of MISO sync stages, 0: not implemented
			MISO_HYS_STG	: natural 				:= 0			--! number of bit length for hysteresis, 0: not implemented
        );
port    (
            -- Clock/Reset
            RST     : in    std_logic;          					--! asynchronous reset
            CLK     : in    std_logic;          					--! clock, rising edge
            -- SPI
            SCK		: out	std_logic;								--! Shift forward clock
			CSN		: out	std_logic_vector(NUM_CS-1 downto 0);	--! chip select
			MOSI	: out	std_logic;								--! serial data out;	master-out / slave-in
			MISO	: in	std_logic;								--! serial data in;		master-in  / slave-out
			-- Parallel
			DI		: in	std_logic_vector(DW_SFR-1 downto 0);	--! Parallel data-in, transmitted via MOSI
            DO		: out   std_logic_vector(DW_SFR-1 downto 0);	--! Parallel data-out, received via MISO
            -- Management
			EN		: in	std_logic;								--! if in idle master starts receive and transmission
			BSY		: out	std_logic;								--! transmission is active
			DO_WR	: out	std_logic_vector(NUM_CS-1 downto 0);	--! DO segment contents new data
			DI_RD	: out	std_logic_vector(NUM_CS-1 downto 0)		--! DI segment transfered into MOSI shift forward register
        );
end entity generic_spi_master;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture rtl of generic_spi_master is

    ----------------------------------------------
    -- Constants
    ----------------------------------------------
		-- SPI Mode
		constant c_spi_mode_slv		: std_logic_vector(1 downto 0) := std_logic_vector(to_unsigned(SPI_MODE, 2));	--! spi mode as slv
		alias	 c_cpol				: std_logic is c_spi_mode_slv(1);												--! clock polarity; 0: clock idle low, 		1: clock idle high
		alias	 c_cpha				: std_logic is c_spi_mode_slv(0);												--! clock phase;	0: latch on first edge	1: latch on second edge
		-- SCK Clock Divider
		constant c_sck_div_2		: integer := integer(floor(real(CLK_HZ)/(2.0*real(SCK_HZ))));	--! 2.0 cause SCK needs half clocks
		constant c_sck_div_width	: integer := integer(ceil(log2(real(c_sck_div_2+1))));			--! half lock counter width
		-- Counter
		constant c_bit_cntr_width	: integer := integer(ceil(log2(real(DW_SFR+1))));	--! bit counter for SFR
		constant c_cs_cntr_width	: integer := integer(ceil(log2(real(NUM_CS+1))));	--! chip select channel counter
	----------------------------------------------
	
	
    ----------------------------------------------
    -- SPI state machine
    ----------------------------------------------
		type t_spi_master is
			(
				IDLE,			--! Wait for transfer start
				CSN_START,		--! CSN at transmission start
				CSN_START_WT,	--! wait for half clock
				SCK_CHG,		--! SFR output (MOSI) is changed
				SCK_CHG_WT,		--! Clock divider wait state
				SCK_CAP,		--! SFR captures input (MISO)
				SCK_CAP_WT,		--! clock divider wait state
				CSN_END,		--! CSN at transmission start
				CSN_END_WT,		--! wait for half clock
				CSN_FRC,		--! ensures wait of half SCK period
				CSN_FRC_WT		--! wait for half clock
			);
	----------------------------------------------
	
	
    ----------------------------------------------
    -- Signals
    ----------------------------------------------
		-- FSM
		signal current_state	: t_spi_master;		--! FSM state
		signal next_state		: t_spi_master;		--! next state
		-- Counter
		signal sck_cntr_cnt		: unsigned(c_sck_div_width-1 downto 0);		--! SCK clock generator counter value
		signal sck_cntr_ld		: std_logic;								--! load SCK clock generator
		signal sck_cntr_en		: std_logic;								--! counter decrements
		signal sck_cntr_is_zero	: std_logic;								--! actual count value is zero
		signal bit_cntr_cnt		: unsigned(c_bit_cntr_width-1 downto 0);	--! bit counter, needed for FSMs end of shift
		signal bit_cntr_ld		: std_logic;								--! preload bit counter
		signal bit_cntr_is_zero	: std_logic;								--! has zero count
		signal bit_cntr_is_init	: std_logic;								--! has load count
		signal bit_cntr_en		: std_logic;								--! enable counters decrement
		signal cs_cntr_cnt		: unsigned(c_cs_cntr_width-1 downto 0);		--! CS channel selection counter
		signal cs_cntr_zero		: std_logic;								--! make counter to zero
		signal cs_cntr_en		: std_logic;								--! enable increment
		-- SFR
		signal sck_tff			: std_logic;							--! toggle flip-flop for SCK clock generation
		signal sck_tff_ld		: std_logic;							--! preload register
		signal sck_tff_en		: std_logic;							--! enable toggle
		signal mosi_sfr			: std_logic_vector(DW_SFR-1 downto 0);	--! MOSI shift register
		signal mosi_load		: std_logic;							--! load parallel data
		signal mosi_shift		: std_logic;							--! shift on next clock rise edge
		signal miso_sfr			: std_logic_vector(DW_SFR-1 downto 0);	--! MISO shift register
		signal miso_shift		: std_logic;							--! shift on next clock rise edge
		-- Miscellaneous
		signal csn_ff			: std_logic_vector(CSN'range);	--! CSN registered out
		signal csn_ff_ld		: std_logic;
		signal csn_ff_en		: std_logic;
		
		
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
				sck_tff	<= c_cpol;
			elsif ( rising_edge(CLK) ) then
				if ( '1' = sck_tff_ld ) then
					sck_tff	<= c_cpol;
				elsif ( '1' = sck_tff_en ) then
					sck_tff <= not sck_tff;
				end if;
			end if;
		end process p_sck;
		--***************************
		
		--***************************
		-- toggle control
		with current_state select				--! preload
			sck_tff_ld	<= 	'1' when IDLE,		--! init
							'1' when CSN_END,	--! SPI Mode 0/2 last toggle skipped, bring to idle
							'0' when others;	--! counter not needed, reload
		
		with current_state select												--! enable
			sck_tff_en	<= 	(c_cpha or (not bit_cntr_is_init))	when SCK_CHG,	--! SPI Mode 0/2 TFF toggels not on falling edge of CSN
							'1'									when SCK_CAP,	--! toggle
							'0' 								when others;	--! hold
							
		--***************************
		
		--***************************
		-- port assignment
		SCK	<= sck_tff;
		--***************************
		
	----------------------------------------------
	
	
    ----------------------------------------------
    -- CSN Register & Control
	----------------------------------------------
	
		--***************************
		p_csn_reg : process( RST, CLK )
		begin
			if ( RST = to_stdulogic(RST_ACTIVE) ) then
				csn_ff	<= (others => '1');
			elsif ( rising_edge(CLK) ) then
				if ( '1' = csn_ff_ld ) then
					csn_ff	<= (others => '1');
				elsif ( '1' = csn_ff_en ) then
					csn_ff									<= (others => '1');	--! disable all
					csn_ff(to_integer(to_01(cs_cntr_cnt)))	<= '0';				--! enable selected channel
				end if;
			end if;
		end process p_csn_reg;
		--***************************
		
		--***************************
		-- Control
		with current_state select												--! select channel
			csn_ff_en	<=	'1'									when CSN_START,	--! SPI Mode 1/3, 
							(not c_cpha) and bit_cntr_is_init	when SCK_CHG,	--! SPI Mode 0/2, CSN is enabled at SCK change
							'0'									when others;	--! hold last value	
							
		with current_state select				--! deselect all
			csn_ff_ld	<=	'1'	when IDLE,		--! all slaves disabled
							'1'	when CSN_FRC,	--! deselect all slaves
							'0'	when others;	--! hold last value	
		--***************************
		
		--***************************
		-- port assignment
		CSN	<= csn_ff;
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
					mosi_sfr <= DI;	--! load SFR
				elsif ( '1' = mosi_shift ) then
					mosi_sfr <= mosi_sfr(mosi_sfr'left-1 downto mosi_sfr'right) & '0';	--! shift one bit to left
				end if;
			end if;
		end process p_mosi_sfr;
		--***************************
		
		--***************************
		-- SFR Control
		with current_state select								--! MOSI load, dominant
			mosi_load	<=	bit_cntr_is_init	when SCK_CHG,	--! new value
							'0' 				when others;	--! 

		with current_state select				--! MOSI shift
			mosi_shift	<=	'1'	when SCK_CHG,	--! shift
							'1'	when CSN_END,	--! sets line to zero
							'0' when others;	--! no shift
		--***************************
		
		--***************************
		-- Input selection
		p_di_sel : process( mosi_load, cs_cntr_cnt )
		begin
			DI_RD									<= (others => '0');
			DI_RD(to_integer(to_01(cs_cntr_cnt)))	<= mosi_load;
		end process p_di_sel;
		--***************************
		
		--***************************
		-- Output
		MOSI <= mosi_sfr(mosi_sfr'left);	--! MSB is shifted out first
		--***************************
		
	----------------------------------------------
	
	
    ----------------------------------------------
    -- MISO Shift Register
	p_miso_sfr : process( RST, CLK )
	begin
		if ( to_stdulogic(RST_ACTIVE) = RST ) then

		elsif ( rising_edge(CLK) ) then

		end if;
	end process p_MISO_sfr;
	----------------------------------------------
	
	
    ----------------------------------------------
    -- Counter registers & Control
	----------------------------------------------
	
		--***************************
		p_cntr_reg : process( RST, CLK )
		begin
			if ( to_stdulogic(RST_ACTIVE) = RST ) then
				-- Reset
				sck_cntr_cnt	<= (others => '0');
				bit_cntr_cnt 	<= (others => '0');
				cs_cntr_cnt		<= (others => '0');
			elsif ( rising_edge(CLK) ) then
				-- SCK Clock generator
				if ( '1' = sck_cntr_ld ) then
					sck_cntr_cnt <= to_unsigned(c_sck_div_2-2, sck_cntr_cnt'length);	-- preload counter
				elsif ( '1' = sck_cntr_en ) then
					sck_cntr_cnt <= sck_cntr_cnt-1;
				end if;
				-- Bit counter
				if ( '1' = bit_cntr_ld ) then
					bit_cntr_cnt <= to_unsigned(DW_SFR, bit_cntr_cnt'length);
				elsif ( '1' = bit_cntr_en ) then
					bit_cntr_cnt <= bit_cntr_cnt-1;
				end if;
				-- CS counter
				if ( '1' = cs_cntr_zero ) then
					cs_cntr_cnt <= (others => '0');
				elsif ( '1' = cs_cntr_en ) then
					if ( cs_cntr_cnt = NUM_CS-1 ) then	--! overflow, always inside CSN vector
						cs_cntr_cnt <= (others => '0');
					else
						cs_cntr_cnt <= cs_cntr_cnt + 1;	--! increment
					end if;
				end if;
			end if;
		end process p_cntr_reg;
		--***************************
		
		--***************************
		-- SCK clock divider
		with current_state select									--! reload
			sck_cntr_ld	<=	sck_cntr_is_zero	when CSN_START_WT,	--! wait for target shift clock generation
							sck_cntr_is_zero 	when SCK_CHG_WT,	--! 
							sck_cntr_is_zero 	when SCK_CAP_WT,	--!
							sck_cntr_is_zero	when CSN_END_WT,	--!
							sck_cntr_is_zero	when CSN_FRC_WT,	--!
							'1' 				when others;		--! counter not needed, reload
		
		with current_state select						--! enable
			sck_cntr_en	<= 	'1'	when CSN_START_WT,	--! count to achieve target clock
							'1' when SCK_CHG_WT,	--! 
							'1' when SCK_CAP_WT,	--!
							'1'	when CSN_END_WT,	--!
							'1' when CSN_FRC_WT,	--!
							'0' when others;		--! no count
		
		-- Flags
		sck_cntr_is_zero <= '1' when ( 0 = to_01(sck_cntr_cnt) ) else '0';
		--***************************
		
		--***************************
		-- Bit counter
		with current_state select				--! reload
			bit_cntr_ld	<= 	'1' when IDLE,		--! preload
							'1' when CSN_START,	--! preload counter
							'0' when others;	--! counter not needed, reload
		
		with current_state select				--! enable
			bit_cntr_en	<= 	'1'	when SCK_CAP,	--! decrement counter
							'0' when others;	--! hold
							
		-- Flags
		bit_cntr_is_zero <= '1' when ( 0 = to_01(bit_cntr_cnt) ) else '0';
		bit_cntr_is_init <= '1' when ( to_unsigned(DW_SFR, bit_cntr_cnt'length) = to_01(bit_cntr_cnt) ) else '0';	
		--***************************
		
		--***************************
		-- CSN counter counter
		with current_state select					--! clears counter
			cs_cntr_zero	<= 	'1' when IDLE,		--! clear
								'0' when others;	--! hold
		
		with current_state select				--! enable
			cs_cntr_en	<= 	'1'	when CSN_END,	--! next channel
							'0' when others;	--! hold
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
    p_next_state : process	(
                                current_state,		--! current FSM state
								EN,					--! module inputs, enables transceiver
								sck_cntr_cnt,	--! clock division
								bit_cntr_cnt,		--! count shifted times
								cs_cntr_cnt			--! selects active CS channel
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
					if ( '0' = c_cpha ) then		--! SPI mode 0/2
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
				if ( 1 < c_sck_div_2 ) then		--! clock division required
					next_state <= CSN_START_WT;	--! wait for clock division
				else							--! runs with half main clock
					-- TODO
				end if;
			--***************************

			--***************************
			-- Clock division
			when CSN_START_WT =>
				if ( 0 < sck_cntr_cnt ) then
					next_state <= CSN_START_WT;
				else
					next_state <= SCK_CHG;
				end if;
			--***************************

			--***************************
			-- MOSI changes (SCK I/II)
			when SCK_CHG =>
				if ( 1 < c_sck_div_2 ) then		--! clock division required
					next_state <= SCK_CHG_WT;
				else
					-- TODO
				end if;
			--***************************
			
			--***************************
			-- MOSI changes (SCK I/II) - clock division
			when SCK_CHG_WT =>
				if ( 0 = sck_cntr_cnt ) then
					--if ( ('0' = c_cpha) and (1 = bit_cntr_cnt) ) then	--! SPI Mode 0/2: skip last half SCK cycle
					--	next_state <= CSN_END;							--! waits half clock SCK cycle before CS disabling
					--else
					next_state <= SCK_CAP;
					--end if;
				else
					next_state <= SCK_CHG_WT;
				end if;
			--***************************
			
			--***************************
			-- MISO captured (SCK II/II)
			when SCK_CAP =>
				if ( 1 < c_sck_div_2 ) then		--! clock division required
					next_state <= SCK_CAP_WT;
				else
					-- TODO
				end if;
			--***************************
			
			--***************************
			-- MISO captured (SCK II/II) - clock division
			when SCK_CAP_WT =>
				if ( 0 < sck_cntr_cnt ) then
					next_state <= SCK_CAP_WT;
				else
					if ( 0 = bit_cntr_cnt ) then
						next_state <= CSN_END;	--! waits half clock SCK cycle before CS disabling
					else
						next_state <= SCK_CHG;
					end if;
					
				end if;
			--***************************
			
			--***************************
			-- Wait for CSN half SCK cycle before deassert
			when CSN_END =>
				if ( 1 < c_sck_div_2 ) then		--! clock division required
					next_state <= CSN_END_WT;
				else
					next_state <= CSN_FRC;
				end if;
			--***************************
			
			--***************************
			-- CSN SCK division wait
			when CSN_END_WT =>
				if ( 0 < sck_cntr_cnt ) then
					next_state <= CSN_END_WT;
				else
					next_state <= CSN_FRC;
				end if;
			--***************************
			
			--***************************
			-- Limits CSN disable/enable to half SCK
			when CSN_FRC =>
				if ( 1 < c_sck_div_2 ) then		--! clock division required
					next_state <= CSN_FRC_WT;
				else
					if ( 0 = cs_cntr_cnt ) then 	--! NUM_CS-1 go in idle, through overflow in CSN_END state, check for zero
						next_state <= IDLE;			--! all channels served
					else
						next_state <= CSN_START;	--! next CS selected channel
					end if;
				end if;
			--***************************
			
			--***************************
			-- CSN SCK division wait
			when CSN_FRC_WT =>
				if ( 0 < sck_cntr_cnt ) then
					next_state <= CSN_FRC_WT;
				else
					if ( 0 = cs_cntr_cnt ) then 	--! NUM_CS-1 go in idle, through overflow in CSN_END state, check for zero
						next_state <= IDLE;			--! all channels served
					else
						next_state <= CSN_START;	--! next CS selected channel
					end if;
					
				end if;
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
