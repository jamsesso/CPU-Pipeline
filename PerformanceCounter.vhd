library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

entity PerformanceCounter is
	port(
		clock 	: in std_logic;
		enable	: in std_logic;
		clear	: in std_logic;
		count 	: out std_logic_vector(15 downto 0)
	);
end entity;

architecture Behaviour of PerformanceCounter is
	signal tmp_counter : std_logic_vector(15 downto 0) := x"0000";
begin
	BenchmarkPerformance: process(clock, clear, enable) begin
		if clear = '1' then
			tmp_counter <= x"0000";
		elsif rising_edge(clock) and enable = '1' then
			tmp_counter <= tmp_counter + 1;
		end if;
	end process;
	
	count <= tmp_counter;
end architecture;