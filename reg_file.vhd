-------------------------------------------------------------
-- Simple Microprocessor Design (ESD Book Chapter 3) 
-- Copyright 2001 Weijun Zhang
--
-- Register Files (16*16) of datapath compsed of
-- 4-bit address bus; 16-bit data bus
-- reg_file.vhd
-------------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;			   
use ieee.std_logic_unsigned.all;   
use work.MP_lib.all;

entity reg_file is
port ( 	clock	: 	in std_logic; 	
	rst	: 	in std_logic;
	RFwe	: 	in std_logic; -- Register file write enable
	RFr1e	: 	in std_logic; -- Register file port 1 read enable
	RFr2e	: 	in std_logic; -- Register file port 2 read enable
	RFwa	: 	in std_logic_vector(3 downto 0); -- Register to write to
	RFr1a	: 	in std_logic_vector(3 downto 0); -- Register to read on port 1
	RFr2a	: 	in std_logic_vector(3 downto 0); -- Register to read on port 2
	RFw		: 	in std_logic_vector(15 downto 0); -- Data to write to register
	RFr1	: 	out std_logic_vector(15 downto 0); -- Data read from register on port 1
	RFr2	:	out std_logic_vector(15 downto 0)  -- Data read from register on port 2
);
end reg_file;

architecture behv of reg_file is			

  type rf_type is array (0 to 15) of 
        std_logic_vector(15 downto 0);
  signal tmp_rf: rf_type;

begin
  write12: process(clock, rst, RFwa, RFwe, RFw)
  begin
    if rst='1' then				-- high active
        tmp_rf <= (tmp_rf'range => ZERO);
    else
	if rising_edge(clock) then
	  if RFwe='1' then
	    tmp_rf(conv_integer(RFwa)) <= RFw;
	  end if;
	end if;
    end if;
  end process;						   
  read1: process(clock, rst, RFr1e, RFr1a)
  begin
    if rst='1' then
	RFr1 <= ZERO;
    else
	if rising_edge(clock) then
	  if RFr1e='1' then	
	    RFr1 <= tmp_rf(conv_integer(RFr1a));
	  end if;
	end if;
    end if;
  end process;
  read2: process(clock, rst, RFr2e, RFr2a)
  begin
    if rst='1' then
	RFr2<= ZERO;
    else
	if rising_edge(clock) then
	  if RFr2e='1' then								 
	    RFr2 <= tmp_rf(conv_integer(RFr2a));
	  end if;
	end if;
    end if;
  end process;
end behv;











