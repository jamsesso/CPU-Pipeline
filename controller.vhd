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
		mem_read2:	out std_logic;
		benchmark_enable : out std_logic;
		benchmark_clear : out std_logic
	);
end controller;

architecture fsm of controller is
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
				
				when bstart =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							benchmark_clear <= '1';
							exec_state <= Second;
							
						when Second =>
							benchmark_clear <= '0';
							exec_state <= Third;
							
						when Third =>
							benchmark_enable <= '1';
							exec_state <= First;
						
						when others =>
					end case;
					
				when bstop =>
					case exec_state is
						when First =>
							RFwe_ctrl <= '0';
							benchmark_enable <= '0';
							exec_state <= Second;
							
						when Second =>
							benchmark_clear <= '1';
							exec_state <= Third;
							
						when Third =>
							benchmark_clear <= '0';
							exec_state <= First;
						
						when others =>
					end case;
				
				when others =>
			end case;
		end if;
	end process;
end architecture;