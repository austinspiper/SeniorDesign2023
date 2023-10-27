LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY main_tb IS
END main_tb;

ARCHITECTURE Behavioral OF main_tb IS

	SIGNAL tb_ppu_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL tb_cpu_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL tb_ppu_adr : STD_LOGIC_VECTOR(13 DOWNTO 0);
	SIGNAL tb_cpu_adr : STD_LOGIC_VECTOR(14 DOWNTO 0);
	SIGNAL tb_m2 : STD_LOGIC := '0';
	SIGNAL tb_romsel : STD_LOGIC := '1';
	SIGNAL tb_ppu_rd : STD_LOGIC := '0';
	SIGNAL tb_ppu_wr : STD_LOGIC := '0';
	SIGNAL tb_cpu_rw : STD_LOGIC := '0';
	SIGNAL tb_reset : STD_LOGIC := '0';
	SIGNAL tb_S_SCLK : STD_LOGIC := '0';
	SIGNAL tb_S_MOSI : STD_LOGIC := '0';
	SIGNAL tb_S_MISO : STD_LOGIC := '0';
	CONSTANT ClockFrequency : INTEGER := 50e6; -- 50 MHz
	CONSTANT ClockPeriod : TIME := 1000 ms / ClockFrequency;

	CONSTANT m2ClockFrequency : INTEGER := 6e6; -- 6 MHz
	CONSTANT m2ClockPeriod : TIME := 1000 ms / m2ClockFrequency;
	SIGNAL tb_CLK : STD_LOGIC := '1';

BEGIN
	tb_CLK <= NOT tb_CLK AFTER ClockPeriod / 2;
	tb_m2 <= NOT tb_m2 AFTER m2ClockPeriod / 2;
	m : ENTITY work.system_test
		PORT MAP
		(
			CLOCK_50 => tb_CLK,
			reset => tb_reset,
			SCLK => tb_S_SCLK,
			MOSI => tb_S_MOSI,
			MISO => tb_S_MISO,
			ppu_adr_in => tb_ppu_adr,
			cpu_adr_in => tb_cpu_adr,
			ppu_data_nes => tb_ppu_data,
			cpu_data_nes => tb_cpu_data,
			m2 => tb_m2,
			romsel => tb_romsel,
			ppu_rd_nes => tb_ppu_rd,
			ppu_wr_nes => tb_ppu_wr,
			cpu_rw_nes => tb_cpu_rw
		);

	reset_proc : PROCESS
	BEGIN
		tb_reset <= '0';
		WAIT FOR 25 ns;
		tb_reset <= '1';
		WAIT;
	END PROCESS;

	tb_S_SCLK <= NOT tb_S_SCLK AFTER 25 ns;

	tb_proc : PROCESS
	BEGIN

		-- Write to PPU as NES
		tb_ppu_data <= "11001111";
		tb_ppu_adr <= (0 => '1', OTHERS => '0');
		tb_ppu_wr <= '1';

		-- Write to CPU as NES
		tb_cpu_data <= "11110011";
		tb_cpu_adr <= (0 => '1', OTHERS => '0');
		tb_cpu_rw <= '1';

		-- write_toggle
		FOR i IN 0 TO 5 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		tb_S_MOSI <= '0';
		WAIT FOR 50 ns;

		-- write_ppu
		FOR i IN 0 TO 6 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;

		-- adr 0000000000000001
		FOR i IN 0 TO 6 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;

		-- len 0000000000000001
		FOR i IN 0 TO 6 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '0';
		WAIT FOR 50 ns;

		-- data 01111111
		FOR i IN 0 TO 6 LOOP
			tb_S_MOSI <= '1';
			WAIT FOR 50 ns;
		END LOOP;

		-- read_ppu
		FOR i IN 0 TO 4 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		tb_S_MOSI <= '0';
		WAIT FOR 50 ns;
		tb_S_MOSI <= '0';
		WAIT FOR 50 ns;

		-- adr 0000000000000001
		FOR i IN 0 TO 6 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;

		-- len 0000000000000001
		FOR i IN 0 TO 6 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '0';
		WAIT FOR 50 ns;

		WAIT FOR 50 * 9 ns;

		-- write_toggle		
		FOR i IN 0 TO 5 LOOP
			tb_S_MOSI <= '0';
			WAIT FOR 50 ns;
		END LOOP;
		tb_S_MOSI <= '1';
		WAIT FOR 50 ns;
		tb_S_MOSI <= '0';
		WAIT FOR 50 ns;

		-- Write to PPU as NES
		tb_ppu_data <= "11000111";
		tb_ppu_adr <= (1 => '1', OTHERS => '0');
		tb_ppu_wr <= '1';

		-- Write to CPU as NES
		tb_cpu_data <= "11110011";
		tb_cpu_adr <= (1 => '1', OTHERS => '0');
		tb_cpu_rw <= '1';

		WAIT FOR 50 ns;
		-- Read from PPU as NES
		tb_ppu_data <= "ZZZZZZZZ";
		tb_ppu_adr <= (0 => '1', OTHERS => '0');
		tb_ppu_wr <= '0';
		tb_ppu_rd <= '1';
		WAIT FOR 50 ns;
		REPORT "Just Kidding.   Test Done." SEVERITY failure;
		WAIT;
	END PROCESS;

END Behavioral;