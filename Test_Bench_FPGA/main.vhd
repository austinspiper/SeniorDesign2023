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
			PPU inv_WR: out std_logic;
			PPU inv_RD: out std_logic;
			PPU inv_A13: out std_logic;
			
	
	);