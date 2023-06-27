----------------------------------------------------------------------------------
-- Company: Peralex Electronics
-- Engineer: GT
-- 
-- Create Date: 08.05.2023
-- Design Name: 
-- Module Name: ddc_resamp_int4_dec5 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Resamples DDC data from 640MSPS/320MSPS/160MSPS/80MSPS to 512MSPS/256MSPS/128MSPS/64MSPS.
-- Assumes four samples provided in a clock cycle. Interfaces to SKARAB ADC operating
-- in decimate by 4, 8, 16 or 32 mode at 2560MSPS.
--
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddc_resamp_int4_dec5 is
	port (
        clk : in std_logic;
        reset : in std_logic;
        ddc_data_in : in std_logic_vector(127 downto 0);
        ddc_data_val_in : in std_logic;
        resamp_ddc_data_out : out std_logic_vector(127 downto 0);
        resamp_ddc_data_val_out : out std_logic);
end ddc_resamp_int4_dec5;

architecture arch_ddc_resamp_int4_dec5 of ddc_resamp_int4_dec5 is
    
    type T_COMB5_STATE is (
    COMB5_STATE_0,
    COMB5_STATE_1,
    COMB5_STATE_2,
    COMB5_STATE_3,
    COMB5_STATE_4);

    constant C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE : integer := 4;
    constant C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE : integer := 5;
    constant C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE : integer := 20;
    constant C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE : integer := 4;
    constant C_INT_FILT_INPUT_DATA_WIDTH : integer := 16;
    constant C_INT_FILT_INPUT_AXI_DATA_WIDTH : integer := 16;
    constant C_INT_FILT_OUTPUT_AXI_DATA_WIDTH : integer := 40;
    constant C_INT_FILT_OUTPUT_DATA_WIDTH : integer := 34;
    constant C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH : integer := 32;

    component resamp_int4_dec5_c18_dp16_60dB
    port ( 
        aresetn : in std_logic;
        aclk : in std_logic;
        s_axis_data_tvalid : in std_logic;
        s_axis_data_tready : out std_logic;
        s_axis_data_tdata : in std_logic_vector ((C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto 0);
        m_axis_data_tvalid : out std_logic;
        m_axis_data_tdata : out std_logic_vector ((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_AXI_DATA_WIDTH - 1) downto 0));
    end component;

    component unbiased_convergent_round
	generic (
        input_width	: integer := 18;
        output_width : integer := 16);
    port(
        rst : in std_logic;
        clk : in std_logic;							   
        din_en : in std_logic;
        din : in std_logic_vector((input_width - 1) downto 0);
        dout_vld : out std_logic;
        dout : out std_logic_vector((output_width - 1) downto 0));
    end component;

    component data_recorder_multi
	generic (						 
        data_width : integer;
        samples_per_clock : integer;
        output_file_name : string);
    port(
        rst : in std_logic;
        clk : in std_logic;
        dval : in std_logic;
        din : in std_logic_vector((samples_per_clock * data_width - 1) downto 0));
    end component;
       
       
       
    signal resetn : std_logic := '0';
  
  	subtype ST_FILT_IN_DATA is std_logic_vector((C_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
    type T_FILT_IN_DATA is array(0 to (C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_FILT_IN_DATA;
    signal ddc_data_real_demux : T_FILT_IN_DATA;
    signal ddc_data_imag_demux : T_FILT_IN_DATA;
    signal ddc_data_val_demux : std_logic;
    signal ddc_data_real : std_logic_vector ((C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
    signal ddc_data_imag : std_logic_vector ((C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
        
    signal current_comb5_state : T_COMB5_STATE;        
  	subtype ST_FILT_IN_DATA_COMB5 is std_logic_vector((C_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
    type T_FILT_IN_DATA_COMB5 is array(0 to (C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_FILT_IN_DATA_COMB5;
    signal comb5_ddc_data_real_demux : T_FILT_IN_DATA_COMB5;
    signal comb5_ddc_data_imag_demux : T_FILT_IN_DATA_COMB5;
    signal comb5_ddc_data_val_demux : std_logic;
    signal next_comb5_ddc_data_real_demux : T_FILT_IN_DATA_COMB5;
    signal next_comb5_ddc_data_imag_demux : T_FILT_IN_DATA_COMB5;
    signal comb5_ddc_data_real : std_logic_vector ((C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
    signal comb5_ddc_data_imag : std_logic_vector ((C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
        
    signal s_axis_data_tvalid : std_logic;
    signal s_axis_data_tready_real : std_logic;
    signal s_axis_data_tready_imag : std_logic;
    signal s_axis_data_tdata_real : std_logic_vector ((C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto 0);
    signal s_axis_data_tdata_imag : std_logic_vector ((C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto 0);
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tdata_real : std_logic_vector ((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_AXI_DATA_WIDTH - 1) downto 0); 
    signal m_axis_data_tdata_imag : std_logic_vector ((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_AXI_DATA_WIDTH - 1) downto 0); 
    
    signal filt_int4_data_real : std_logic_vector((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    signal filt_int4_data_imag : std_logic_vector((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    signal filt_int4_data_val : std_logic;
    
    signal filt_int4_data_trunc_real : std_logic_vector((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH - 1) downto 0);
    signal filt_int4_data_trunc_imag : std_logic_vector((C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH - 1) downto 0);

	subtype ST_FILT_INT4_DATA is std_logic_vector((C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    type T_FILT_INT4_DATA is array(0 to (C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_FILT_INT4_DATA;       
    signal filt_int4_data_demux_real : T_FILT_INT4_DATA;
    signal filt_int4_data_demux_imag : T_FILT_INT4_DATA;
    signal filt_int4_data_val_reg : std_logic;
    signal filt_int4_data_demux_real_reg : T_FILT_INT4_DATA;
    signal filt_int4_data_demux_imag_reg : T_FILT_INT4_DATA;

	subtype ST_FILT_INT4_DEC5_DATA is std_logic_vector((C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    type T_FILT_INT4_DEC5_DATA is array(0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_FILT_INT4_DEC5_DATA; 
    signal filt_int4_dec5_data_val : std_logic;
    signal filt_int4_dec5_data_demux_real : T_FILT_INT4_DEC5_DATA;
    signal filt_int4_dec5_data_demux_imag : T_FILT_INT4_DEC5_DATA;
    signal filt_int4_dec5_data_real : std_logic_vector((C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    signal filt_int4_dec5_data_imag : std_logic_vector((C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    signal filt_int4_dec5_data_trunc_real : std_logic_vector((C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH - 1) downto 0);
    signal filt_int4_dec5_data_trunc_imag : std_logic_vector((C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH - 1) downto 0);
      
	subtype ST_FILT_INT4_DEC5_ROUND_DATA is std_logic_vector(15 downto 0);
    type T_FILT_INT4_DEC5_ROUND_DATA is array(0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_FILT_INT4_DEC5_ROUND_DATA;       
    signal filt_int4_dec5_round_data_val : std_logic_vector(0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1));
    signal filt_int4_dec5_round_data_demux_real : T_FILT_INT4_DEC5_ROUND_DATA;
    signal filt_int4_dec5_round_data_demux_imag : T_FILT_INT4_DEC5_ROUND_DATA;
    signal filt_int4_dec5_round_data_real : std_logic_vector((C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * 16 - 1) downto 0);
    signal filt_int4_dec5_round_data_imag : std_logic_vector((C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * 16 - 1) downto 0);
          
begin

    gen_resetn : process(clk)
    begin
        if (rising_edge(clk))then
            resetn <= not reset;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- REGISTER INPUTS TO IMPROVE TIMING
----------------------------------------------------------------------------------------------

    -- SPLIT REAL AND IMAGINARY INPUTS
    gen_ddc_data_reg : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                for a in 0 to (C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE - 1) loop
                    ddc_data_real_demux(a) <= (others => '0');
                    ddc_data_imag_demux(a) <= (others => '0');
                end loop;
                
                ddc_data_val_demux <= '0';
                
            else
                ddc_data_real_demux(0) <= ddc_data_in(15 downto 0);
                ddc_data_real_demux(1) <= ddc_data_in(47 downto 32);
                ddc_data_real_demux(2) <= ddc_data_in(79 downto 64);
                ddc_data_real_demux(3) <= ddc_data_in(111 downto 96);
            
                ddc_data_imag_demux(0) <= ddc_data_in(31 downto 16);
                ddc_data_imag_demux(1) <= ddc_data_in(63 downto 48);
                ddc_data_imag_demux(2) <= ddc_data_in(95 downto 80);
                ddc_data_imag_demux(3) <= ddc_data_in(127 downto 112);
            
                ddc_data_val_demux <= ddc_data_val_in;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- COMBINE SAMPLES INTO 5 SAMPLES PER CLOCK CYCLE TO ALLOW FILTER OPTIMISATION AT DECIMATION STAGE
----------------------------------------------------------------------------------------------

    gen_current_comb5_state : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                current_comb5_state <= COMB5_STATE_0;
                comb5_ddc_data_val_demux <= '0';
                for a in 0 to (C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE - 1) loop
                    comb5_ddc_data_real_demux(a) <= (others => '0');
                    comb5_ddc_data_imag_demux(a) <= (others => '0');
                    next_comb5_ddc_data_real_demux(a) <= (others => '0');
                    next_comb5_ddc_data_imag_demux(a) <= (others => '0');
                end loop;            
            else
                comb5_ddc_data_val_demux <= '0';

                if (ddc_data_val_demux = '1')then
                    case current_comb5_state is
                        when COMB5_STATE_0 =>
                        current_comb5_state <= COMB5_STATE_1;
        
                        comb5_ddc_data_real_demux(0) <= ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(1) <= ddc_data_real_demux(1);
                        comb5_ddc_data_real_demux(2) <= ddc_data_real_demux(2);
                        comb5_ddc_data_real_demux(3) <= ddc_data_real_demux(3);

                        comb5_ddc_data_imag_demux(0) <= ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(1) <= ddc_data_imag_demux(1);
                        comb5_ddc_data_imag_demux(2) <= ddc_data_imag_demux(2);
                        comb5_ddc_data_imag_demux(3) <= ddc_data_imag_demux(3);

                        when COMB5_STATE_1 =>
                        current_comb5_state <= COMB5_STATE_2;
                        
                        comb5_ddc_data_real_demux(4) <= ddc_data_real_demux(0);
                        next_comb5_ddc_data_real_demux(0) <= ddc_data_real_demux(1);
                        next_comb5_ddc_data_real_demux(1) <= ddc_data_real_demux(2);
                        next_comb5_ddc_data_real_demux(2) <= ddc_data_real_demux(3);

                        comb5_ddc_data_imag_demux(4) <= ddc_data_imag_demux(0);
                        next_comb5_ddc_data_imag_demux(0) <= ddc_data_imag_demux(1);
                        next_comb5_ddc_data_imag_demux(1) <= ddc_data_imag_demux(2);
                        next_comb5_ddc_data_imag_demux(2) <= ddc_data_imag_demux(3);

                        comb5_ddc_data_val_demux <= '1';
                        
                        when COMB5_STATE_2 =>
                        current_comb5_state <= COMB5_STATE_3;
                        
                        comb5_ddc_data_real_demux(0) <= next_comb5_ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(1) <= next_comb5_ddc_data_real_demux(1);
                        comb5_ddc_data_real_demux(2) <= next_comb5_ddc_data_real_demux(2);
                        comb5_ddc_data_real_demux(3) <= ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(4) <= ddc_data_real_demux(1);
                        next_comb5_ddc_data_real_demux(0) <= ddc_data_real_demux(2);
                        next_comb5_ddc_data_real_demux(1) <= ddc_data_real_demux(3);
                        
                        comb5_ddc_data_imag_demux(0) <= next_comb5_ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(1) <= next_comb5_ddc_data_imag_demux(1);
                        comb5_ddc_data_imag_demux(2) <= next_comb5_ddc_data_imag_demux(2);
                        comb5_ddc_data_imag_demux(3) <= ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(4) <= ddc_data_imag_demux(1);
                        next_comb5_ddc_data_imag_demux(0) <= ddc_data_imag_demux(2);
                        next_comb5_ddc_data_imag_demux(1) <= ddc_data_imag_demux(3);
                        
                        comb5_ddc_data_val_demux <= '1';
                        
                        when COMB5_STATE_3 =>    
                        current_comb5_state <= COMB5_STATE_4;

                        comb5_ddc_data_real_demux(0) <= next_comb5_ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(1) <= next_comb5_ddc_data_real_demux(1);
                        comb5_ddc_data_real_demux(2) <= ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(3) <= ddc_data_real_demux(1);
                        comb5_ddc_data_real_demux(4) <= ddc_data_real_demux(2); 
                        next_comb5_ddc_data_real_demux(0) <= ddc_data_real_demux(3);

                        comb5_ddc_data_imag_demux(0) <= next_comb5_ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(1) <= next_comb5_ddc_data_imag_demux(1);
                        comb5_ddc_data_imag_demux(2) <= ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(3) <= ddc_data_imag_demux(1);
                        comb5_ddc_data_imag_demux(4) <= ddc_data_imag_demux(2); 
                        next_comb5_ddc_data_imag_demux(0) <= ddc_data_imag_demux(3);

                        comb5_ddc_data_val_demux <= '1';

                        when COMB5_STATE_4 =>    
                        current_comb5_state <= COMB5_STATE_0;
        
                        comb5_ddc_data_real_demux(0) <= next_comb5_ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(1) <= ddc_data_real_demux(0);
                        comb5_ddc_data_real_demux(2) <= ddc_data_real_demux(1);
                        comb5_ddc_data_real_demux(3) <= ddc_data_real_demux(2);
                        comb5_ddc_data_real_demux(4) <= ddc_data_real_demux(3);
                    
                        comb5_ddc_data_imag_demux(0) <= next_comb5_ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(1) <= ddc_data_imag_demux(0);
                        comb5_ddc_data_imag_demux(2) <= ddc_data_imag_demux(1);
                        comb5_ddc_data_imag_demux(3) <= ddc_data_imag_demux(2);
                        comb5_ddc_data_imag_demux(4) <= ddc_data_imag_demux(3);
        
                        comb5_ddc_data_val_demux <= '1';
        
                    end case;
                end if;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- FIR FILTER PERFORMS INTERPOLATE BY 4 ONLY
----------------------------------------------------------------------------------------------
    
    s_axis_data_tvalid <= comb5_ddc_data_val_demux and s_axis_data_tready_real and s_axis_data_tready_imag;
    
    -- MULTIPLEX THE INDIVIDUAL SAMPLES
    generate_s_axis_data_tdata : for a in 0 to (C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        s_axis_data_tdata_real(((a + 1) * C_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto (a * C_INT_FILT_INPUT_AXI_DATA_WIDTH)) <= comb5_ddc_data_real_demux(a);
        s_axis_data_tdata_imag(((a + 1) * C_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto (a * C_INT_FILT_INPUT_AXI_DATA_WIDTH)) <= comb5_ddc_data_imag_demux(a);
    end generate generate_s_axis_data_tdata;
         
    -- REAL INTERPOLATE BY 4 FIR FILTER
    resamp_int4_dec5_c18_dp16_60dB_real : resamp_int4_dec5_c18_dp16_60dB
    port map( 
        aresetn => resetn,
        aclk => clk,
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready_real,
        s_axis_data_tdata => s_axis_data_tdata_real,
        m_axis_data_tvalid => m_axis_data_tvalid,
        m_axis_data_tdata => m_axis_data_tdata_real);    

    -- IMAGINARY INTERPOLATE BY 4 FIR FILTER
    resamp_int4_dec5_c18_dp16_60dB_imag : resamp_int4_dec5_c18_dp16_60dB
    port map( 
        aresetn => resetn,
        aclk => clk,
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready_imag,
        s_axis_data_tdata => s_axis_data_tdata_imag,
        m_axis_data_tvalid => open,
        m_axis_data_tdata => m_axis_data_tdata_imag);    
    
    -- EXTRACT INTERPOLATE OUTPUTS FROM AXI STREAM 
    generate_filt_int4_data : for a in 0 to (C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        filt_int4_data_real((C_INT_FILT_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_OUTPUT_DATA_WIDTH * a)) <= m_axis_data_tdata_real((C_INT_FILT_OUTPUT_AXI_DATA_WIDTH * a + C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (C_INT_FILT_OUTPUT_AXI_DATA_WIDTH * a));
        filt_int4_data_imag((C_INT_FILT_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_OUTPUT_DATA_WIDTH * a)) <= m_axis_data_tdata_imag((C_INT_FILT_OUTPUT_AXI_DATA_WIDTH * a + C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (C_INT_FILT_OUTPUT_AXI_DATA_WIDTH * a));
    end generate generate_filt_int4_data;     
    
    filt_int4_data_val <= m_axis_data_tvalid;

    -- DEMULTIPLEX THE INDIVIDUAL SAMPLES TO MAKE DECIMATION EASIER
    generate_filt_int4_data_demux : for a in 0 to (C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        filt_int4_data_demux_real(a) <= filt_int4_data_real(((a + 1) * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_OUTPUT_DATA_WIDTH));
        filt_int4_data_demux_imag(a) <= filt_int4_data_imag(((a + 1) * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_OUTPUT_DATA_WIDTH));
    end generate generate_filt_int4_data_demux;

    -- REGISTER TO IMPROVE TIMING
    gen_filt_int4_data_demux_reg : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                filt_int4_data_val_reg <= '0';
                for a in 0 to (C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) loop
                    filt_int4_data_demux_real_reg(a) <= (others => '0');
                    filt_int4_data_demux_imag_reg(a) <= (others => '0');
                end loop;
            else
                filt_int4_data_val_reg <= filt_int4_data_val;
                for a in 0 to (C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) loop
                    filt_int4_data_demux_real_reg(a) <= filt_int4_data_demux_real(a);
                    filt_int4_data_demux_imag_reg(a) <= filt_int4_data_demux_imag(a);
                end loop;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- DECIMATE BY 5
---------------------------------------------------------------------------------------------- 

    filt_int4_dec5_data_val <= filt_int4_data_val_reg;
    
    -- SIMPLY SELECT EVERY 5TH SAMPLE TO DECIMATE BY 5
    generate_filt_int4_dec5_data_demux : for a in 0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        filt_int4_dec5_data_demux_real(a) <= filt_int4_data_demux_real_reg(a * 5);
        filt_int4_dec5_data_demux_imag(a) <= filt_int4_data_demux_imag_reg(a * 5);
    end generate generate_filt_int4_dec5_data_demux;

----------------------------------------------------------------------------------------------
-- PERFORM CONVERGENT ROUNDING ON OUTPUTS OF DECIMATION IN PARALLEL
----------------------------------------------------------------------------------------------
    
    generate_unbiased_convergent_round : for a in 0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate

        -- UNBIASED CONVERGENT ROUND REAL
        unbiased_convergent_round_real : unbiased_convergent_round
        generic map(
            input_width	=> (C_INT_FILT_OUTPUT_DATA_WIDTH - 1), -- NEED THIS ELSE LOSE 6dB
            output_width => 16)
        port map(
            rst => reset,
            clk => clk,							   
            din_en => filt_int4_dec5_data_val,
            din => filt_int4_dec5_data_demux_real(a)((C_INT_FILT_OUTPUT_DATA_WIDTH - 2) downto 0),
            dout_vld => filt_int4_dec5_round_data_val(a),
            dout => filt_int4_dec5_round_data_demux_real(a));    
    
        -- UNBIASED CONVERGENT ROUND IMAGINARY
        unbiased_convergent_round_imag : unbiased_convergent_round
        generic map(
            input_width    => (C_INT_FILT_OUTPUT_DATA_WIDTH - 1), -- NEED THIS ELSE LOSE 6dB
            output_width => 16)
        port map(
            rst => reset,
            clk => clk,                               
            din_en => filt_int4_dec5_data_val,
            din => filt_int4_dec5_data_demux_imag(a)((C_INT_FILT_OUTPUT_DATA_WIDTH - 2) downto 0),
            dout_vld => open,
            dout => filt_int4_dec5_round_data_demux_imag(a));    

    end generate generate_unbiased_convergent_round;   
    
----------------------------------------------------------------------------------------------
-- MULTIPLEX AND COMBINE REAL AND IMAGINARY DATA ONTO OUTPUT BUS
----------------------------------------------------------------------------------------------
        
    gen_resamp_ddc_data : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                resamp_ddc_data_out <= (others => '0');  
                resamp_ddc_data_val_out <= '0';
            else
                resamp_ddc_data_out <= filt_int4_dec5_round_data_demux_imag(3) & filt_int4_dec5_round_data_demux_real(3) & filt_int4_dec5_round_data_demux_imag(2) & filt_int4_dec5_round_data_demux_real(2) & filt_int4_dec5_round_data_demux_imag(1) & filt_int4_dec5_round_data_demux_real(1) & filt_int4_dec5_round_data_demux_imag(0) & filt_int4_dec5_round_data_demux_real(0);
                resamp_ddc_data_val_out <= filt_int4_dec5_round_data_val(0);
            end if;
        end if;
    end process;        
        
------------------------------------------------------------------------------------------------
---- DATA RECORDERS
------------------------------------------------------------------------------------------------    
    
--    -- DDC DATA IN
--    -- MULTIPLEX THE INDIVIDUAL SAMPLES
--    generate_ddc_data : for a in 0 to (C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        ddc_data_real(((a + 1) * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_INPUT_DATA_WIDTH)) <= ddc_data_real_demux(a);
--        ddc_data_imag(((a + 1) * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_INPUT_DATA_WIDTH)) <= ddc_data_imag_demux(a);
--    end generate generate_ddc_data;               
    
--    data_recorder_multi_ddc_data_real : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_INPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "ddc_data_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_data_val_demux,
--        din => ddc_data_real);

--    data_recorder_multi_ddc_data_imag : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_INPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "ddc_data_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_data_val_demux,
--        din => ddc_data_imag);
        
--    -- COMB5 DDC DATA IN 
--    -- MULTIPLEX THE INDIVIDUAL SAMPLES
--    generate_comb5_ddc_data : for a in 0 to (C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        comb5_ddc_data_real(((a + 1) * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_INPUT_DATA_WIDTH)) <= comb5_ddc_data_real_demux(a);
--        comb5_ddc_data_imag(((a + 1) * C_INT_FILT_INPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_INPUT_DATA_WIDTH)) <= comb5_ddc_data_imag_demux(a);
--    end generate generate_comb5_ddc_data;               

--    data_recorder_multi_comb5_ddc_data_real : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_INPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "comb5_ddc_data_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => comb5_ddc_data_val_demux,
--        din => comb5_ddc_data_real);
    
--    data_recorder_multi_comb5_ddc_data_imag : data_recorder_multi
--        generic map(                         
--            data_width => C_INT_FILT_INPUT_DATA_WIDTH,
--            samples_per_clock => C_INT_FILT_COMB_SAMPLES_PER_CLOCK_CYCLE,
--            output_file_name => "comb5_ddc_data_q.txt")
--        port map(
--            rst => reset,
--            clk => clk,
--            dval => comb5_ddc_data_val_demux,
--            din => comb5_ddc_data_imag);
        
--    -- INTERPOLATION FILTER OUTPUT     
--    -- TRUNCATE INTERPOLATION FILTER OUTPUTS TO 32 BITS 
--    generate_filt_int4_data_trunc : for a in 0 to (C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        filt_int4_data_trunc_real((C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * a)) <= filt_int4_data_real((C_INT_FILT_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_OUTPUT_DATA_WIDTH * a + 2));
--        filt_int4_data_trunc_imag((C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * a)) <= filt_int4_data_imag((C_INT_FILT_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_OUTPUT_DATA_WIDTH * a + 2));
--    end generate generate_filt_int4_data_trunc; 
               
--    data_recorder_multi_int4_data_trunc_real : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "filt_int4_trunc_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_data_val,
--        din => filt_int4_data_trunc_real);
        
--    data_recorder_multi_int4_data_trunc_imag : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "filt_int4_trunc_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_data_val,
--        din => filt_int4_data_trunc_imag);

--    -- DECIMATION OUTPUT     
--    -- MULTIPLEX THE INDIVIDUAL SAMPLES AFTER DECIMATION
--    generate_filt_int4_dec5_data : for a in 0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        filt_int4_dec5_data_real(((a + 1) * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_OUTPUT_DATA_WIDTH)) <= filt_int4_dec5_data_demux_real(a);
--        filt_int4_dec5_data_imag(((a + 1) * C_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (a * C_INT_FILT_OUTPUT_DATA_WIDTH)) <= filt_int4_dec5_data_demux_imag(a);
--    end generate generate_filt_int4_dec5_data;    
    
--    -- TRUNCATE DECIMATION OUTPUTS TO 32 BITS 
--    generate_filt_int4_dec5_data_trunc : for a in 0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        filt_int4_dec5_data_trunc_real((C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * a)) <= filt_int4_dec5_data_real((C_INT_FILT_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_OUTPUT_DATA_WIDTH * a + 2));
--        filt_int4_dec5_data_trunc_imag((C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH * a)) <= filt_int4_dec5_data_imag((C_INT_FILT_OUTPUT_DATA_WIDTH * (a + 1) - 1) downto (C_INT_FILT_OUTPUT_DATA_WIDTH * a + 2));
--    end generate generate_filt_int4_dec5_data_trunc; 
               
--    data_recorder_multi_int4_dec5_data_trunc_real : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "filt_int4_dec5_trunc_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_dec5_data_val,
--        din => filt_int4_dec5_data_trunc_real);
        
--    data_recorder_multi_int4_dec5_data_trunc_imag : data_recorder_multi
--    generic map(                         
--        data_width => C_INT_FILT_TRUNC_OUTPUT_DATA_WIDTH,
--        samples_per_clock => C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "filt_int4_dec5_trunc_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_dec5_data_val,
--        din => filt_int4_dec5_data_trunc_imag);

--    -- ROUND OUTPUT     
--    -- MULTIPLEX THE INDIVIDUAL SAMPLES AFTER CONVERGENT ROUNDING
--    generate_filt_int4_dec5_round_data : for a in 0 to (C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        filt_int4_dec5_round_data_real(((a + 1) * 16 - 1) downto (a * 16)) <= filt_int4_dec5_round_data_demux_real(a);
--        filt_int4_dec5_round_data_imag(((a + 1) * 16 - 1) downto (a * 16)) <= filt_int4_dec5_round_data_demux_imag(a);
--    end generate generate_filt_int4_dec5_round_data;    

--    data_recorder_multi_int4_dec5_round_data_trunc_real : data_recorder_multi
--    generic map(                         
--        data_width => 16,
--        samples_per_clock => C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "filt_int4_dec5_round_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_dec5_round_data_val(0),
--        din => filt_int4_dec5_round_data_real);
        
--    data_recorder_multi_int4_dec5_round_data_trunc_imag : data_recorder_multi
--    generic map(                         
--        data_width => 16,
--        samples_per_clock => C_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "filt_int4_dec5_round_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_dec5_round_data_val(0),
--        din => filt_int4_dec5_round_data_imag);
        
end arch_ddc_resamp_int4_dec5;
