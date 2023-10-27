LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY general_testing_tb IS
END general_testing_tb;

ARCHITECTURE Behavioral OF general_testing_tb IS

	SIGNAL tb_reset : STD_LOGIC := '0';
	SIGNAL tb_S_SS_n : STD_LOGIC;
	SIGNAL tb_S_SCLK : STD_LOGIC := '0';
	SIGNAL tb_S_MOSI : STD_LOGIC := '0';
	SIGNAL tb_S_MISO : STD_LOGIC := '0';
	CONSTANT ClockFrequency : INTEGER := 50e6; -- 50 MHz
	CONSTANT ClockPeriod : TIME := 1000 ms / ClockFrequency;
	SIGNAL tb_CLK : STD_LOGIC := '0';

	CONSTANT test_msg : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"FF81";  -- Write 0xFF to adr 1
	CONSTANT test_msg2 : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"5580";  -- Write 0x55 to adr 0 (To clear prev write from buses so read test is clean)
	CONSTANT test_msg3 : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0001";  -- Read from adr 1

BEGIN
	tb_CLK <= NOT tb_CLK AFTER ClockPeriod / 2;

	m : ENTITY work.general_testing
		PORT MAP
		(
			CLK => tb_CLK,
			reset => tb_reset,
			S_SCLK => tb_S_SCLK,
			S_MOSI => tb_S_MOSI,
			S_MISO => tb_S_MISO,
			S_SS => tb_S_SS_n
		);

	tb_proc : PROCESS
	BEGIN
		-- Issue reset
		tb_S_SS_n <= '1';
		tb_reset <= '0';
		WAIT FOR 25 ns;
		tb_reset <= '1';

		
		-- Start Send command byte
		tb_S_SS_n <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_SCLK <= '0';
			tb_S_MOSI <= test_msg(7 - i);
			WAIT FOR 25 ns;
			tb_S_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_S_SS_n <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		-- Start Send command byte
		tb_S_SS_n <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_SCLK <= '0';
			tb_S_MOSI <= test_msg(15 - i); -- MSB
			WAIT FOR 25 ns;
			tb_S_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_S_SS_n <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		
		
		-- Start Send command byte
		tb_S_SS_n <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_SCLK <= '0';
			tb_S_MOSI <= test_msg2(7 - i);
			WAIT FOR 25 ns;
			tb_S_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_S_SS_n <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		-- Start Send command byte
		tb_S_SS_n <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_SCLK <= '0';
			tb_S_MOSI <= test_msg2(15 - i);  -- MSB
			WAIT FOR 25 ns;
			tb_S_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_S_SS_n <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		
		
		-- Start Send command byte
		tb_S_SS_n <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_SCLK <= '0';
			tb_S_MOSI <= test_msg3(7 - i);
			WAIT FOR 25 ns;
			tb_S_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_S_SS_n <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		-- Start Send command byte
		tb_S_SS_n <= '0';
		WAIT FOR 8 ns;
		FOR i IN 0 TO 7 LOOP
			tb_S_SCLK <= '0';
			tb_S_MOSI <= test_msg3(15 - i);  -- MSB
			WAIT FOR 25 ns;
			tb_S_SCLK <= '1';
			WAIT FOR 25 ns;
		END LOOP;
		WAIT FOR 8 ns;
		tb_S_SS_n <= '1';
		WAIT FOR 8 ns;
		WAIT FOR 40 ns;
		-- End Send command byte
		
		
		WAIT FOR 100 ns;
		REPORT "Just Kidding.   Test Done." SEVERITY failure;
		WAIT;
	END PROCESS;

END Behavioral;