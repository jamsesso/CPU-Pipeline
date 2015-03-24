library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;

package MP_lib is
	type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);

	constant ZERO 	: std_logic_vector(15 downto 0) := "0000000000000000";
	constant HIRES 	: std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	
	-- Instruction definitions.
	constant mov1 	: std_logic_vector(3 downto 0) := "0000"; -- 0
	constant mov2 	: std_logic_vector(3 downto 0) := "0001"; -- 1
	constant mov3 	: std_logic_vector(3 downto 0) := "0010"; -- 2
	constant mov4 	: std_logic_vector(3 downto 0) := "0011"; -- 3
	constant add  	: std_logic_vector(3 downto 0) := "0100"; -- 4
	constant subt 	: std_logic_vector(3 downto 0) := "0101"; -- 5
	constant jz  	: std_logic_vector(3 downto 0) := "0110"; -- 6
	constant halt  	: std_logic_vector(3 downto 0) := "1111"; -- F
	constant readm  : std_logic_vector(3 downto 0) := "0111"; -- 7
	constant mult 	: std_logic_vector(3 downto 0) := "1000"; -- 8
	constant incr 	: std_logic_vector(3 downto 0) := "1001"; -- 9
	constant decr 	: std_logic_vector(3 downto 0) := "1010"; -- A
	constant mov5 	: std_logic_vector(3 downto 0) := "1011"; -- B
	constant bstart : std_logic_vector(3 downto 0) := "1100"; -- C
	constant bstop	: std_logic_vector(3 downto 0) := "1101"; -- D

	component microprocessor is
		port( 	
			cpu_clk:	in std_logic;
			cpu_rst:	in std_logic;
			cpu_output:	out std_logic_vector(15 downto 0);
			performance_counter: out std_logic_vector(15 downto 0)
		); 
	end component;

	component alu is
		port (
			num_A: 	in std_logic_vector(15 downto 0);
			num_B: 	in std_logic_vector(15 downto 0);
			jpsign:	in std_logic;
			ALUs:	in std_logic_vector(2 downto 0);
			ALUz:	out std_logic;
			ALUout:	out std_logic_vector(15 downto 0)
		);
	end component;

	component bigmux is
		port( 	
			Ia: 	in std_logic_vector(15 downto 0);
			Ib: 	in std_logic_vector(15 downto 0);	  
			Ic:	in std_logic_vector(15 downto 0);
			Id:	in std_logic_vector(15 downto 0);
			Option:	in std_logic_vector(1 downto 0);
			Muxout:	out std_logic_vector(15 downto 0)
		);
	end component;

	component controller is
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
			benchmark:  out std_logic
		);
	end component;

	component IR is
		port(
			IRin:	  in std_logic_vector(15 downto 0);
			IRld:	  in std_logic;
			dir_addr: out std_logic_vector(15 downto 0);
			IRout: 	  out std_logic_vector(15 downto 0)
		);
	end component;

	component memory is
		port ( 	
			clock	: 	in std_logic;
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
	end component;

	component obuf is
		port(	
			O_en: 		in std_logic;
			obuf_in: 	in std_logic_vector(15 downto 0);
			obuf_out: 	out std_logic_vector(15 downto 0)
		);
	end component;

	component PC is
		port(	
			clock:	in std_logic;
			PCld:	in std_logic;
			PCinc:	in std_logic;
			PCclr:	in std_logic;
			PCin:	in std_logic_vector(15 downto 0);
			PCout:	out std_logic_vector(15 downto 0)
		);
	end component;

	component reg_file is
		port ( 	
			clock	: 	in std_logic; 	
			rst	: 	in std_logic;
			RFwe	: 	in std_logic;
			RFr1e	: 	in std_logic;
			RFr2e	: 	in std_logic;	
			RFwa	: 	in std_logic_vector(3 downto 0);  
			RFr1a	: 	in std_logic_vector(3 downto 0);
			RFr2a	: 	in std_logic_vector(3 downto 0);
			RFw	: 	in std_logic_vector(15 downto 0);
			RFr1	: 	out std_logic_vector(15 downto 0);
			RFr2	:	out std_logic_vector(15 downto 0);
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
	end component;

	component smallmux is
		port( 	
			I0: 	in std_logic_vector(15 downto 0);
			I1: 	in std_logic_vector(15 downto 0);	  
			I2:		in std_logic_vector(15 downto 0);
			Sel:	in std_logic_vector(1 downto 0);
			O: 		out std_logic_vector(15 downto 0)
		);
	end component;

	component ctrl_unit is
		port(	
			clock_cu:	in 	std_logic;
			rst_cu:		in 	std_logic;
			PCld_cu:	in 	std_logic;
			mdata_out: 	in 	std_logic_vector(15 downto 0);
			dpdata_out:	in 	std_logic_vector(15 downto 0);
			maddr_in:	out 	std_logic_vector(15 downto 0);		  
			immdata:	out 	std_logic_vector(15 downto 0);
			IR_debug :  out std_logic_vector(15 downto 0);
			RFs_cu:		out	std_logic_vector(1 downto 0);
			RFwa_cu:	out	std_logic_vector(3 downto 0);
			RFr1a_cu:	out	std_logic_vector(3 downto 0);
			RFr2a_cu:	out	std_logic_vector(3 downto 0);
			RFwe_cu:	out	std_logic;
			RFr1e_cu:	out	std_logic;
			RFr2e_cu:	out	std_logic;
			jpen_cu:	out 	std_logic;
			ALUs_cu:	out	std_logic_vector(2 downto 0);	
			Mre_cu:		out 	std_logic;
			Mwe_cu:		out 	std_logic;
			oe_cu:		out 	std_logic;
			mem_read2 : out std_logic;
			mem_addr2 : out std_logic_vector(7 downto 0);
			IR_dir_addr_debug : out std_logic_vector(15 downto 0);
			benchmark : out std_logic
		);
	end component;

	component datapath is				
		port(	
			clock_dp:	in 	std_logic;
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
	end component;
	
	component SevenSegment is
        port(
                HexData : in std_logic_vector(3 downto 0);
                Display : out std_logic_vector(6 downto 0)
        );
	end component;
end MP_lib;

package body MP_lib is

end MP_lib;
