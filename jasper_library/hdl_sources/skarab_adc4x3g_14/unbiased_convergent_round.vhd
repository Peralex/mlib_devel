-------------------------------------------------------------------------------
--
-- Title       : unbiased_convergent_round
-- Design      : uwb_ddc
-- Author      : Clifford van Dyk
-- Company     : Peralex
--
-------------------------------------------------------------------------------
--
-- File        : unbiased_convergent_round.vhd
-- Generated   : Tue Jan 24 16:43:12 2006
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.20
--
-------------------------------------------------------------------------------
--
-- Description : 
-- Unbiased convergent rounding is implemented by adding a rounding constant 
-- of approximately 0.5 * the LSB of the output word to the input, and then
-- truncating the input word to the output word length. The rounding constant
-- is actually computed on a sample by sample basis by adding either 0 or 1 LSB 
-- to a value that is 0.5-1 LSB, with a probability of 0.5.	 
--
-- The LSB of the output word is used to decide whether to add 0 or 1 LSB to
-- create the rounding constant. This bit is assumed to be statistically
-- uncorellated to the lower bits.
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {unbiased_convergent_round} architecture {arch_unbiased_convergent_round_rtl}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;  
use ieee.numeric_std.all;

entity unbiased_convergent_round is
	generic (
	 			input_width	: integer := 18;
	 			output_width : integer := 16
			);
	 port(
		 rst : in STD_LOGIC;
		 clk : in STD_LOGIC;							   
		 din_en : in STD_LOGIC;
		 din : in STD_LOGIC_VECTOR(input_width-1 downto 0);
		 dout_vld : out STD_LOGIC;
		 dout : out STD_LOGIC_VECTOR(output_width-1 downto 0)
	     );
end unbiased_convergent_round;

--}} End of automatically maintained section

architecture arch_unbiased_convergent_round_rtl of unbiased_convergent_round is

signal rounding_constant_lower_bits : std_logic_vector(input_width-output_width-2 downto 0);
signal rounding_constant_upper_bits : std_logic_vector(output_width downto 0);
signal rounding_constant_without_lsb : std_logic_vector(input_width-1 downto 0);

signal rounding_constant_lsb_upper_bits : std_logic_vector(input_width-2 downto 0);
signal rounding_constant_lsb_lower_bit : std_logic;
signal rounding_constant_lsb : std_logic_vector(input_width-1 downto 0); 

signal rounding_constant : std_logic_vector(input_width-1 downto 0);

signal input_plus_rounding_constant : std_logic_vector(input_width-1 downto 0);

begin															  
	
-- Construct rounding constant (excluding LSB)
rounding_constant_upper_bits <= (others=>'0');
rounding_constant_lower_bits <= (others=>'1');
rounding_constant_without_lsb <= rounding_constant_upper_bits & rounding_constant_lower_bits;

-- Construct rounding constant LSB		   
rounding_constant_lsb_lower_bit <= din(input_width-output_width);
rounding_constant_lsb_upper_bits <= (others => '0');
rounding_constant_lsb <= rounding_constant_lsb_upper_bits & rounding_constant_lsb_lower_bit;

-- Construct rounding constant
rounding_constant <= std_logic_vector(signed(rounding_constant_without_lsb)+signed(rounding_constant_lsb));

process (clk)
begin
	if rising_edge(clk) then
        if rst = '1' then								  
            dout_vld <= '0';
            input_plus_rounding_constant <= (others=>'0');
        else	   
            -- Output is delayed one clock cycle from input
            dout_vld <= din_en;
            
            -- Add rounding constant prior to truncation
            if din_en = '1' then
                input_plus_rounding_constant <= std_logic_vector(signed(din)+signed(rounding_constant));
            end if;
		end if;
	end if;
end process;

dout <= input_plus_rounding_constant(input_width-1 downto input_width-output_width);

end arch_unbiased_convergent_round_rtl;
