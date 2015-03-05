library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS
-- FUCKING PISS

entity ExecutePipeline is
	port(
		opcode		: in std_logic_vector(3 downto 0);
		clock		: in std_logic;
		rst			: in std_logic;
		IR_word		: in std_logic_vector(15 downto 0);
		RFs_ctrl	: out std_logic_vector(1 downto 0);
		RFwa_ctrl	: out std_logic_vector(3 downto 0);
		RFr1a_ctrl	: out std_logic_vector(3 downto 0);
		RFr2a_ctrl	: out std_logic_vector(3 downto 0);
		RFwe_ctrl	: out std_logic;
		RFr1e_ctrl	: out std_logic;
		RFr2e_ctrl	: out std_logic;						 
		ALUs_ctrl	: out std_logic_vector(2 downto 0);	 
		jmpen_ctrl	: out std_logic;
		PCinc_ctrl	: out std_logic;
		PCclr_ctrl	: out std_logic;
		IRld_ctrl	: out std_logic;
		Ms_ctrl		: out std_logic_vector(1 downto 0);
		Mre_ctrl	: out std_logic;
		Mwe_ctrl	: out std_logic;
		oe_ctrl		: out std_logic
	);
end entity;

architecture Behaviour of ExecutePipeline is
	type ExecuteState is (
		First,
		Second,
		Third
	);
	
	signal state : ExecuteState;
begin
	process begin
		if (rising_edge(clock) and opcode /= "ZZZZ") then
			state <= First;
			
			case opcode is
				when mov1 =>
					case state is
						when First =>
							RFwa_ctrl <= IR_word(11 downto 8);	
							RFs_ctrl <= "01";  -- RF[rn] <= mem[direct]
							Ms_ctrl <= "01";
							Mre_ctrl <= '1';
							Mwe_ctrl <= '0';
							state <= Second;
						when Second =>
							RFwe_ctrl <= '1'; 
							Mre_ctrl <= '0'; 
							state <= Third;
						when Third =>
							RFwe_ctrl <= '0';
							state <= First;
					end case;

				when mov2 =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- mem[direct] <= RF[rn]			
							Ms_ctrl <= "01";
							ALUs_ctrl <= "000";	  
							IRld_ctrl <= '0';
							state <= Second;
						when Second =>
							Mre_ctrl <= '0';
							Mwe_ctrl <= '1';
							state <= Third;
						when Third =>
							Ms_ctrl <= "10";				  
							Mwe_ctrl <= '0';
							state <= First;
					end case;
					
				when mov3 =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- mem[RF[rn]] <= RF[rm]
							Ms_ctrl <= "00";
							ALUs_ctrl <= "001";
							RFr2a_ctrl <= IR_word(7 downto 4); 
							RFr2e_ctrl <= '1'; -- set addr.& data
							state <= Second;
						when Second =>
							Mre_ctrl <= '0';			
							Mwe_ctrl <= '1'; -- write into memory
							state <= Third;
						when Third =>
							Ms_ctrl <= "10";-- return
							Mwe_ctrl <= '0';
							state <= First;
					end case;

				when mov4 =>
					case state is
						when First =>
							RFwa_ctrl <= IR_word(11 downto 8);	
							RFwe_ctrl <= '1'; -- RF[rn] <= imm.
							RFs_ctrl <= "10";
							IRld_ctrl <= '0';
							state <= Second;
						when Second =>
							state <= Third;
						when Third =>
							state <= First;
					end case;

				when mov5 =>
					case state is
						when First =>
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
							state <= Second;
						when Second =>
							RFr1e_ctrl <= '0';
							-- At this point, the data at the address specified by R1 is now on the data_out bus of the memory unit.
							-- data_out is connected to mem_data bus (and IR bus, but we don't care)
							-- mem_data is option "01" on the smallmux unit.
							-- We want to connect the mem_data bus to the RFw bus:
							RFs_ctrl <= "01";
							-- Done.
							state <= Third;
						when Third =>
							-- Now we simply need to instruct our register file to write the value on the bus into the appropriate register:
							RFwa_ctrl <= IR_word(7 downto 4);
							RFwe_ctrl <= '1';
							state <= First;
					end case;
					
				when add =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] + RF[r2]
							RFr2e_ctrl <= '1'; 
							RFr2a_ctrl <= IR_word(7 downto 4);
							ALUs_ctrl <= "010";
							state <= Second;
						when Second =>
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(3 downto 0);
							RFwe_ctrl <= '1';
							state <= Third;
						when Third =>
							state <= First;
					end case;
					
				when subt =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- RF[rn] <= RF[rn] - RF[rm]
							RFr2a_ctrl <= IR_word(7 downto 4);
							RFr2e_ctrl <= '1';  
							ALUs_ctrl <= "011";
							state <= Second;
						when Second =>
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(3 downto 0);
							RFwe_ctrl <= '1';
							state <= Third;
						when Third =>
							state <= First;
					end case;
					
				when jz =>
					case state is
						when First =>
							jmpen_ctrl <= '1';
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- jz if R[rn] = 0
							ALUs_ctrl <= "000";
							state <= Second;
						when Second =>
							state <= Third;
						when Third =>
							jmpen_ctrl <= '0';
							state <= First;
					end case;
					
				when halt =>
					-- need to figure out what to do
					-- need a way to flush fetching
					case state is
						when First =>
							state <= Second;
						when Second =>
							state <= Third;
						when Third =>
							state <= First;
					end case;
					
				when readm =>
					case state is
						when First =>
							Ms_ctrl <= "01";
							Mre_ctrl <= '1'; -- read memory
							Mwe_ctrl <= '0';
							state <= Second;
						when Second =>
							oe_ctrl <= '1';
							state <= Third;
						when Third =>
							state <= First;
					end case;
					
				when mult =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8);	
							RFr1e_ctrl <= '1'; -- RF[r3] <= RF[r1] * RF[r2]
							RFr2e_ctrl <= '1'; 
							RFr2a_ctrl <= IR_word(7 downto 4);
							ALUs_ctrl <= "100";
							state <= Second;
						when Second =>
							RFr1e_ctrl <= '0';
							RFr2e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(3 downto 0);
							RFwe_ctrl <= '1';
							state <= Third;
						when Third =>
							state <= First;
					end case;
					
				when incr =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8); -- Get R1 from instruction.
							RFr1e_ctrl <= '1';                  -- Enable port 1 on register file to read value.
							ALUs_ctrl <= "101";                 -- Select "increment" option in ALU.
							state <= Second;
						when Second =>
							RFr1e_ctrl <= '0'; -- Disable reading from register file signal.
							RFs_ctrl <= "00";  -- Put result from the ALU onto the RF write bus.
							RFwa_ctrl <= IR_word(11 downto 8);
							RFwe_ctrl <= '1';
							state <= Third;
						when Third =>
							state <= First;
					end case;

				when decr =>
					case state is
						when First =>
							RFr1a_ctrl <= IR_word(11 downto 8);
							RFr1e_ctrl <= '1';
							ALUs_ctrl <= "110";
							state <= Second;
						when Second =>
							RFr1e_ctrl <= '0';
							RFs_ctrl <= "00";
							RFwa_ctrl <= IR_word(11 downto 8);
							RFwe_ctrl <= '1';
							state <= Third;
						when Third =>
							state <= First;
					end case;
				
				when others =>
			end case;
		end if;
	end process;
end architecture;