library ieee;
use ieee.std_logic_1164.all;

entity SevenSegment is
        port(
                HexData : in std_logic_vector(3 downto 0);
                Display : out std_logic_vector(6 downto 0)
        );
end entity;

architecture Behaviour of SevenSegment is
begin
        process(HexData)
        begin
                case HexData is
                        when "0000" => Display <= not ("1111110");
                        when "0001" => Display <= not ("0110000");
                        when "0010" => Display <= not ("1101101");
                        when "0011" => Display <= not ("1111001");
                        when "0100" => Display <= not ("0110011");
                        when "0101" => Display <= not ("1011011");
                        when "0110" => Display <= not ("1011111");
                        when "0111" => Display <= not ("1110000");
                        when "1000" => Display <= not ("1111111");
                        when "1001" => Display <= not ("1111011");
                        when "1010" => Display <= not ("1110111");
                        when "1011" => Display <= not ("0011111");
                        when "1100" => Display <= not ("0001101");
                        when "1101" => Display <= not ("0111101");
                        when "1110" => Display <= not ("1001111");
                        when "1111" => Display <= not ("1000111");
                end case;
        end process;
end architecture;