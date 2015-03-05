library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Controller is
	port(
		clock 			: in std_logic;
		reset 			: in std_logic;
		fetch_output 	: out std_logic_vector(3 downto 0);
		exec_output 	: out std_logic_vector(3 downto 0)
	);
end entity;

architecture Behaviour of Controller is
	type FetchState is (Fetch, IncrementPC, Decode);
	type ExecState is (First, Second, Third);
	
	signal fetch_state : FetchState := Fetch;
	signal exec_state : ExecState := First;
	shared variable fetch_ready : std_logic;
begin
	-- Fetch stage.
	FetchStage: process(clock, reset) begin
		if reset = '1' then
			fetch_ready := '0';
		elsif rising_edge(clock) then
			case fetch_state is
				when Fetch =>
					fetch_output <= x"A";
					fetch_state <= IncrementPC;
				when IncrementPC =>
					fetch_output <= x"B";
					fetch_state <= Decode;
				when Decode =>
					fetch_output <= x"C";
					fetch_ready := '1';
					fetch_state <= Fetch;
			end case;
		end if;
	end process;
	
	-- Execute stage.
	ExecuteStage: process(clock, reset) begin
		if rising_edge(clock) and fetch_ready = '1' then
			case exec_state is
				when First =>
					exec_output <= x"1";
					exec_state <= Second;
				when Second => 
					exec_output <= x"2";
					exec_state <= Third;
				when Third =>
					exec_output <= x"3";
					exec_state <= First;
			end case;
		end if;
	end process;
end architecture;