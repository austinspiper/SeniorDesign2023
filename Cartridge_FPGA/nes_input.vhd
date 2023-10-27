library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

 
entity nes_input is
  port (
	 CLK : in std_logic := '0';
    ppu_adr_out : out std_logic_vector(15 downto 0);
    cpu_adr_out : out std_logic_vector(15 downto 0);
	 ppu_data : inout std_logic_vector(7 downto 0);
	 cpu_data : inout std_logic_vector(7 downto 0);
	 ppu_data_nes : inout std_logic_vector(7 downto 0);
	 cpu_data_nes : inout std_logic_vector(7 downto 0);
	 ppu_adr_in : in std_logic_vector(13 downto 0);
    cpu_adr_in : in std_logic_vector(14 downto 0);
	 cpu_rw_out : out std_logic := '0';
	 ppu_rw_out : out std_logic := '0';
	 cpu_rw_in : in std_logic := '0';
	 ppu_rd : in std_logic := '0';
	 ppu_wr : in std_logic := '0';
	 m2 : in  std_logic := '0';
    romsel : in  std_logic := '1'
    );
end nes_input;
 
architecture Behavioral of nes_input is
begin

	
  cpu_adr_out(14 downto 0) <= cpu_adr_in;
  cpu_adr_out(15) <= '1' when (romsel = '0' and m2 = '1') else '0';
  ppu_adr_out <= "00" & ppu_adr_in;
  ppu_data_nes <= ppu_data when (ppu_rd = '1') else "ZZZZZZZZ";
  ppu_data <= ppu_data_nes when (ppu_wr = '1') else "ZZZZZZZZ";
  cpu_data_nes <= cpu_data when (cpu_rw_in = '0') else "ZZZZZZZZ";
  cpu_data <= cpu_data_nes when (cpu_rw_in = '1') else "ZZZZZZZZ";
  
  -- read/write flags will need a delay on actual system and be synced with m2
  ppu_rw_out <= ppu_wr;
  cpu_rw_out <= cpu_rw_in;
  --update_rw : process(m2)
  --begin
  --	if rising_edge(m2) then
  --		ppu_rw_out <= ppu_wr;
  --		cpu_rw_out <= cpu_rw_in;
  --	end if;
  --end process;
end Behavioral;