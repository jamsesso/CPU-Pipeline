--------------------------------------------------------
-- Simple Microprocessor Design
--
-- Test Bench for Fibonacci Number Generator
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;			   
use ieee.std_logic_unsigned.all;
--use work.MP_lib.all;

entity TB_MP is
end TB_MP;

architecture behv of TB_MP is

component microprocessor is
port( 	cpu_clk:	in std_logic;
		cpu_rst:	in std_logic;
		cpu_output:	out std_logic_vector(15 downto 0)
); 
end component;

signal TB_clk: std_logic;
signal TB_rst: std_logic;
signal TB_output: std_logic_vector(15 downto 0);

begin  			
	
	Unit: microprocessor port map(TB_clk, TB_rst, TB_output);
	
    process
    begin
		TB_clk <= '0';			-- offer clock signal
		wait for 5 ns;			-- in cocurrent process
		TB_clk <= '1';
		wait for 5 ns;
    end process;
	
    process
    begin 
		TB_rst <= '1';
		wait for 50 ns;
		TB_rst <= '0';
		wait for 100000 ns;
	end process;	

end behv;				 