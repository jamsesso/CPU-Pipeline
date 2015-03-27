--------------------------------------------------------
-- Simple Microprocessor Design
--
-- memory 256*16
-- 8 bit address; 16 bit data
-- memory.vhd
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;   
use work.MP_lib.all;

entity memory is
port ( 	clock	: 	in std_logic;
		rst		: 	in std_logic;
		Mre		:	in std_logic;
		Mre2    :   in std_logic;
		Mwe		:	in std_logic;
		address	:	in std_logic_vector(7 downto 0);
		address2  :	in std_logic_vector(7 downto 0);
		data_in	  :	in std_logic_vector(15 downto 0); -- Fetch stage never needs to write data so we don't need another datain bus.
		data_out  :	out std_logic_vector(15 downto 0);
		data_out2 : out std_logic_vector(15 downto 0)
);
end memory;

architecture behv of memory	 is			

type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
signal tmp_ram: ram_type;
begin
	write: process(clock, rst, Mre, address, data_in)
	begin
		if rst='1' then
			tmp_ram <= (	-- 5x5 matricies with solution:
				-- A = (M[100] - [124]),  B = (M[125] - [149]),  C = (M[150 - 174])
				-- A = [1 2 3 4 5]		  B = [0 1 2 3 4]        C = [1 3 5 7 9]
				   --  [6 7 8 9 0]	    	  [0 0 0 0 8]            [6 7 8 9 8]
				   --  [1 2 3 4 5]	    	  [8 7 6 5 4]            [9 9 9 9 9]
				   --  [6 7 8 9 0]      	  [3 1 0 0 4]            [9 8 8 9 4]
				   --  [1 2 3 4 5]	    	  [0 0 0 0 0]            [1 2 3 4 5]

				-- Copy the starting array addresses.
				 0 => x"3164",	-- R1 = 100, M(A[x][x])
				 1 => x"327D",	-- R2 = 125, M(B[x][x])
				 2 => x"3396",	-- R3 = 150, M(C[x][x])

				-- Compute the matrix addition.
				 3 => x"B140",	-- R4 = M[A[x][x]]
				 4 => x"B250",	-- R5 = M[B[x][x]]
				 5 => x"4456",	-- R6 = (R4 + R5)
				 6 => x"2360",	-- M[R3] = R6

				-- Increment addresses.
				 7 => x"9100",  -- R1++
				 8 => x"9200",  -- R2++
				 9 => x"9300",  -- R3++

				-- Loop until M[124] is no longer zero.
				10 => x"07AE",	-- R7 = M[174]
				11 => x"6703", 	-- R7 = 0 : PC<- #48

				-- Output Martix C.
				12 => x"7096",	-- output <- M[150]
				13 => x"7097",	-- output <- M[151] 
				14 => x"7098",	-- output <- M[152] 
				15 => x"7099",	-- output <- M[153]
				16 => x"709A",	-- output <- M[154]
				17 => x"709B",	-- output <- M[155]
				18 => x"709C",	-- output <- M[156]
				19 => x"709D",	-- output <- M[157]
				20 => x"709E",	-- output <- M[158] 
				21 => x"709F",	-- output <- M[159] 
				22 => x"70A0",	-- output <- M[160]
				23 => x"70A1",	-- output <- M[161]
				24 => x"70A2",	-- output <- M[162]
				25 => x"70A3",	-- output <- M[163]
				26 => x"70A4",	-- output <- M[164]
				27 => x"70A5",	-- output <- M[165] 
				28 => x"70A6",	-- output <- M[166] 
				29 => x"70A7",	-- output <- M[167]
				30 => x"70A8",	-- output <- M[168]
				31 => x"70A9",	-- output <- M[169]
				32 => x"70AA",	-- output <- M[170]
				33 => x"70AB",	-- output <- M[171]
				34 => x"70AC",	-- output <- M[172] 
				35 => x"70AD",	-- output <- M[173] 
				36 => x"70AE",	-- output <- M[174]	
				37 => x"F000",	-- HALT
				
				-- Matrix A
				100 => x"0001",
				101 => x"0002",
				102 => x"0003",
				103 => x"0004",
				104 => x"0005",
				105 => x"0006",
				106 => x"0007",
				107 => x"0008",
				108 => x"0009",
				109 => x"0000",
				110 => x"0001",
				111 => x"0002",
				112 => x"0003",
				113 => x"0004",
				114 => x"0005",
				115 => x"0006",
				116 => x"0007",
				117 => x"0008",
				118 => x"0009",
				119 => x"0000",
				120 => x"0001",
				121 => x"0002",
				122 => x"0003",
				123 => x"0004",
				124 => x"0005",
				
				-- Matrix B
				125 => x"0000",
				126 => x"0001",
				127 => x"0002",
				128 => x"0003",
				129 => x"0004",
				130 => x"0000",
				131 => x"0000",
				132 => x"0000",
				133 => x"0000",
				134 => x"0008",
				135 => x"0008",
				136 => x"0007",
				137 => x"0006",
				138 => x"0005",
				139 => x"0004",
				140 => x"0003",
				141 => x"0001",
				142 => x"0000",
				143 => x"0000",
				144 => x"0004",
				145 => x"0000",
				146 => x"0000",
				147 => x"0000",
				148 => x"0000",
				149 => x"0000",
			others => x"0000");
		else
			if (clock'event and clock = '1') then
				if (Mwe ='1' and Mre = '0') then
					tmp_ram(conv_integer(address)) <= data_in;
				end if;
			end if;
		end if;
	end process;

    read1: process(clock, rst, Mwe, address)
	begin
		if rst='1' then
			data_out <= ZERO;
		else
			if (clock'event and clock = '1') then
				if (Mre ='1' and Mwe ='0') then								 
					data_out <= tmp_ram(conv_integer(address));
				end if;
			end if;
		end if;
	end process;
	
	-- Fetch instruction can read from memory concurrently!!!!
	read2: process(clock, rst, Mre2, address2)
	begin
		if rst = '1' then
			data_out2 <= ZERO;
		elsif rising_edge(clock) and Mre2 = '1' then
			data_out2 <= tmp_ram(conv_integer(address2));
		end if;
	end process;
end behv;