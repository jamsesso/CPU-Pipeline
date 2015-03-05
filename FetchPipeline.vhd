library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

entity FetchPipeline is
	port(
		-- Module inputs.
		clock					: in std_logic;
		reset					: in std_logic;
		instruction_reg			: in std_logic_vector(15 downto 0);
		
		-- Module outputs.
		reg_file_bus_select		: out std_logic_vector(1 downto 0);
		reg_file_write			: out std_logic_vector(3 downto 0);
		reg_file_read1			: out std_logic_vector(3 downto 0);
		reg_file_read2			: out std_logic_vector(3 downto 0);
		reg_file_write_en		: out std_logic; -- Active HIGH
		reg_file_read1_en		: out std_logic; -- Active HIGH
		reg_file_read2_en		: out std_logic; -- Active HIGH
		pc_increment_en			: out std_logic; -- Active HIGH
		instruction_reg_load_en	: out std_logic; -- Active HIGH
		mem_bus_select			: out std_logic_vector(1 downto 0);
		mem_write_en			: out std_logic; -- Active HIGH
		mem_read_en				: out std_logic; -- Active HIGH
		jump_en					: out std_logic; -- Active HIGH
		output_en				: out std_logic; -- Active HIGH
		opcode					: out std_logic_vector(3 downto 0)
	);
end entity;

architecture Behaviour of FetchPipeline is
	type FetchState is (
		FetchInstruction,
		IncrementProgramCounter,
		DecodeInstruction
	);
	
	signal state : FetchState;
begin
	process begin
		if rising_edge(clock) then
			case state is
				when FetchInstruction =>
					-- Load the instruction register.
					pc_increment_en <= '0';
					instruction_reg_load_en <= '1';
					
					-- Connect the memory data bus to the instruction register.
					mem_read_en <= '1';
					mem_write_en <= '0';
					mem_bus_select <= "10";
					
					-- Reset register signals.
					reg_file_write_en <= '0';
					reg_file_read1_en <= '0';
					reg_file_read2_en <= '0';
					
					-- Reset jump and output instructions.
					jump_en <= '0';
					output_en <= '0';
					state <= IncrementProgramCounter;
				
				when IncrementProgramCounter =>
					-- Enable PC module.
					instruction_reg_load_en <= '0';
					pc_increment_en <= '1';
					mem_read_en <= '0';
					state <= DecodeInstruction;
				
				when DecodeInstruction =>
					-- Disable PC module and decode instruction.
					pc_increment_en <= '0';
					opcode <= instruction_reg(3 downto 0);
					state <= FetchInstruction;
				when others =>
			end case;
		end if;
	end process;
end architecture;