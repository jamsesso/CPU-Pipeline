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

				-- Populate Marticies A and B.
				 0 => x"C000",  -- Start performance counter.
				 1 => x"3001",	-- R0 = 1
			 	 2 => x"1064",	-- M[100] <- R0, A[0][0]
				 3 => x"106E",	-- M[110] <- R0, A[2][0]
				 4 => x"1078",	-- M[120] <- R0, A[4][0]
				 5 => x"107E",	-- M[126] <- R0, B[0][1]
				 6 => X"108D",  -- M[141] <- R0, B[3][1]
				 7 => x"9000",  -- R0++, R0 = 2
				 8 => x"1065",	-- M[101] <- R0, A[0][1]
				 9 => x"106F",	-- M[111] <- R0, A[2][1]
				10 => x"1079",	-- M[121] <- R0, A[4][1]
				11 => x"107F",	-- M[127] <- R0, B[0][2]
				12 => x"9000",  -- R0++, R0 = 3		
				13 => x"1066",	-- M[102] <- R0, A[0][2]
				14 => x"1070",	-- M[112] <- R0, A[2][2]
				15 => x"107A",	-- M[122] <- R0, A[4][2]
				16 => x"1080",	-- M[128] <- R0, B[0][3]
				17 => x"108C",  -- M[140] <- R0, B[3][0]
				18 => x"9000",  -- R0++, R0 = 4
				19 => x"1067",	-- M[103] <- R0, A[0][3]
				20 => x"1071",	-- M[113] <- R0, A[2][3]
				21 => x"107B",	-- M[123] <- R0, A[4][3]
				22 => x"1081",	-- M[129] <- R0, B[0][4]
				23 => x"108B",  -- M[139] <- R0, B[2][4]
				24 => x"1090",  -- M[144] <- R0, B[3][4]
				25 => x"9000",  -- R0++, R0 = 5
				26 => x"1068",	-- M[104] <- R0, A[0][4]
				27 => x"1072",	-- M[114] <- R0, A[2][4]
				28 => x"107C",	-- M[124] <- R0, A[4][4]
				29 => x"108A",	-- M[138] <- R0, B[2][3]
				30 => x"9000",  -- R0++, R0 = 6
				31 => x"1069",	-- M[105] <- R0, A[1][0]
				32 => x"1073",	-- M[115] <- R0, A[3][0]
				33 => x"1089",	-- M[137] <- R0, B[2][2]
				34 => x"9000",  -- R0++, R0 = 7
				35 => x"106A",	-- M[106] <- R0, A[1][1]
				36 => x"1074",	-- M[116] <- R0, A[3][1]
				37 => x"1088",	-- M[136] <- R0, B[2][1]
				38 => x"9000",  -- R0++, R0 = 8
				39 => x"106B",	-- M[107] <- R0, A[1][2]
				40 => x"1075",	-- M[117] <- R0, A[3][2]
				41 => x"1086",	-- M[134] <- R0, B[1][4]
				42 => x"1087",	-- M[135] <- R0, B[2][0]
				43 => x"9000",  -- R0++, R0 = 9
				44 => x"106C",	-- M[108] <- R0, A[1][3]
				45 => x"1076",	-- M[118] <- R0, A[3][3]

				-- Copy the starting array addresses.
				46 => x"3164",	-- R1 = 100, M(A[x][x])
				47 => x"327D",	-- R2 = 125, M(B[x][x])
				48 => x"3396",	-- R3 = 150, M(C[x][x])

				-- Compute the matrix addition.
				49 => x"B140",	-- R4 = M[A[x][x]]
				50 => x"B250",	-- R5 = M[B[x][x]]
				51 => x"4456",	-- R6 = (R4 + R5)
				52 => x"2360",	-- M[R3] = R6

				-- Increment addresses.
				53 => x"9100",  -- R1++
				54 => x"9200",  -- R2++
				55 => x"9300",  -- R3++

				-- Loop until M[124] is no longer zero.
				56 => x"07AE",	-- R7 = M[174]
				57 => x"6730", 	-- R7 = 0 : PC<- #48

				-- Output Martix C.
				58 => x"7096",	-- output <- M[150]
				59 => x"7097",	-- output <- M[151] 
				60 => x"7098",	-- output <- M[152] 
				61 => x"7099",	-- output <- M[153]
				62 => x"709A",	-- output <- M[154]
				63 => x"709B",	-- output <- M[155]
				64 => x"709C",	-- output <- M[156]
				65 => x"709D",	-- output <- M[157]
				66 => x"709E",	-- output <- M[158] 
				67 => x"709F",	-- output <- M[159] 
				68 => x"70A0",	-- output <- M[160]
				69 => x"70A1",	-- output <- M[161]
				70 => x"70A2",	-- output <- M[162]
				71 => x"70A3",	-- output <- M[163]
				72 => x"70A4",	-- output <- M[164]
				73 => x"70A5",	-- output <- M[165] 
				74 => x"70A6",	-- output <- M[166] 
				75 => x"70A7",	-- output <- M[167]
				76 => x"70A8",	-- output <- M[168]
				77 => x"70A9",	-- output <- M[169]
				78 => x"70AA",	-- output <- M[170]
				79 => x"70AB",	-- output <- M[171]
				80 => x"70AC",	-- output <- M[172] 
				81 => x"70AD",	-- output <- M[173] 
				82 => x"70AE",	-- output <- M[174]	
				83 => x"D000",  -- Stop performance counter.
				84 => x"F000",	-- HALT
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