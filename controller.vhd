----------------------------------------------------------------------------
-- Simple Microprocessor Design (ESD Book Chapter 3)
-- Copyright 2001 Weijun Zhang
--
-- Controller (control logic plus state register)
-- VHDL FSM modeling
-- controller.vhd
----------------------------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

entity controller is
port(	clock:		in std_logic;
	rst:		in std_logic;
	IR_word:	in std_logic_vector(15 downto 0);
	RFs_ctrl:	out std_logic_vector(1 downto 0);
	RFwa_ctrl:	out std_logic_vector(3 downto 0);
	RFr1a_ctrl:	out std_logic_vector(3 downto 0);
	RFr2a_ctrl:	out std_logic_vector(3 downto 0);
	RFwe_ctrl:	out std_logic;
	RFr1e_ctrl:	out std_logic;
	RFr2e_ctrl:	out std_logic;						 
	ALUs_ctrl:	out std_logic_vector(2 downto 0);	 
	jmpen_ctrl:	out std_logic;
	PCinc_ctrl:	out std_logic;
	PCclr_ctrl:	out std_logic;
	IRld_ctrl:	out std_logic;
	Ms_ctrl:	out std_logic_vector(1 downto 0);
	Mre_ctrl:	out std_logic;
	Mwe_ctrl:	out std_logic;
	oe_ctrl:	out std_logic;
	mem_read2 : out std_logic
);
end controller;

architecture fsm of controller is

  type state_type is (  S0,S1,S1a,S1b,S2,S3,S3a,S3b,S4,S4a,S4b,S5,S5a,S5b,
			S6,S6a,S7,S7a,S7b,S8,S8a,S8b,S9,S9a,S9b,S10,S11,S11a, 
			
			-- multiplication states
			Multiply, Multiply_Save_Result, Multiply_Save_Result_B,
			
			-- increment register value states
			Request_Increment, Save_Increment_Result,
			
			-- decrement register value states
			Request_Decrement, Save_Decrement_Result,
			
			-- indirect memory access states
			Start_Indirect_Memory_Access, Write_Indirect_Memory_Access, Save_Indirect_Memory_Access
			);
  signal state: state_type;
	
begin
  process(clock, rst, IR_word)
    variable OPCODE: std_logic_vector(3 downto 0);
  begin
    if rst='1' then			   
		Ms_ctrl <= "10";
		PCclr_ctrl <= '1';		  	-- Reset State
		PCinc_ctrl <= '0';
		IRld_ctrl <= '0';
		RFs_ctrl <= "00";		
		Rfwe_ctrl <= '0';
		Mre_ctrl <= '0';
		mem_read2 <= '0';
		Mwe_ctrl <= '0';					
		jmpen_ctrl <= '0';		
		oe_ctrl <= '0';
		state <= S0;
    elsif (clock'event and clock='1') then
	case state is 
	  when S0 =>	PCclr_ctrl <= '0';	-- Reset State	
			state <= S1;	

	  when S1 =>	PCinc_ctrl <= '0';	
			IRld_ctrl <= '1'; -- Fetch Instruction
			Mre_ctrl <= '1'; -- Old way to read in fetch stage.
			mem_read2 <= '1'; -- New way to read in fetch stage.
			RFwe_ctrl <= '0'; 
			RFr1e_ctrl <= '0'; 
			RFr2e_ctrl <= '0'; 
			Ms_ctrl <= "10";
			Mwe_ctrl <= '0';
			jmpen_ctrl <= '0';
			oe_ctrl <= '0';
			state <= S1a;
	  when S1a => 	
	        IRld_ctrl <= '0';
	        PCinc_ctrl <= '1';
	        Mre_ctrl <= '0';
	        mem_read2 <= '0';
	  		state <= S2;
	  				
	  when S2 =>	
			PCinc_ctrl <= '0';
			OPCODE := IR_word(15 downto 12);
			  case OPCODE is
			    when mov1 => 	state <= S3;
			    when mov2 => 	state <= S4;
			    when mov3 => 	state <= S5;
			    when mov4 => 	state <= S6;
			    when add =>  	state <= S7;
			    when subt =>	state <= S8;
			    when jz =>		state <= S9;
			    when halt =>	state <= S10; 
			    when readm => 	state <= S11;
			    when mult =>	state <= Multiply;
			    when incr =>	state <= Request_Increment;
			    when decr =>	state <= Request_Decrement;
			    when mov5 =>    state <= Start_Indirect_Memory_Access;
			    when others => 	state <= S1;
			    end case;
					
	  when S3 =>	RFwa_ctrl <= IR_word(11 downto 8);	
			RFs_ctrl <= "01";  -- RF[rn] <= mem[direct]
			Ms_ctrl <= "01";
			Mre_ctrl <= '1';
			Mwe_ctrl <= '0';		  
			state <= S3a;
	  when S3a =>   RFwe_ctrl <= '1'; 
	        Mre_ctrl <= '0'; 
			state <= S3b;
	  when S3b => 	RFwe_ctrl <= '0';
			state <= S1;
	    
	  when S4 =>	RFr1a_ctrl <= IR_word(11 downto 8);	
			RFr1e_ctrl <= '1'; -- mem[direct] <= RF[rn]			
			Ms_ctrl <= "01";
			ALUs_ctrl <= "000";	  
			IRld_ctrl <= '0';
			state <= S4a;			-- read value from RF
	  when S4a =>   Mre_ctrl <= '0';
			Mwe_ctrl <= '1';
			state <= S4b;			-- write into memory
	  when S4b =>   Ms_ctrl <= "10";				  
			Mwe_ctrl <= '0';
			state <= S1;
		
	  when S5 =>	RFr1a_ctrl <= IR_word(11 downto 8);	
			RFr1e_ctrl <= '1'; -- mem[RF[rn]] <= RF[rm]
			Ms_ctrl <= "00";
			ALUs_ctrl <= "001";
			RFr2a_ctrl <= IR_word(7 downto 4); 
			RFr2e_ctrl <= '1'; -- set addr.& data
			state <= S5a;
	  when S5a =>   Mre_ctrl <= '0';			
			Mwe_ctrl <= '1'; -- write into memory
			state <= S5b;
	  when S5b => 	Ms_ctrl <= "10";-- return
			Mwe_ctrl <= '0';
			state <= S1;
					
	  when S6 =>	RFwa_ctrl <= IR_word(11 downto 8);	
			RFwe_ctrl <= '1'; -- RF[rn] <= imm.
			RFs_ctrl <= "10";
			IRld_ctrl <= '0';
			state <= S6a;
	  when S6a =>   state <= S1;
	    
	  when S7 =>	RFr1a_ctrl <= IR_word(11 downto 8);	
			RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] + RF[r2]
			RFr2e_ctrl <= '1'; 
			RFr2a_ctrl <= IR_word(7 downto 4);
 			ALUs_ctrl <= "010";
			state <= S7a;
	  when S7a =>   RFr1e_ctrl <= '0';
			RFr2e_ctrl <= '0';
			RFs_ctrl <= "00";
			RFwa_ctrl <= IR_word(3 downto 0);
			RFwe_ctrl <= '1';
			state <= S7b;
	  when S7b =>   state <= S1;
					
	  when S8 =>	RFr1a_ctrl <= IR_word(11 downto 8);	
			RFr1e_ctrl <= '1'; -- RF[rn] <= RF[rn] - RF[rm]
			RFr2a_ctrl <= IR_word(7 downto 4);
			RFr2e_ctrl <= '1';  
			ALUs_ctrl <= "011";
			state <= S8a;
	  when S8a =>   RFr1e_ctrl <= '0';
			RFr2e_ctrl <= '0';
			RFs_ctrl <= "00";
			RFwa_ctrl <= IR_word(3 downto 0);
			RFwe_ctrl <= '1';
			state <= S8b;
	  when S8b =>   state <= S1;
	  when S9 =>	jmpen_ctrl <= '1';
			RFr1a_ctrl <= IR_word(11 downto 8);	
			RFr1e_ctrl <= '1'; -- jz if R[rn] = 0
			ALUs_ctrl <= "000";
			state <= S9a;
	  when S9a =>   state <= S9b;
	  when S9b =>   jmpen_ctrl <= '0';
	        state <= S1;
	  when S10 =>	state <= S10; -- halt
		
	  when S11 =>   Ms_ctrl <= "01";
			Mre_ctrl <= '1'; -- read memory
			Mwe_ctrl <= '0';		  
			state <= S11a;
	  when S11a =>  oe_ctrl <= '1'; 
			state <= S1;
			
		-- Multiplication Instruction
		when Multiply => 
			RFr1a_ctrl <= IR_word(11 downto 8);	
			RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] * RF[r2]
			RFr2e_ctrl <= '1'; 
			RFr2a_ctrl <= IR_word(7 downto 4);
 			ALUs_ctrl <= "100";
			state <= Multiply_Save_Result;
			
		when Multiply_Save_Result => 
			RFr1e_ctrl <= '0';
			RFr2e_ctrl <= '0';
			RFs_ctrl <= "00";
			RFwa_ctrl <= IR_word(3 downto 0);
			RFwe_ctrl <= '1';
			state <= S1;
	  
		-- Increment Instruction
		when Request_Increment =>
			RFr1a_ctrl <= IR_word(11 downto 8); -- Get R1 from instruction.
			RFr1e_ctrl <= '1';                  -- Enable port 1 on register file to read value.
			ALUs_ctrl <= "101";                 -- Select "increment" option in ALU.
			state <= Save_Increment_Result;
	
		when Save_Increment_Result =>
			RFr1e_ctrl <= '0'; -- Disable reading from register file signal.
			RFs_ctrl <= "00";  -- Put result from the ALU onto the RF write bus.
			RFwa_ctrl <= IR_word(11 downto 8);
			RFwe_ctrl <= '1';
			state <= S1;
	  
		-- Decrement Instruction
		when Request_Decrement =>
			RFr1a_ctrl <= IR_word(11 downto 8);
			RFr1e_ctrl <= '1';
			ALUs_ctrl <= "110";
			state <= Save_Decrement_Result;
			
		when Save_Decrement_Result =>
			RFr1e_ctrl <= '0';
			RFs_ctrl <= "00";
			RFwa_ctrl <= IR_word(11 downto 8);
			RFwe_ctrl <= '1';
			state <= S1;
			
		-- Indirect memory access
		when Start_Indirect_Memory_Access =>
			RFr1a_ctrl <= IR_word(11 downto 8); -- Get the address stored in R1.
			RFr1e_ctrl <= '1';	                -- Enable port 1 on register file for reading.
			-- The value in R1 is now available on the RFr1 bus.
			-- RFr1 bus is connected to RFr1out_dp bus.
			-- RFr1out_dp bus is connected to dpdata_out bus.
			-- Next, we need to wire the dpdata_out bus to the maddr_in bus:
			Ms_ctrl <= "00";
			-- Now the memory unit sees the value from R1 on its address bus.
			-- Finally, signal that we intent to read data:
			Mre_ctrl <= '1';
			state <= Write_Indirect_Memory_Access;
			
		when Write_Indirect_Memory_Access =>
			RFr1e_ctrl <= '0';
			-- At this point, the data at the address specified by R1 is now on the data_out bus of the memory unit.
			-- data_out is connected to mem_data bus (and IR bus, but we don't care)
			-- mem_data is option "01" on the smallmux unit.
			-- We want to connect the mem_data bus to the RFw bus:
			RFs_ctrl <= "01";
			-- Done.
			state <= Save_Indirect_Memory_Access;
			
		when Save_Indirect_Memory_Access =>
			-- Now we simply need to instruct our register file to write the value on the bus into the appropriate register:
			RFwa_ctrl <= IR_word(7 downto 4);
			RFwe_ctrl <= '1';
			state <= S1;
	  
	  when others =>
	end case;
    end if;
  end process;
end fsm;