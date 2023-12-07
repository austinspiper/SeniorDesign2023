LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY spi_slave IS
	PORT (
		CLK : IN STD_LOGIC;
		SCLK : IN STD_LOGIC;
		MISO : OUT STD_LOGIC;
		MOSI : IN STD_LOGIC;
		SS : IN STD_LOGIC;
		RESET : IN STD_LOGIC;
		DATA_IN : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
		DATA_OUT : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
	);
END spi_slave;

ARCHITECTURE Behavioral OF spi_slave IS

	SIGNAL shift_reg_in : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
	SIGNAL shift_reg_out : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
	
   SIGNAL sclk_sync, mosi_sync, ss_sync: STD_LOGIC := '0';
   SIGNAL sclk_sync_prev: STD_LOGIC := '0';

BEGIN

	PROCESS(RESET, CLK)
	BEGIN
		IF reset = '0' THEN
			ss_sync <= '1';
			sclk_sync_prev <= '0';
			sclk_sync <= '0';
			mosi_sync <= '0';
		ELSIF rising_edge(CLK) THEN
			-- First stage of synchronization
			sclk_sync_prev <= sclk_sync;
			sclk_sync <= SCLK;
			mosi_sync <= MOSI;
			ss_sync <= SS;
		END IF;
    END PROCESS;

	-- SPI Mode 0, SS is used to sync data and prevent metastability issues
	PROCESS (RESET, CLK, SCLK, SS, DATA_IN)
	BEGIN
		IF RESET = '0' THEN
			shift_reg_in <= (OTHERS => '0');
			shift_reg_out <= DATA_IN(23 DOWNTO 0);
			MISO <= DATA_IN(23);
		ELSIF ss_sync = '1' THEN
			shift_reg_out <= DATA_IN(23 DOWNTO 0);
			MISO <= DATA_IN(23);
		ELSIF rising_edge(CLK) AND sclk_sync_prev = '0' AND sclk_sync = '1' AND ss_sync = '0' THEN
			shift_reg_in <= shift_reg_in(22 DOWNTO 0) & mosi_sync;
			DATA_OUT <= shift_reg_in(22 DOWNTO 0) & mosi_sync;
			MISO <= shift_reg_out(23);
			shift_reg_out <= shift_reg_out(22 DOWNTO 0) & '0'; -- Shift right with zero padding (for this example)
		ELSE
			MISO <= shift_reg_out(23);
			shift_reg_in <= shift_reg_in;
			shift_reg_out <= shift_reg_out;
		END IF;

	END PROCESS;

END Behavioral;
