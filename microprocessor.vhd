--------------------------------------------------------
-- Simple Microprocessor Design 
--
-- Microprocessor composed of
-- Ctrl_Unit, Data_Path and Memory
-- structural modeling
-- microprocessor.vhd
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;			   
use ieee.std_logic_unsigned.all;
use work.MP_lib.all;

entity microprocessor is
port( 	cpu_clk:	in std_logic;
		cpu_rst:	in std_logic;
		cpu_output:	out std_logic_vector(15 downto 0);
		performance_counter : out std_logic_vector(15 downto 0);
		
-- Debug variables
		D_addr_bus,D_mdin_bus,D_mdout_bus,D_immd_bus, D_IR, D_rfout_bus: out std_logic_vector(15 downto 0);  
		D_mem_addr: out std_logic_vector(7 downto 0);
		D_mem_addr2: out std_logic_vector(7 downto 0);
		D_RFwa_s, D_RFr1a_s, D_RFr2a_s: out std_logic_vector(3 downto 0);
		D_RFwe_s, D_RFr1e_s, D_RFr2e_s: out std_logic;
		D_ALUs_s: out std_logic_vector(2 downto 0);
		D_RFs_s: out std_logic_vector(1 downto 0);
		D_PCld_s, D_Mre_s, D_Mwe_s, D_jpz_s, D_oe_s: out std_logic;
		D_IR_dir_addr : out std_logic_vector(15 downto 0);
		D_Register0 : out std_logic_vector(15 downto 0);
		D_Register1 : out std_logic_vector(15 downto 0);
		D_Register2 : out std_logic_vector(15 downto 0);
		D_Register3 : out std_logic_vector(15 downto 0);
		D_Register4 : out std_logic_vector(15 downto 0);
		D_Register5 : out std_logic_vector(15 downto 0);
		D_Register6 : out std_logic_vector(15 downto 0);
		D_Register7 : out std_logic_vector(15 downto 0);
		D_Register8 : out std_logic_vector(15 downto 0);
		D_Register9 : out std_logic_vector(15 downto 0);
		D_RegisterA : out std_logic_vector(15 downto 0);
		D_RegisterB : out std_logic_vector(15 downto 0);
		D_RegisterC : out std_logic_vector(15 downto 0);
		D_RegisterD : out std_logic_vector(15 downto 0);
		D_RegisterE : out std_logic_vector(15 downto 0);
		D_RegisterF : out std_logic_vector(15 downto 0);
		D_benchmark : out std_logic
-- end debug variables		
);
end microprocessor;

architecture structure of microprocessor is

signal addr_bus,mdin_bus,mdout_bus,immd_bus,rfout_bus, IR_debug : std_logic_vector(15 downto 0);  
signal mem_addr: std_logic_vector(7 downto 0);

-- New memory signals.
signal mem_read2 : std_logic;
signal mem_addr2 : std_logic_vector(7 downto 0);
signal mem_data_out2 : std_logic_vector(15 downto 0);

signal RFwa_s, RFr1a_s, RFr2a_s: std_logic_vector(3 downto 0);
signal RFwe_s, RFr1e_s, RFr2e_s: std_logic;
signal ALUs_s: std_logic_vector(2 downto 0);
signal RFs_s: std_logic_vector(1 downto 0);
signal PCld_s, Mre_s, Mwe_s, jpz_s, oe_s: std_logic;
signal debug_IR_dir_addr : std_logic_vector(15 downto 0);

signal benchmark : std_logic;

signal counter : std_logic_vector(15 downto 0) := x"0000";

begin
	
	mem_addr <= addr_bus(7 downto 0); 
	
	Unit0: ctrl_unit port map(	cpu_clk,cpu_rst,PCld_s,mem_data_out2,rfout_bus,addr_bus,
								immd_bus, IR_debug, RFs_s,RFwa_s,RFr1a_s,RFr2a_s,RFwe_s,
								RFr1e_s,RFr2e_s,jpz_s,ALUs_s,Mre_s,Mwe_s,oe_s, mem_read2, mem_addr2, debug_IR_dir_addr,
								benchmark);
								
	Unit1: datapath port map(	cpu_clk,cpu_rst,immd_bus,mdout_bus,
								RFs_s,RFwa_s,RFr1a_s,RFr2a_s,RFwe_s,RFr1e_s,
								RFr2e_s,jpz_s,ALUs_s,oe_s,PCld_s,rfout_bus,
								mdin_bus,cpu_output,
								D_Register0, D_Register1, D_Register2, D_Register3, 
								D_Register4, D_Register5, D_Register6, D_Register7, 
								D_Register8, D_Register9, D_RegisterA, D_RegisterB, 
								D_RegisterC, D_RegisterD, D_RegisterE, D_RegisterF);
								
	Unit2: memory port map(	cpu_clk,cpu_rst,Mre_s, mem_read2, Mwe_s,mem_addr, mem_addr2, mdin_bus,mdout_bus, mem_data_out2);
	
	process(cpu_clk, benchmark) begin
		if rising_edge(cpu_clk) and benchmark = '1' then
			counter <= counter + 1;
		end if;
	end process;

performance_counter <= counter;

-- Debug code
D_addr_bus <=addr_bus;
D_mdin_bus <=mdin_bus;
D_mdout_bus <=mdout_bus;
D_immd_bus <=immd_bus;
D_rfout_bus<=rfout_bus;
D_mem_addr<=mem_addr;
D_mem_addr2 <= mem_addr2;
D_RFwa_s<=RFwa_s;
D_RFr1a_s<=RFr1a_s;
D_RFr2a_s<=RFr2a_s;
D_RFwe_s<=RFwe_s;
D_RFr1e_s<=RFr1e_s;
D_RFr2e_s<=RFr2e_s;
D_ALUs_s<=ALUs_s;
D_RFs_s<=RFs_s;
D_PCld_s<=PCld_s;
D_Mre_s<=Mre_s;
D_Mwe_s<=Mwe_s;
D_jpz_s<=jpz_s;
D_oe_s<=oe_s;
D_IR <= IR_debug;
D_IR_dir_addr <= debug_IR_dir_addr;
D_benchmark <= benchmark;

end structure;
