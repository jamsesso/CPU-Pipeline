library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;			   
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

entity TB_MP is
	port(
		clock 		: in std_logic;
		reset 		: in std_logic;
		pipeline 	: in std_logic;
		display0	: out std_logic_vector(0 to 6);
		display1	: out std_logic_vector(0 to 6);
		display2	: out std_logic_vector(0 to 6);
		display3	: out std_logic_vector(0 to 6);
	);
end TB_MP;

architecture behv of TB_MP is
	signal cpu_output : std_logic_vector(15 downto 0);
	signal performance_counter : std_logic_vector(15 downto 0);
begin
	-- Set up the processor.
	Processor: microprocessor port map(clock, reset, output, performance_counter);
	
	-- Display performance counter. The bus is 16 bits so we need 4 hex displays.
	HexDisp3: SevenSegment port map(performance_counter(15 downto 12), display3);
	HexDisp2: SevenSegment port map(performance_counter(11 downto 8), display2);
	HexDisp1: SevenSegment port map(performance_counter(7 downto 4), display1);
	HexDisp0: SevenSegment port map(performance_counter(3 downto 0), display0);
end behv;				 