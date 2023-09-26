library IEEE;
use IEEE.std_logic_1164.all;

entity CartridgeTB is

	port(
			-- CPU Data/Address Buses
			CPU_Address: out std_logic_vector(14 downto 0);
			CPU_Data: inout  std_logic_vector(7 downto 0);
			
			-- One-bit CPU Signals
			CPU_RW: out std_logic;
			M2: out std_logic; 
			
			
			-- PPU Data/Address Buses
			PPU_Address: out std_logic_vector(13 downto 0);
			PPU_Data: inout std_logic_vector(7 downto 0);
			
			-- One-bit PPU Signals
			PPU_inv_WR: out std_logic;
			PPU_inv_RD: out std_logic;
			PPU_inv_A13: out std_logic;
			
			-- Debug Signals
			step_clk: in std_logic; --Requests the next address on the cartridge
			reset: in std_logic;
			CPU_Data_View: out std_logic_vector(7 downto 0);
			PPU_Data_View: out std_logic_vector(7 downto 0);
			
			
			
			
			
	
	);
	
	architecture TB_Arch of CartridgeTB is
	
	begin
		
		type state_types is (startup, runtime);
		
		signal state: state_types := startup; -- Setting initial value of the state machine to "startup"
		
		move_to_next_address: process
			begin
				if rising_edge(step_clk) and state = runtime then
				
				elsif state = startup then
				
					CPU_Address <= X"00";
					PPU_Address <= X"00";
				
				
				end if
					