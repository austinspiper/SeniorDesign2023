LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY testbench IS
END testbench;

ARCHITECTURE Behavioral OF testbench IS

	SIGNAL tb_ppu_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL tb_cpu_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL tb_ppu_adr : STD_LOGIC_VECTOR(13 DOWNTO 0);
	SIGNAL tb_cpu_adr : STD_LOGIC_VECTOR(14 DOWNTO 0);
	SIGNAL tb_m2 : STD_LOGIC := '0';
	SIGNAL tb_romsel : STD_LOGIC := '1';
	SIGNAL tb_ppu_rd : STD_LOGIC := '0';
	SIGNAL tb_ppu_wr : STD_LOGIC := '0';
	SIGNAL tb_cpu_rw : STD_LOGIC := '0';
	SIGNAL tb_reset : STD_LOGIC := '1';
	
	SIGNAL tb_SCLK : STD_LOGIC := '0';
	SIGNAL tb_MOSI : STD_LOGIC := '0';
	SIGNAL tb_MISO : STD_LOGIC := '0';
	SIGNAL tb_SS : STD_LOGIC := '1';
	SIGNAL tb_LOCKED : STD_LOGIC := '0';
	CONSTANT ClockFrequency : INTEGER := 50e6; -- 50 MHz
	CONSTANT ClockPeriod : TIME := 1000 ms / ClockFrequency;

	CONSTANT m2ClockFrequency : INTEGER := 6e6; -- 6 MHz
	CONSTANT m2ClockPeriod : TIME := 1000 ms / m2ClockFrequency;
	SIGNAL tb_CLK : STD_LOGIC := '1';
	
	CONSTANT msg_toggle_sel : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"02";  -- Write Toggle
	
	TYPE generic_array_type IS ARRAY (NATURAL RANGE <>) OF std_logic_vector(7 DOWNTO 0);


	PROCEDURE Initialize_Array(variable Arr : out generic_array_type) IS
	BEGIN
		 FOR i IN 0 TO 256 LOOP
			  Arr(i) := std_logic_vector(to_unsigned(i mod 256, 8));
		 END LOOP;
	END PROCEDURE Initialize_Array;
	
	PROCEDURE Initialize_Array0(variable Arr : out generic_array_type) IS
	BEGIN
		 FOR i IN 0 TO 256 LOOP
			  Arr(i) := (OTHERS => '0');
		 END LOOP;
	END PROCEDURE Initialize_Array0;

-- This is a model of the super slow custom software based SPI implementation I am running on the Pico
PROCEDURE Send_Command(signal SCLK : out STD_LOGIC; signal MOSI : out STD_LOGIC; signal MISO : in STD_LOGIC; signal SS : out STD_LOGIC; variable buffer_in : in generic_array_type; variable buffer_out : out generic_array_type; constant cnt : in integer RANGE 0 to 65535; constant commit : in boolean) IS
BEGIN
    SS <= '0';
    WAIT FOR 1.9 us;
	 FOR i IN 0 TO (cnt-1) LOOP
		 FOR b IN 0 TO 7 LOOP
			  SCLK <= '0';
			  WAIT FOR 3.3 us;
			  MOSI <= buffer_in(i)(7 - b);
			  WAIT FOR 1 us;
			  buffer_out(i)(7 - b) := MISO;
			  --WAIT FOR (5.2-3.3-1) us;
			  WAIT FOR 0.9 us;
			  SCLK <= '1';
			  WAIT FOR 2 us;
		 END LOOP;
		 if (commit = true and i < (cnt-1)) then
			WAIT FOR 1 us;
			SS <= '1';
			WAIT FOR 800 ns;
			SS <= '0';
			WAIT FOR 1.9 us;
		 end if;
	 END LOOP;
    SS <= '1';
	 WAIT FOR 800 ns;
END PROCEDURE Send_Command;

PROCEDURE Write_Data(signal SCLK : out STD_LOGIC; signal MOSI : out STD_LOGIC; signal MISO : in STD_LOGIC; signal SS : out STD_LOGIC; variable buffer_in : in generic_array_type; variable buffer_out : out generic_array_type; constant adr : in integer RANGE 0 to 65535; constant len : in integer RANGE 0 to 65535; constant cpu : in boolean; constant wr : in boolean) IS
	
	variable adr_uvec : std_logic_vector(15 DOWNTO 0) := x"0000";
	variable len_uvec : std_logic_vector(15 DOWNTO 0) := x"0000";
	variable op_vec : generic_array_type(0 TO 2);
	variable len_vec : generic_array_type(0 TO 1);
BEGIN
	adr_uvec := std_logic_vector(to_unsigned(adr, 16));
	len_uvec := std_logic_vector(to_unsigned(len, 16));
	op_vec(0) := adr_uvec(15 DOWNTO 8);
	op_vec(1) := adr_uvec(7 DOWNTO 0);
	if (cpu = true) then
		if (wr = true) then
			op_vec(2) := x"00";
		else
			op_vec(2) := x"03";
		end if;
	else
		if (wr = true) then
			op_vec(2) := x"01";
		else
			op_vec(2) := x"04";
		end if;
	end if;
	len_vec(0) := len_uvec(15 DOWNTO 8);
	len_vec(1) := len_uvec(7 DOWNTO 0);
	Send_Command(SCLK, MOSI, MISO, SS, op_vec, buffer_out, 3, false);
	Send_Command(SCLK, MOSI, MISO, SS, len_vec, buffer_out, 2, false);
	Send_Command(SCLK, MOSI, MISO, SS, buffer_in, buffer_out, len, true);
END PROCEDURE Write_Data;

BEGIN
	tb_CLK <= NOT tb_CLK AFTER ClockPeriod / 2;
	tb_m2 <= NOT tb_m2 AFTER m2ClockPeriod / 2;
	main : ENTITY work.Cartridge_FPGA
		PORT MAP
		(
			CLOCK_50 => tb_CLK,
			reset => tb_reset,
			ppu_adr_in => tb_ppu_adr,
			cpu_adr_in => tb_cpu_adr,
			cpu_rw_nes => tb_cpu_rw,
		--	ppu_rd_nes => tb_ppu_rd,
		--	ppu_wr_nes => tb_ppu_wr,
			m2 => tb_m2,
			romsel => tb_romsel,
			SCLK => tb_SCLK,
			MOSI => tb_MOSI,
			SS => tb_SS,
			MISO => tb_MISO,
			LOCKED => tb_LOCKED,
			ppu_data_nes => tb_ppu_data,
			cpu_data_nes => tb_cpu_data
		);

	tb_proc : PROCESS
		variable buffer_in : generic_array_type(0 TO 256);
		variable buffer_out : generic_array_type(0 TO 256);
	BEGIN
		tb_SS <= '1';
		tb_reset <= '0';
		WAIT FOR 25 ns;
		tb_reset <= '1';
		-- Start Send command byte
		tb_SS <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_SCLK <= '0';
			tb_MOSI <= msg_toggle_sel(7 - i);
			WAIT FOR 25 ns;
			tb_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_SS <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		
		Initialize_Array0(buffer_out);
		Initialize_Array(buffer_in);
		Write_Data(tb_SCLK, tb_MOSI, tb_MISO, tb_SS, buffer_in, buffer_out, 0, 256, true, true);


		REPORT "Just Kidding.   Test Done." SEVERITY failure;
		WAIT;
	END PROCESS;

END Behavioral;