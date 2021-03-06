----------------------------------------------------------------
-- Simple Microprocessor Design (ESD Book Chapter 3)
-- Copyright 2001 Weijun Zhang
--
-- DATAPATH composed of Multiplexor, Register File and ALU
-- VHDL structural modeling
-- datapath.vhd
----------------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;			   
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

entity datapath is				
port(	clock_dp:	in 	std_logic;
	rst_dp:		in 	std_logic;
	imm_data:	in 	std_logic_vector(15 downto 0);
	mem_data: 	in 	std_logic_vector(15 downto 0);
	RFs_dp:		in 	std_logic_vector(1 downto 0);
	RFwa_dp:	in 	std_logic_vector(3 downto 0);
	RFr1a_dp:	in 	std_logic_vector(3 downto 0);
	RFr2a_dp:	in 	std_logic_vector(3 downto 0);
	RFwe_dp:	in 	std_logic;
	RFr1e_dp:	in 	std_logic;
	RFr2e_dp:	in 	std_logic;
	jp_en:		in 	std_logic;
	ALUs_dp:	in 	std_logic_vector(2 downto 0);
	oe_dp:		in 	std_logic;
	ALUz_dp:	out 	std_logic;
	RF1out_dp:	out 	std_logic_vector(15 downto 0);
	ALUout_dp:	out 	std_logic_vector(15 downto 0);
	bufout_dp:	out 	std_logic_vector(15 downto 0);
	Register0 : out std_logic_vector(15 downto 0);
	Register1 : out std_logic_vector(15 downto 0);
	Register2 : out std_logic_vector(15 downto 0);
	Register3 : out std_logic_vector(15 downto 0);
	Register4 : out std_logic_vector(15 downto 0);
	Register5 : out std_logic_vector(15 downto 0);
	Register6 : out std_logic_vector(15 downto 0);
	Register7 : out std_logic_vector(15 downto 0);
	Register8 : out std_logic_vector(15 downto 0);
	Register9 : out std_logic_vector(15 downto 0);
	RegisterA : out std_logic_vector(15 downto 0);
	RegisterB : out std_logic_vector(15 downto 0);
	RegisterC : out std_logic_vector(15 downto 0);
	RegisterD : out std_logic_vector(15 downto 0);
	RegisterE : out std_logic_vector(15 downto 0);
	RegisterF : out std_logic_vector(15 downto 0)
);
end datapath;

architecture struct of datapath is

signal mux2rf, rf2alu1: std_logic_vector(15 downto 0); 
signal rf2alu2, alu2memmux: std_logic_vector(15 downto 0);

begin		

  U1: smallmux port map(alu2memmux, mem_data, 
			imm_data, RFs_dp, mux2rf);
  U2: reg_file port map(clock_dp, rst_dp, RFwe_dp, 
			RFr1e_dp, RFr2e_dp, 
			RFwa_dp, RFr1a_dp, RFr2a_dp, 
			mux2rf, rf2alu1, rf2alu2, 
			Register0, Register1, Register2, Register3, 
			Register4, Register5, Register6, Register7, 
			Register8, Register9, RegisterA, RegisterB, 
			RegisterC, RegisterD, RegisterE, RegisterF);
  U3: alu port map( rf2alu1, rf2alu2, jp_en, ALUs_dp, 
		    ALUz_dp, alu2memmux);
  U4: obuf port map(oe_dp, mem_data, bufout_dp);
	
  ALUout_dp <= alu2memmux;
  RF1out_dp <= rf2alu1;
	
end struct;