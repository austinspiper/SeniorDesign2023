library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

 
entity inout_mux is
  port (
    adr_mem : out INTEGER RANGE 0 to 65535;
	 data_mem_in : out std_logic_vector(7 downto 0);
	 data_mem_out : in std_logic_vector(7 downto 0);
	 rw_mem : out std_logic := '0';
	 data_1_in : in std_logic_vector(7 downto 0);
	 data_1_out : out std_logic_vector(7 downto 0);
	 data_2_in: in std_logic_vector(7 downto 0);
	 data_2_out : out std_logic_vector(7 downto 0);
	 adr_1 : in INTEGER RANGE 0 to 65535;
	 adr_2 : in INTEGER RANGE 0 to 65535;
	 rw_1 : in std_logic := '0';
	 rw_2 : in std_logic := '0';
	 sel : in std_logic := '0'
	 );
end inout_mux;
 
architecture Behavioral of inout_mux is

begin
  data_1_out <= data_mem_out;
  data_2_out <= data_mem_out;
  data_mem_in <= data_1_in WHEN sel = '0' ELSE data_2_in;
  adr_mem <= adr_1 when (sel = '0') else adr_2;
  rw_mem <= rw_1 when (sel = '0') else rw_2;
end Behavioral;