library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

 
entity inout_mux is
  port (
    adr_mem : out std_logic_vector(15 downto 0);
	 data_mem : inout std_logic_vector(7 downto 0);
	 rw_mem : out std_logic := '0';
	 data_1 : inout std_logic_vector(7 downto 0);
	 data_2 : inout std_logic_vector(7 downto 0);
	 adr_1 : in std_logic_vector(15 downto 0);
	 adr_2 : in std_logic_vector(15 downto 0);
	 rw_1 : in std_logic := '0';
	 rw_2 : in std_logic := '0';
	 sel : in std_logic := '0'
	 );
end inout_mux;
 
architecture Behavioral of inout_mux is

begin

  data_1 <= data_mem when (rw_1 = '0' and sel = '0') else "ZZZZZZZZ";
  data_2 <= data_mem when (rw_2 = '0' and sel = '1') else "ZZZZZZZZ";
  data_mem <= data_1 when (rw_1 = '1' and sel = '0') else
				  data_2 when (rw_2 = '1' and sel = '1') else "ZZZZZZZZ";

  adr_mem <= adr_1 when (sel = '0') else adr_2;
  rw_mem <= rw_1 when (sel = '0') else rw_2;
end Behavioral;