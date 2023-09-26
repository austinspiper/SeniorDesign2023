library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Test_Bench_FPGA is
	port (
			-- CPU Data/Address Buses
			CPU_Address: out std_logic_vector(14 downto 0);
			CPU_Data: inout  std_logic_vector(7 downto 0);
			
			-- One-bit CPU Signals
			CPU_RW: out std_logic := '1';
			M2: out std_logic := '0'; 
			
			
			-- PPU Data/Address Buses
			PPU_Address: out std_logic_vector(13 downto 0);
			PPU_Data: inout std_logic_vector(7 downto 0);
			
			-- One-bit PPU Signals
			PPU_inv_WR: out std_logic := '1';
			PPU_inv_RD: out std_logic := '0';
			-- PPU_inv_A13: out std_logic;
			
			-- Debug Signals
			step_clk: in std_logic; --Requests the next address on the cartridge
 			reset: in std_logic;
			CPU_Data_View: out std_logic_vector(7 downto 0);
			PPU_Data_View: out std_logic_vector(7 downto 0)
	
	);
end Test_Bench_FPGA;
	
architecture TB_Arch of Test_Bench_FPGA is
	
	type state_types is (STARTUP, RUNTIME);
	
	signal state: state_types := STARTUP; -- Setting initial value of the state machine to "startup"
	signal CPU_Address_Buffer: std_logic_vector(14 downto 0);
	signal PPU_Address_Buffer: std_logic_vector(13 downto 0);
	
	begin
	
		move_to_next_address: process(step_clk, reset)
		begin
				if (rising_edge(step_clk)) and (state = runtime) then
				
					CPU_Address_Buffer <= std_logic_vector( unsigned(CPU_Address_Buffer) + 1 );
					CPU_Address <= CPU_Address_Buffer;
				
					PPU_Address_Buffer <= std_logic_vector( unsigned(PPU_Address_Buffer) + 1 );
					PPU_Address <= PPU_Address_Buffer;
					
				end if;
				
				if (state = startup) or (reset = '1') then
					
					CPU_Address_Buffer <= "000000000000000";
					CPU_Address <= CPU_Address_Buffer;
					PPU_Address_Buffer <= "00000000000000";
					PPU_Address <= PPU_Address_Buffer;
				
					state <= runtime;
				
				end if;
				
			end process;
				
			
				
end TB_Arch;
				