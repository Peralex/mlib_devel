----------------------------------------------------------------------------------
-- Company: Peralex Electronics
-- Engineer: GT
-- 
-- Create Date: 08.05.2023
-- Design Name: 
-- Module Name: ddc_dec16_in_dec32_out - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Performs decimate by 2 on DDC data from SKARAB ADC operating at decimate by 16. 
-- Assumes four samples provided per clock cycle. 
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

entity ddc_dec16_in_dec32_out is
	port (
        clk : in std_logic;
        reset : in std_logic;
        ddc_dec16_data_in : in std_logic_vector(127 downto 0);
        ddc_dec16_data_val_in : in std_logic;
        ddc_dec32_data_out : out std_logic_vector(127 downto 0);
        ddc_dec32_data_val_out : out std_logic);
end ddc_dec16_in_dec32_out;

architecture arch_ddc_dec16_in_dec32_out of ddc_dec16_in_dec32_out is
    
    component ddc_dec16_in_dec32_out_input_fifo
    port ( 
        clk : in std_logic;
        rst : in std_logic;
        din : in std_logic_vector(127 downto 0);
        wr_en : in std_logic;
        rd_en : in std_logic;
        dout : out std_logic_vector(127 downto 0);
        full : out std_logic;
        empty : out std_logic);
    end component;
    
    component resamp_dec2_c18_dp16_90dB
    port ( 
        aresetn : in std_logic;
        aclk : in std_logic;
        s_axis_data_tvalid : in std_logic;
        s_axis_data_tready : out std_logic;
        s_axis_data_tdata : in std_logic_vector(15 downto 0);
        m_axis_data_tvalid : out std_logic;
        m_axis_data_tdata : out std_logic_vector(39 downto 0));
    end component;       
       
    component unbiased_convergent_round
    generic (
        input_width : integer := 18;
        output_width : integer := 16);
    port(
        rst : in std_logic;
        clk : in std_logic;                               
        din_en : in std_logic;
        din : in std_logic_vector((input_width - 1) downto 0);
        dout_vld : out std_logic;
        dout : out std_logic_vector((output_width - 1) downto 0));
    end component;       
   
    component data_recorder
    generic(                         
        data_width : integer;
        output_file_name : string);
    port(
        rst : in std_logic;
        clk : in std_logic;
        dval : in std_logic;
        din : in std_logic_vector((data_width - 1) downto 0));
    end component;
      
    signal resetn : std_logic := '0';
    
    signal ddc_dec16_data_reg : std_logic_vector(127 downto 0);
    signal ddc_dec16_data_val_reg : std_logic;

    signal input_fifo_din : std_logic_vector(127 downto 0);
    signal input_fifo_wrreq : std_logic;
    signal input_fifo_rdreq : std_logic;
    signal input_fifo_dout : std_logic_vector(127 downto 0);
    signal input_fifo_full : std_logic;
    signal input_fifo_empty : std_logic;
    signal input_retime_count : integer range 0 to 3;
    signal input_fifo_rdreq_z : std_logic;
    signal input_fifo_rdreq_z2 : std_logic;
    signal input_fifo_rdreq_z3 : std_logic;
    signal input_fifo_rdreq_z4 : std_logic;

    signal ddc_dec16_data_serial : std_logic_vector(31 downto 0);
    signal ddc_dec16_data_val_serial : std_logic;
    signal ddc_dec16_data_serial_reg : std_logic_vector(31 downto 0);
    signal ddc_dec16_data_val_serial_reg : std_logic;

    signal s_axis_data_tvalid : std_logic;
    signal s_axis_data_tready_real : std_logic;
    signal s_axis_data_tready_imag : std_logic;
    signal s_axis_data_tdata_real : std_logic_vector(15 downto 0);
    signal s_axis_data_tdata_imag : std_logic_vector(15 downto 0);
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tdata_real : std_logic_vector(39 downto 0);
    signal m_axis_data_tdata_imag : std_logic_vector(39 downto 0);
    
    signal ddc_dec32_data_real : std_logic_vector(34 downto 0);
    signal ddc_dec32_data_imag : std_logic_vector(34 downto 0);
    signal ddc_dec_32_data_val : std_logic;
    signal ddc_dec32_data_real_trunc : std_logic_vector(31 downto 0);
    signal ddc_dec32_data_imag_trunc : std_logic_vector(31 downto 0);

    signal ddc_dec32_data_round_real : std_logic_vector(15 downto 0);
    signal ddc_dec32_data_round_imag : std_logic_vector(15 downto 0);
    signal ddc_dec_32_data_round_val : std_logic;
    
    signal ddc_dec32_data_out_count : integer range 0 to 3;
    signal ddc_dec32_data_out_i : std_logic_vector(127 downto 0);
    signal ddc_dec32_data_val_out_i : std_logic;    
  
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

    gen_ddc_dec16_data_reg : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                ddc_dec16_data_reg <= (others => '0');
                ddc_dec16_data_val_reg <= '0';
            else
                if (ddc_dec16_data_val_in = '1')then
                    ddc_dec16_data_reg <= ddc_dec16_data_in;
                end if;
                ddc_dec16_data_val_reg <= ddc_dec16_data_val_in;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- BUFFER INPUT TO HANDLE BURST DATA
----------------------------------------------------------------------------------------------

    input_fifo_din <= ddc_dec16_data_reg;
    input_fifo_wrreq <= ddc_dec16_data_val_reg and (not input_fifo_full);

    ddc_dec16_in_dec32_out_input_fifo_0 : ddc_dec16_in_dec32_out_input_fifo
    port map( 
        clk => clk,
        rst => reset,
        din => input_fifo_din,
        wr_en => input_fifo_wrreq,
        rd_en => input_fifo_rdreq,
        dout => input_fifo_dout,
        full => input_fifo_full,
        empty => input_fifo_empty);    
     
    input_fifo_rdreq <= '1' when ((input_fifo_empty = '0')and(input_retime_count = 3)) else '0';     
     
    gen_input_retime_count : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                input_retime_count <= 0;
            else
                if (input_retime_count = 3)then
                    input_retime_count <= 0;
                else
                   input_retime_count <= input_retime_count + 1;
                end if;
            end if;
        end if;
    end process;        
  
    gen_input_fifo_rdreq_z : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                input_fifo_rdreq_z <= '0';
                input_fifo_rdreq_z2 <= '0';
                input_fifo_rdreq_z3 <= '0';
                input_fifo_rdreq_z4 <= '0';            
            else
                input_fifo_rdreq_z <= input_fifo_rdreq;
                input_fifo_rdreq_z2 <= input_fifo_rdreq_z;
                input_fifo_rdreq_z3 <= input_fifo_rdreq_z2;
                input_fifo_rdreq_z4 <= input_fifo_rdreq_z3;            
            end if;
        end if;
    end process;            

----------------------------------------------------------------------------------------------
-- CONVERT TO SINGLE SAMPLE PER CLOCK CYCLE
----------------------------------------------------------------------------------------------

    ddc_dec16_data_val_serial <= input_fifo_rdreq_z or input_fifo_rdreq_z2 or input_fifo_rdreq_z3 or input_fifo_rdreq_z4;
    
    ddc_dec16_data_serial <=
    input_fifo_dout(31 downto 0) when (input_fifo_rdreq_z = '1') else
    input_fifo_dout(63 downto 32) when (input_fifo_rdreq_z2 = '1') else
    input_fifo_dout(95 downto 64) when (input_fifo_rdreq_z3 = '1') else
    input_fifo_dout(127 downto 96);

    -- REGISTER
    gen_ddc_dec16_data_val_serial_reg : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                ddc_dec16_data_serial_reg <= (others => '0');
                ddc_dec16_data_val_serial_reg <= '0';
            else
                ddc_dec16_data_serial_reg <= ddc_dec16_data_serial;
                ddc_dec16_data_val_serial_reg <= ddc_dec16_data_val_serial;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- DECIMATE BY 2 FIR FILTER
----------------------------------------------------------------------------------------------

    s_axis_data_tvalid <= ddc_dec16_data_val_serial_reg and s_axis_data_tready_real and s_axis_data_tready_imag;
    
    s_axis_data_tdata_real <= ddc_dec16_data_serial_reg(15 downto 0);
    s_axis_data_tdata_imag <= ddc_dec16_data_serial_reg(31 downto 16);

    -- REAL FIR FILTER
    resamp_dec2_c18_dp16_90dB_real : resamp_dec2_c18_dp16_90dB
    port map( 
        aresetn => resetn,
        aclk => clk,
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready_real,
        s_axis_data_tdata => s_axis_data_tdata_real,
        m_axis_data_tvalid => m_axis_data_tvalid,
        m_axis_data_tdata => m_axis_data_tdata_real);

    -- REAL FIR FILTER
    resamp_dec2_c18_dp16_90dB_imag : resamp_dec2_c18_dp16_90dB
    port map( 
        aresetn => resetn,
        aclk => clk,
        s_axis_data_tvalid => s_axis_data_tvalid,
        s_axis_data_tready => s_axis_data_tready_imag,
        s_axis_data_tdata => s_axis_data_tdata_imag,
        m_axis_data_tvalid => open,
        m_axis_data_tdata => m_axis_data_tdata_imag);

    ddc_dec_32_data_val <= m_axis_data_tvalid;

    ddc_dec32_data_real <= m_axis_data_tdata_real(34 downto 0);
    ddc_dec32_data_imag <= m_axis_data_tdata_imag(34 downto 0);
    ddc_dec32_data_real_trunc <= ddc_dec32_data_real(34 downto 3);
    ddc_dec32_data_imag_trunc <= ddc_dec32_data_imag(34 downto 3);

----------------------------------------------------------------------------------------------
-- CONVERGENT ROUNDING
----------------------------------------------------------------------------------------------

    unbiased_convergent_round_real : unbiased_convergent_round
    generic map(
        input_width => 34,
        output_width => 16)
    port map(
        rst => reset,
        clk => clk,                               
        din_en => ddc_dec_32_data_val,
        din => ddc_dec32_data_real(33 downto 0),
        dout_vld => ddc_dec_32_data_round_val,
        dout => ddc_dec32_data_round_real);

    unbiased_convergent_round_imag : unbiased_convergent_round
    generic map(
        input_width => 34,
        output_width => 16)
    port map(
        rst => reset,
        clk => clk,                               
        din_en => ddc_dec_32_data_val,
        din => ddc_dec32_data_imag(33 downto 0),
        dout_vld => open,
        dout => ddc_dec32_data_round_imag);

----------------------------------------------------------------------------------------------
-- COMBINE INTO 4 SAMPLES PER CLOCK CYCLE AGAIN TO MATCH INPUT
----------------------------------------------------------------------------------------------

    gen_ddc_dec32_data_out_count : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                ddc_dec32_data_out_count <= 0;
                ddc_dec32_data_out_i <= (others => '0');
                ddc_dec32_data_val_out_i <= '0';
            else
                ddc_dec32_data_val_out_i <= '0';

                if (ddc_dec_32_data_round_val = '1')then
                    if (ddc_dec32_data_out_count = 0)then
                        ddc_dec32_data_out_count <= 1;
                        ddc_dec32_data_out_i(31 downto 0) <= ddc_dec32_data_round_imag & ddc_dec32_data_round_real;
                    elsif (ddc_dec32_data_out_count = 1)then
                        ddc_dec32_data_out_count <= 2;
                        ddc_dec32_data_out_i(63 downto 32) <= ddc_dec32_data_round_imag & ddc_dec32_data_round_real;
                    elsif (ddc_dec32_data_out_count = 2)then
                        ddc_dec32_data_out_count <= 3;
                        ddc_dec32_data_out_i(95 downto 64) <= ddc_dec32_data_round_imag & ddc_dec32_data_round_real;
                    else
                        ddc_dec32_data_out_count <= 0;
                        ddc_dec32_data_out_i(127 downto 96) <= ddc_dec32_data_round_imag & ddc_dec32_data_round_real;
                        ddc_dec32_data_val_out_i <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- REGISTER OUTPUTS
----------------------------------------------------------------------------------------------

    gen_ddc_dec32_data_out : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                ddc_dec32_data_out <= (others => '0');
                ddc_dec32_data_val_out <= '0';            
            else
                ddc_dec32_data_out <= ddc_dec32_data_out_i;
                ddc_dec32_data_val_out <= ddc_dec32_data_val_out_i;            
            end if;
        end if;
    end process;

------------------------------------------------------------------------------------------------
---- DATA RECORDERS
------------------------------------------------------------------------------------------------    
    
--    -- DDC DEC16 DATA IN
--    data_recorder_ddc_dec16_data_serial_real : data_recorder
--    generic map(                         
--        data_width => 16,
--        output_file_name => "ddc_dec16_data_serial_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_dec16_data_val_serial_reg,
--        din => ddc_dec16_data_serial_reg(15 downto 0));     

--    data_recorder_ddc_dec16_data_serial_imag : data_recorder
--    generic map(                         
--        data_width => 16,
--        output_file_name => "ddc_dec16_data_serial_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_dec16_data_val_serial_reg,
--        din => ddc_dec16_data_serial_reg(31 downto 16));     

--    -- DDC DEC32 DATA
--    data_recorder_ddc_dec32_data_trunc_real : data_recorder
--    generic map(                         
--        data_width => 32,
--        output_file_name => "ddc_dec32_data_trunc_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_dec_32_data_val,
--        din => ddc_dec32_data_real_trunc);     

--    data_recorder_ddc_dec32_data_trunc_imag : data_recorder
--    generic map(                         
--        data_width => 32,
--        output_file_name => "ddc_dec32_data_trunc_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_dec_32_data_val,
--        din => ddc_dec32_data_imag_trunc);     

--    -- DDC DEC32 DATA AFTER ROUNDING
--    data_recorder_ddc_dec32_data_round_real : data_recorder
--    generic map(                         
--        data_width => 16,
--        output_file_name => "ddc_dec32_data_round_i.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_dec_32_data_round_val,
--        din => ddc_dec32_data_round_real);     

--    data_recorder_ddc_dec32_data_round_imag : data_recorder
--    generic map(                         
--        data_width => 16,
--        output_file_name => "ddc_dec32_data_round_q.txt")
--    port map(
--        rst => reset,
--        clk => clk,
--        dval => ddc_dec_32_data_round_val,
--        din => ddc_dec32_data_round_imag);        
        
end arch_ddc_dec16_in_dec32_out;
