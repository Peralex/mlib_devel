----------------------------------------------------------------------------------
-- Company: Peralex Electronics
-- Engineer: GT
-- 
-- Create Date: 08.05.2023
-- Design Name: 
-- Module Name: adc_resamp_int4_dec5 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Resamples ADC data from 2560MSPS to 2048MSPS.
-- Assumes 10 samples provided in a clock cycle. Interfaces to SKARAB ADC operating
-- at 2560MSPS. 
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

entity adc_resamp_int4_dec5 is
	port (
        clk : in std_logic;
        reset : in std_logic;
        adc_data_in : in std_logic_vector(119 downto 0); -- 10 samples at 12 bits per sample
        adc_data_val_in : in std_logic;
        resamp_adc_data_out : out std_logic_vector(95 downto 0); -- 8 samples at 12 bits per sample
        resamp_adc_data_val_out : out std_logic);
end adc_resamp_int4_dec5;

architecture arch_adc_resamp_int4_dec5 of adc_resamp_int4_dec5 is

    constant C_ADC_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE : integer := 10;
    constant C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE : integer := 40;
    constant C_ADC_INT_FILT_INPUT_DATA_WIDTH : integer := 12;
    constant C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH : integer := 16;
    constant C_ADC_INT_FILT_OUTPUT_AXI_DATA_WIDTH : integer := 32;
    constant C_ADC_INT_FILT_OUTPUT_DATA_WIDTH : integer := 30;
    constant C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE : integer := 8;

    component resamp_int4_dec5_c18_dp12_60dB
    port ( 
        aresetn : in std_logic;
        aclk : in std_logic;
        s_axis_data_tvalid : in std_logic;
        s_axis_data_tready : out std_logic;
        s_axis_data_tdata : in std_logic_vector ((C_ADC_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto 0);
        m_axis_data_tvalid : out std_logic;
        m_axis_data_tdata : out std_logic_vector ((C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_ADC_INT_FILT_OUTPUT_AXI_DATA_WIDTH - 1) downto 0));
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
    signal adc_data_reg : std_logic_vector((C_ADC_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE * C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1) downto 0);
    signal adc_data_val_reg : std_logic;
        
    signal s_axis_data_tvalid : std_logic;
    signal s_axis_data_tready : std_logic;
    signal s_axis_data_tdata : std_logic_vector ((C_ADC_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) downto 0);
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tdata : std_logic_vector ((C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE * C_ADC_INT_FILT_OUTPUT_AXI_DATA_WIDTH - 1) downto 0); 
    
	subtype ST_ADC_FILT_INT4_DATA is std_logic_vector((C_ADC_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    type T_ADC_FILT_INT4_DATA is array(0 to (C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_ADC_FILT_INT4_DATA;       
    signal filt_int4_data_val : std_logic;
    signal filt_int4_data_demux : T_ADC_FILT_INT4_DATA;
    signal filt_int4_data_val_reg : std_logic;
    signal filt_int4_data_demux_reg : T_ADC_FILT_INT4_DATA;

	subtype ST_ADC_FILT_INT4_DEC5_DATA is std_logic_vector((C_ADC_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto 0);
    type T_ADC_FILT_INT4_DEC5_DATA is array(0 to (C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_ADC_FILT_INT4_DEC5_DATA;       
    signal filt_int4_dec5_data_val : std_logic;
    signal filt_int4_dec5_data_demux : T_ADC_FILT_INT4_DEC5_DATA;
    signal filt_int4_dec5_data : std_logic_vector((C_ADC_INT_FILT_OUTPUT_DATA_WIDTH * C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) downto 0);
      
	subtype ST_ADC_FILT_INT4_DEC5_ROUND_DATA is std_logic_vector(11 downto 0);
    type T_ADC_FILT_INT4_DEC5_ROUND_DATA is array(0 to (C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1)) of ST_ADC_FILT_INT4_DEC5_ROUND_DATA;       
    signal filt_int4_dec5_round_data_val : std_logic_vector(0 to (C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1));
    signal filt_int4_dec5_round_data_demux : T_ADC_FILT_INT4_DEC5_ROUND_DATA;

    signal resamp_adc_data : std_logic_vector(95 downto 0);
    signal resamp_adc_data_val : std_logic;
          
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

    gen_adc_data_reg : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                adc_data_reg <= (others => '0');
                adc_data_val_reg <= '0';
            else
                adc_data_reg <= adc_data_in;
                adc_data_val_reg <= adc_data_val_in;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- FIR FILTER PERFORMS INTERPOLATE BY 4 ONLY
----------------------------------------------------------------------------------------------
    
    s_axis_data_tvalid <= adc_data_val_reg and s_axis_data_tready;
    
    -- FORMAT ADC INPUT DATA INTO AXIS AND SIGN EXTEND
    generate_s_axis_data_tdata : for a in 0 to (C_ADC_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        s_axis_data_tdata((a * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH + C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1) downto (a * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH)) <= adc_data_reg(((a + 1) * C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1) downto (a * C_ADC_INT_FILT_INPUT_DATA_WIDTH));        
    
        -- CURRENTLY THERE ARE FOUR BITS IN THE AXIS DATA THAT NEED TO BE POPULATED
        s_axis_data_tdata((a + 1) * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH - 4) <= adc_data_reg((a + 1) * C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1);
        s_axis_data_tdata((a + 1) * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH - 3) <= adc_data_reg((a + 1) * C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1);
        s_axis_data_tdata((a + 1) * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH - 2) <= adc_data_reg((a + 1) * C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1);
        s_axis_data_tdata((a + 1) * C_ADC_INT_FILT_INPUT_AXI_DATA_WIDTH - 1) <= adc_data_reg((a + 1) * C_ADC_INT_FILT_INPUT_DATA_WIDTH - 1);
    end generate generate_s_axis_data_tdata;
    
    -- INTERPOLATE BY 4 FIR FILTER
    resamp_int4_dec5_c18_dp12_60dB_0 : resamp_int4_dec5_c18_dp12_60dB
    port map( 
        aresetn => resetn,
        aclk => clk,
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready,
        s_axis_data_tdata => s_axis_data_tdata,
        m_axis_data_tvalid => m_axis_data_tvalid,
        m_axis_data_tdata => m_axis_data_tdata);
    
    filt_int4_data_val <= m_axis_data_tvalid;

    -- DEMULTIPLEX THE INDIVIDUAL SAMPLES TO MAKE DECIMATION EASIER
    generate_filt_int4_data_demux : for a in 0 to (C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        filt_int4_data_demux(a) <= m_axis_data_tdata((a * C_ADC_INT_FILT_OUTPUT_AXI_DATA_WIDTH + C_ADC_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (a * C_ADC_INT_FILT_OUTPUT_AXI_DATA_WIDTH));
    end generate generate_filt_int4_data_demux;

    -- REGISTER TO IMPROVE TIMING
    gen_filt_int4_data_demux_reg : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                filt_int4_data_val_reg <= '0';
                for a in 0 to (C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) loop
                    filt_int4_data_demux_reg(a) <= (others => '0');
                end loop;
            else
                filt_int4_data_val_reg <= filt_int4_data_val;
                for a in 0 to (C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) loop
                    filt_int4_data_demux_reg(a) <= filt_int4_data_demux(a);
                end loop;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- DECIMATE BY 5
---------------------------------------------------------------------------------------------- 

    filt_int4_dec5_data_val <= filt_int4_data_val_reg;
    
    -- SIMPLY SELECT EVERY 5TH SAMPLE TO DECIMATE BY 5
    generate_filt_int4_dec5_data_demux : for a in 0 to (C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
        filt_int4_dec5_data_demux(a) <= filt_int4_data_demux_reg(a * 5);
    end generate generate_filt_int4_dec5_data_demux;    

----------------------------------------------------------------------------------------------
-- PERFORM CONVERGENT ROUNDING ON OUTPUTS OF DECIMATION IN PARALLEL
----------------------------------------------------------------------------------------------
    
    generate_unbiased_convergent_round : for a in 0 to (C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate

        -- UNBIASED CONVERGENT ROUND
        unbiased_convergent_round_0 : unbiased_convergent_round
        generic map(
            input_width	=> 29, -- UPPER SIGN BIT NOT USED, CONFIRMED LEVELS ON HARDWARE
            output_width => 12)
        port map(
            rst => reset,
            clk => clk,							   
            din_en => filt_int4_dec5_data_val,
            din => filt_int4_dec5_data_demux(a)(28 downto 0),
            dout_vld => filt_int4_dec5_round_data_val(a),
            dout => filt_int4_dec5_round_data_demux(a));    

    end generate generate_unbiased_convergent_round;   
    
----------------------------------------------------------------------------------------------
-- MULTIPLEX ROUND OUTPUT ONTO OUTPUT BUS
----------------------------------------------------------------------------------------------
        
    gen_resamp_ddc_data : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                resamp_adc_data <= (others => '0');  
                resamp_adc_data_val <= '0';
            else
                resamp_adc_data <= filt_int4_dec5_round_data_demux(7) & filt_int4_dec5_round_data_demux(6) & filt_int4_dec5_round_data_demux(5) & filt_int4_dec5_round_data_demux(4) & filt_int4_dec5_round_data_demux(3) & filt_int4_dec5_round_data_demux(2) & filt_int4_dec5_round_data_demux(1) & filt_int4_dec5_round_data_demux(0);
                resamp_adc_data_val <= filt_int4_dec5_round_data_val(0);
            end if;
        end if;
    end process;        
       
    resamp_adc_data_out <= resamp_adc_data;  
    resamp_adc_data_val_out <= resamp_adc_data_val;         
        
------------------------------------------------------------------------------------------------
---- DATA RECORDERS
------------------------------------------------------------------------------------------------    
    
--    -- ADC DATA IN
--    data_recorder_multi_adc_data_in_real : data_recorder_multi
--    generic map(                         
--        data_width => C_ADC_INT_FILT_INPUT_DATA_WIDTH,
--        samples_per_clock => C_ADC_INT_FILT_INPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "adc_data_reg.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => adc_data_val_reg,
--        din => adc_data_reg);
        
--    -- INTERPOLATION FILTER OUTPUT     
--    data_recorder_multi_int4_data_trunc_real : data_recorder_multi
--    generic map(                         
--        data_width => C_ADC_INT_FILT_OUTPUT_AXI_DATA_WIDTH,
--        samples_per_clock => C_ADC_INT_FILT_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "adc_filt_int4_axis.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => m_axis_data_tvalid,
--        din => m_axis_data_tdata);
        
--    -- DECIMATION OUTPUT     
--    -- MULTIPLEX THE INDIVIDUAL SAMPLES AFTER DECIMATION
--    generate_filt_int4_dec5_data : for a in 0 to (C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE - 1) generate
--        filt_int4_dec5_data(((a + 1) * C_ADC_INT_FILT_OUTPUT_DATA_WIDTH - 1) downto (a * C_ADC_INT_FILT_OUTPUT_DATA_WIDTH)) <= filt_int4_dec5_data_demux(a);
--    end generate generate_filt_int4_dec5_data;    
               
--    data_recorder_multi_filt_int4_dec5_data : data_recorder_multi
--    generic map(                         
--        data_width => C_ADC_INT_FILT_OUTPUT_DATA_WIDTH,
--        samples_per_clock => C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "adc_filt_int4_dec5.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => filt_int4_dec5_data_val,
--        din => filt_int4_dec5_data);
        
--    -- ROUND OUTPUT
--    data_recorder_multi_int4_dec5_round_data_trunc_imag : data_recorder_multi
--    generic map(                         
--        data_width => 12,
--        samples_per_clock => C_ADC_INT_FILT_DEC_OUTPUT_SAMPLES_PER_CLOCK_CYCLE,
--        output_file_name => "adc_filt_int4_dec5_round.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => resamp_adc_data_val,
--        din => resamp_adc_data);
        
end arch_adc_resamp_int4_dec5;
