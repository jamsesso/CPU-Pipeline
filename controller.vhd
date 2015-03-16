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
	port(
		clock:		in std_logic;
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
		mem_read2:	out std_logic
	);
end controller;

architecture fsm of controller is
	type state_type is (
		-- Fetch instruction states:
		S0,S1,S1a,S2,
		
		-- Execute instruction states:
		S3,S3a,S3b,
		S4,S4a,S4b,
		S5,S5a,S5b,
		S6,S6a,
		S7,S7a,S7b,
		S8,S8a,S8b,
		S9,S9a,S9b,
		S10,
		S11,S11a,S11b,

		-- multiplication states
		Multiply, Multiply_Save_Result, Multiply_Cleanup,

		-- increment register value states
		Request_Increment, Save_Increment_Result, Increment_Cleanup,

		-- decrement register value states
		Request_Decrement, Save_Decrement_Result, Decrement_Cleanup,

		-- indirect memory access states
		Start_Indirect_Memory_Access, Write_Indirect_Memory_Access, Save_Indirect_Memory_Access
	);
	
	signal state: state_type;
	
	-- New stuff:
	type FetchState is (PreFetch, Fetch, IncrementPC, Decode);
	type ExecuteState is (First, Second, Third, JZWait1, JZWait2, JZWait3);
	
	signal fetch_state : FetchState := PreFetch;
	signal exec_state : ExecuteState := First;
	shared variable fetch_ready : std_logic := '0';
	shared variable opcode : std_logic_vector(3 downto 0);
	shared variable halt_cpu : std_logic := '0';
	shared variable flush_pipeline : std_logic := '0';
begin
	-- Fetch stage.
	FetchStage: process(clock, rst, IR_word) begin
		if rst = '1' then
			fetch_ready := '0';
			fetch_state <= PreFetch;
			mem_read2   <= '0';
			PCclr_ctrl  <= '1';
			PCinc_ctrl  <= '0';
			IRld_ctrl   <= '0';
		elsif flush_pipeline = '1' then
			fetch_state <= Fetch;
			mem_read2   <= '0';
			PCinc_ctrl  <= '0';
			IRld_ctrl   <= '0';
		elsif rising_edge(clock) and halt_cpu = '0' then
			case fetch_state is
				when PreFetch =>
					PCclr_ctrl <= '0';
					fetch_state <= Fetch;
					
				when Fetch =>
					-- Fetch instruction.
					-- Tell IR to write the instruction from memory and send the read signal to memory to get the instruction.
					IRld_ctrl <= '1';
					mem_read2 <= '1';
					fetch_state <= IncrementPC;
					
				when IncrementPC =>
					-- Done loading new instruction into IR, deassert signals.
					IRld_ctrl  <= '0';
					mem_read2  <= '0';
					-- Tell the PC to start incrementing.
					PCinc_ctrl <= '1';
					fetch_state <= Decode;
					
				when Decode =>
					PCinc_ctrl  <= '0';
					fetch_ready := '1';
					opcode      := IR_word(15 downto 12);
					fetch_state <= Fetch;
			end case;
		end if;
	end process;
	
	-- Execute stage.
	ExecuteStage: process(clock, rst) begin
		if rst = '1' then
			RFs_ctrl   <= "00";
			RFwe_ctrl  <= '0';
			Mre_ctrl   <= '0';
			Mwe_ctrl   <= '0';
			jmpen_ctrl <= '0';
			oe_ctrl    <= '0';
		elsif rising_edge(clock) and fetch_ready = '1' and halt_cpu = '0' then
			case opcode is
				when mov1 =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFwa_ctrl <= IR_word(11 downto 8);	
							RFs_ctrl <= "01";  -- RF[rn] <= mem[direct]
							Ms_ctrl <= "01";
							Mre_ctrl <= '1';
							Mwe_ctrl <= '0';
							exec_state <= Second;
							
						when Second =>
							RFwe_ctrl <= '1';
							Mre_ctrl <= '0';
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when mov2 =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- mem[direct] <= RF[rn]			
							Ms_ctrl <= "01";
							ALUs_ctrl <= "000";
							exec_state <= Second;
							
						when Second =>
							Mre_ctrl <= '0';
							Mwe_ctrl <= '1';
							exec_state <= Third;
							
						when Third =>
							Mwe_ctrl <= '0';
							RFr1e_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when mov3 =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- mem[RF[rn]] <= RF[rm]
							Ms_ctrl <= "00";
							ALUs_ctrl <= "001";
							RFr2a_ctrl <= IR_word(7 downto 4); 
							RFr2e_ctrl <= '1'; -- set addr.& data
							exec_state <= Second;
							
						when Second =>
							Mre_ctrl <= '0';			
							Mwe_ctrl <= '1'; -- write into memory
							exec_state <= Third;
							
						when Third =>
							Mwe_ctrl <= '0';
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when mov4 =>
					case exec_state is
						when First =>
							RFwa_ctrl <= IR_word(11 downto 8);	
							RFwe_ctrl <= '1'; -- RF[rn] <= imm.
							RFs_ctrl <= "10";
							exec_state <= Second;
							
						when Second =>
							RFwe_ctrl <= '0';
							exec_state <= Third;
							
						when Third =>
							-- Wait state.
							exec_state <= First;
							
						when others =>
					end case;
					
				when add =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] + RF[r2]
							RFr2e_ctrl <= '1'; 
							RFr2a_ctrl <= IR_word(7 downto 4);
							ALUs_ctrl <= "010";
							exec_state <= Second;
							
						when Second =>
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(3 downto 0);
							RFwe_ctrl <= '1';
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when subt =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- RF[rn] <= RF[rn] - RF[rm]
							RFr2a_ctrl <= IR_word(7 downto 4);
							RFr2e_ctrl <= '1';  
							ALUs_ctrl <= "011";
							exec_state <= Second;
							
						when Second =>
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(3 downto 0);
							RFwe_ctrl <= '1';
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when jz =>
					case exec_state is
						when First =>
							flush_pipeline := '1';
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- jz if R[rn] = 0
							ALUs_ctrl <= "000";
							exec_state <= Second;
							
						when Second =>
							jmpen_ctrl <= '1';
							RFr1e_ctrl <= '0';
							exec_state <= Third;
							
						when Third =>
							flush_pipeline := '0';
							jmpen_ctrl <= '0';
							RFs_ctrl   <= "00";
							RFwe_ctrl  <= '0';
							Mre_ctrl   <= '0';
							Mwe_ctrl   <= '0';
							oe_ctrl    <= '0';
							exec_state <= JZWait1;
							
						when JZWait1 =>
							exec_state <= JZWait2;
							
						when JZWait2 =>
							exec_state <= JZWait3;
							
						when JZWait3 =>
							exec_state <= First;
					end case;
					
				when halt =>
					case exec_state is
						when First =>
							halt_cpu := '1';
							
						when others => -- Doesn't matter, CPU is halted.
					end case;
					
				when readm =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							Ms_ctrl <= "01";
							Mre_ctrl <= '1'; -- read memory
							Mwe_ctrl <= '0';
							exec_state <= Second;
							
						when Second =>
							oe_ctrl <= '1'; 
							exec_state <= Third;
							
						when Third =>
							oe_ctrl  <= '0';
							Mre_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when mult =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] * RF[r2]
							RFr2e_ctrl <= '1'; 
							RFr2a_ctrl <= IR_word(7 downto 4);
							ALUs_ctrl <= "100";
							exec_state <= Second;
							
						when Second =>
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(3 downto 0);
							RFwe_ctrl <= '1';
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when incr =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8); -- Get R1 from instruction.
							RFr1e_ctrl <= '1';                  -- Enable port 1 on register file to read value.
							ALUs_ctrl <= "101";                 -- Select "increment" option in ALU.
							exec_state <= Second;
							
						when Second =>
							RFr1e_ctrl <= '0'; -- Disable reading from register file signal.
							RFs_ctrl <= "00";  -- Put result from the ALU onto the RF write bus.
							RFwa_ctrl <= IR_word(11 downto 8);
							RFwe_ctrl <= '1';
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '0';
							exec_state <= First;
							
						when others =>
					end case;
					
				when decr =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8);
							RFr1e_ctrl <= '1';
							ALUs_ctrl <= "110";
							exec_state <= Second;
							
						when Second =>
							RFr1e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(11 downto 8);
							RFwe_ctrl <= '1';
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '0';
							exec_state <= First;
						
						when others =>
					end case;
					
				when mov5 =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							RFr1a_ctrl <= IR_word(11 downto 8); -- Get the address stored in R1.
							RFr1e_ctrl <= '1';	                -- Enable port 1 on register file for reading.
							Ms_ctrl <= "00";
							RFs_ctrl <= "01";
							exec_state <= Second;
							
						when Second =>
							RFr1e_ctrl <= '0';
							Mre_ctrl <= '1';
							RFwa_ctrl <= IR_word(7 downto 4);
							exec_state <= Third;
							
						when Third =>
							RFwe_ctrl <= '1';
							Mre_ctrl <= '0';
							exec_state <= First;
						
						when others =>
					end case;
				
				when others =>
			end case;
		end if;
	end process;

--	process(clock, rst, IR_word)
--		variable OPCODE: std_logic_vector(3 downto 0);
--	begin
--		if rst='1' then
--			PCclr_ctrl <= '1';		  	-- Reset State
--			PCinc_ctrl <= '0';
--			IRld_ctrl <= '0';
--			RFs_ctrl <= "00";		
--			RFwe_ctrl <= '0';
--			Mre_ctrl <= '0';
--			mem_read2 <= '0';
--			Mwe_ctrl <= '0';					
--			jmpen_ctrl <= '0';		
--			oe_ctrl <= '0';
--			state <= S0;
--		elsif rising_edge(clock) then
--			case state is 
--				when S0 =>	
--					PCclr_ctrl <= '0';	-- Reset State	
--					state <= S1;	
--
---- START FETCH STAGE
--				when S1 =>
--					-- Fetch instruction.
--					-- Tell IR to write the instruction from memory and send the read signal to memory to get the instruction.
--					IRld_ctrl <= '1';
--					mem_read2 <= '1';
--					state <= S1a;
--				
--				when S1a =>
--					-- Done loading new instruction into IR, deassert signals.
--					IRld_ctrl <= '0';
--					mem_read2 <= '0';	
--					-- Tell the PC to start incrementing.
--					PCinc_ctrl <= '1';
--					state <= S2;
--					
--				when S2 =>
--					-- Tell the PC to stop incrementing.
--					PCinc_ctrl <= '0';
--					OPCODE := IR_word(15 downto 12);
--					  case OPCODE is
--						when mov1 => 	state <= S3;
--						when mov2 => 	state <= S4;
--						when mov3 => 	state <= S5;
--						when mov4 => 	state <= S6;
--						when add =>  	state <= S7;
--						when subt =>	state <= S8;
--						when jz =>		state <= S9;
--						when halt =>	state <= S10; 
--						when readm => 	state <= S11;
--						when mult =>	state <= Multiply;
--						when incr =>	state <= Request_Increment;
--						when decr =>	state <= Request_Decrement;
--						when mov5 =>    state <= Start_Indirect_Memory_Access;
--						when others => 	state <= S1;
--						end case;
---- END FETCH STAGE
--
---- START EXECUTE STAGE
--				-- A move instruction.
--				when S3 =>
--					RFwe_ctrl <= '0';
--					RFwa_ctrl <= IR_word(11 downto 8);	
--					RFs_ctrl <= "01";  -- RF[rn] <= mem[direct]
--					Ms_ctrl <= "01";
--					Mre_ctrl <= '1';
--					Mwe_ctrl <= '0';		  
--					state <= S3a;
--				when S3a =>   
--					RFwe_ctrl <= '1'; 
--					Mre_ctrl <= '0'; 
--					state <= S3b;
--				when S3b => 	
--					RFwe_ctrl <= '0';
--					state <= S1;
--				
--				-- A move instruction.
--				when S4 =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8);	
--					RFr1e_ctrl <= '1'; -- mem[direct] <= RF[rn]			
--					Ms_ctrl <= "01";
--					ALUs_ctrl <= "000";	  
--					IRld_ctrl <= '0';
--					state <= S4a;			-- read value from RF
--				when S4a =>   
--					Mre_ctrl <= '0';
--					Mwe_ctrl <= '1';
--					state <= S4b;			-- write into memory
--				when S4b =>			  
--					Mwe_ctrl <= '0';
--					RFr1e_ctrl <= '0';
--					state <= S1;
--				
--				-- A move instruction.
--				when S5 =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8);	
--					RFr1e_ctrl <= '1'; -- mem[RF[rn]] <= RF[rm]
--					Ms_ctrl <= "00";
--					ALUs_ctrl <= "001";
--					RFr2a_ctrl <= IR_word(7 downto 4); 
--					RFr2e_ctrl <= '1'; -- set addr.& data
--					state <= S5a;
--				when S5a =>   
--					Mre_ctrl <= '0';			
--					Mwe_ctrl <= '1'; -- write into memory
--					state <= S5b;
--				when S5b =>
--					Mwe_ctrl <= '0';
--					RFr1e_ctrl <= '0';
--					RFr2e_ctrl <= '0';
--					state <= S1;
--				
--				-- Put immediate value in register instruction.
--				when S6 =>	
--					RFwa_ctrl <= IR_word(11 downto 8);	
--					RFwe_ctrl <= '1'; -- RF[rn] <= imm.
--					RFs_ctrl <= "10";
--					IRld_ctrl <= '0';
--					state <= S6a;
--				when S6a =>
--					RFwe_ctrl <= '0';
--					state <= S1;
--				
--				-- Addition instruction.
--				when S7 =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8);	
--					RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] + RF[r2]
--					RFr2e_ctrl <= '1'; 
--					RFr2a_ctrl <= IR_word(7 downto 4);
--					ALUs_ctrl <= "010";
--					state <= S7a;
--				when S7a =>   
--					RFr1e_ctrl <= '0';
--					RFr2e_ctrl <= '0';
--					RFs_ctrl <= "00";
--					RFwa_ctrl <= IR_word(3 downto 0);
--					RFwe_ctrl <= '1';
--					state <= S7b;
--				when S7b =>
--					RFwe_ctrl <= '0';
--					state <= S1;
--				
--				-- Subtraction instruction.
--				when S8 =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8);	
--					RFr1e_ctrl <= '1'; -- RF[rn] <= RF[rn] - RF[rm]
--					RFr2a_ctrl <= IR_word(7 downto 4);
--					RFr2e_ctrl <= '1';  
--					ALUs_ctrl <= "011";
--					state <= S8a;
--				when S8a =>   
--					RFr1e_ctrl <= '0';
--					RFr2e_ctrl <= '0';
--					RFs_ctrl <= "00";
--					RFwa_ctrl <= IR_word(3 downto 0);
--					RFwe_ctrl <= '1';
--					state <= S8b;
--				when S8b =>
--					RFwe_ctrl <= '0';
--					state <= S1;
--				
--				-- Jump instruction
--				when S9 =>
--					RFwe_ctrl <= '0';
--					jmpen_ctrl <= '1';
--					RFr1a_ctrl <= IR_word(11 downto 8);	
--					RFr1e_ctrl <= '1'; -- jz if R[rn] = 0
--					ALUs_ctrl <= "000";
--					state <= S9a;
--				when S9a =>
--					RFr1e_ctrl <= '0';
--					state <= S9b;
--				when S9b =>   
--					jmpen_ctrl <= '0';
--					state <= S1;
--					
--				-- Halt instruction
--				when S10 =>
--					RFwe_ctrl <= '0';
--					state <= S10; -- halt
--				
--				-- Output Instruction
--				when S11 =>  
--					RFwe_ctrl <= '0';
--					Ms_ctrl <= "01";
--					Mre_ctrl <= '1'; -- read memory
--					Mwe_ctrl <= '0';		  
--					state <= S11a;
--				when S11a =>  
--					oe_ctrl <= '1'; 
--					state <= S11b;
--				when S11b =>
--					oe_ctrl <= '0';
--					Mre_ctrl <= '0';
--					state <= S1;
--					
--				-- Multiplication Instruction
--				when Multiply =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8);	
--					RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] * RF[r2]
--					RFr2e_ctrl <= '1'; 
--					RFr2a_ctrl <= IR_word(7 downto 4);
--					ALUs_ctrl <= "100";
--					state <= Multiply_Save_Result;
--					
--				when Multiply_Save_Result => 
--					RFr1e_ctrl <= '0';
--					RFr2e_ctrl <= '0';
--					RFs_ctrl <= "00";
--					RFwa_ctrl <= IR_word(3 downto 0);
--					RFwe_ctrl <= '1';
--					state <= Multiply_Cleanup;
--					
--				when Multiply_Cleanup =>
--					RFwe_ctrl <= '0';
--					state <= S1;
--			  
--				-- Increment Instruction
--				when Request_Increment =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8); -- Get R1 from instruction.
--					RFr1e_ctrl <= '1';                  -- Enable port 1 on register file to read value.
--					ALUs_ctrl <= "101";                 -- Select "increment" option in ALU.
--					state <= Save_Increment_Result;
--			
--				when Save_Increment_Result =>
--					RFr1e_ctrl <= '0'; -- Disable reading from register file signal.
--					RFs_ctrl <= "00";  -- Put result from the ALU onto the RF write bus.
--					RFwa_ctrl <= IR_word(11 downto 8);
--					RFwe_ctrl <= '1';
--					state <= Increment_Cleanup;
--					
--				when Increment_Cleanup =>
--					RFwe_ctrl <= '0';
--					state <= S1;
--			  
--				-- Decrement Instruction
--				when Request_Decrement =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8);
--					RFr1e_ctrl <= '1';
--					ALUs_ctrl <= "110";
--					state <= Save_Decrement_Result;
--					
--				when Save_Decrement_Result =>
--					RFr1e_ctrl <= '0';
--					RFs_ctrl <= "00";
--					RFwa_ctrl <= IR_word(11 downto 8);
--					RFwe_ctrl <= '1';
--					state <= Decrement_Cleanup;
--					
--				when Decrement_Cleanup =>
--					RFwe_ctrl <= '0';
--					state <= S1;
--					
--				-- Indirect memory access
--				when Start_Indirect_Memory_Access =>
--					RFwe_ctrl <= '0';
--					RFr1a_ctrl <= IR_word(11 downto 8); -- Get the address stored in R1.
--					RFr1e_ctrl <= '1';	                -- Enable port 1 on register file for reading.
--					Ms_ctrl <= "00";
--					RFs_ctrl <= "01";
--					state <= Write_Indirect_Memory_Access;
--					
--				when Write_Indirect_Memory_Access =>
--					RFr1e_ctrl <= '0';
--					Mre_ctrl <= '1';
--					RFwa_ctrl <= IR_word(7 downto 4);
--					state <= Save_Indirect_Memory_Access;
--					
--				when Save_Indirect_Memory_Access =>
--					RFwe_ctrl <= '1';
--					Mre_ctrl <= '0';
--					state <= S1;
---- END EXECUTE STAGE
--			  when others =>
--			end case;
--		end if;
--	end process;
end architecture;