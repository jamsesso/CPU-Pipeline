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
		Mwe		:	in std_logic;
		address	:	in std_logic_vector(7 downto 0);
		data_in	:	in std_logic_vector(15 downto 0);
		data_out:	out std_logic_vector(15 downto 0)
);
end memory;

architecture behv of memory	 is			

type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
signal tmp_ram: ram_type;
begin
	write: process(clock, rst, Mre, address, data_in)
	begin
		if rst='1' then
			-- test increments and decrement instructions
			tmp_ram <= (
				0 => "0011000100001111", -- R1 <- 0x0F       (R1 is a pointer to the address 0x0F)
				1 => "0011001000110011", -- R2 <- 0x33       (R2 holds a test value)
				2 => "0001001000001111", -- MEM[0x0F] <- R2  (Write R2 to memory)
				3 => "1011000100110000", -- R3 <- MEM[R1]    (Use pointer to read value into R3)
				4 => "0001001100010000", -- MEM[0x10] <- R3  (Save R3 into next address, 0x10)
				5 => "0111000000010000", -- OUTPUT MEM[0x10] (should be 33)
				6 => "1111000000000000",
				others => "0000000000000000"
			);
			
			-- generate first 7 factorials
--			tmp_ram <= (
--				0  => x"3000", -- MOV4 R0, 0x00
--				1  => x"3150", -- MOV4 R1, 0x50
--				2  => x"3201", -- MOV4 R2, 0x01
--				3  => x"3300", -- MOV4 R3, 0x00
--				4  => x"3401", -- MOV4 R4, 0x01
--				5  => x"214F", -- MOV3 R1, R4
--				6  => x"4045", -- ADD R0, R4, R5
--				7  => x"4323", -- ADD R3, R2, R3
--				8  => x"8354", -- MULT R3, R5, R4
--				9  => x"4121", -- ADD R1, R2, R1
--				10 => x"0656", -- MOV1 R6, 0x56
--				11 => x"6605", -- JZ R6, 0x05
--				12 => x"7050", -- OUT 0x50
--				13 => x"7051", -- OUT 0x51
--				14 => x"7052", -- OUT 0x52
--				15 => x"7053", -- OUT 0x53
--				16 => x"7054", -- OUT 0x54
--				17 => x"7055", -- OUT 0x55
--				18 => x"7056", -- OUT 0x56
--				19 => x"F000", -- HALT
--				others => x"0000"
--			);
		else
			if (clock'event and clock = '1') then
				if (Mwe ='1' and Mre = '0') then
					tmp_ram(conv_integer(address)) <= data_in;
				end if;
			end if;
		end if;
	end process;

    read: process(clock, rst, Mwe, address)
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
end behv;