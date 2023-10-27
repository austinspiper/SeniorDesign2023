LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY spi_slave IS
	PORT (
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
	SIGNAL shift_reg_out : STD_LOGIC_VECTOR(22 DOWNTO 0) := (OTHERS => '0');
	SIGNAL bit_counter : INTEGER := 0;

BEGIN

	-- SPI Mode 0, SS is used to sync data and prevent metastability issues
	PROCESS (RESET, SCLK, SS, DATA_IN)
	BEGIN
		IF RESET = '0' THEN
			shift_reg_in <= (OTHERS => '0');
			shift_reg_out <= DATA_IN(22 DOWNTO 0);
			MISO <= DATA_IN(23);
			DATA_OUT <= (OTHERS => '0'); -- Ensure DATA_OUT is reset
		ELSIF SS = '1' THEN
			shift_reg_out <= DATA_IN(22 DOWNTO 0);
			MISO <= DATA_IN(23);
			DATA_OUT <= shift_reg_in;
		ELSIF rising_edge(SCLK) AND SS = '0' THEN
			shift_reg_in <= shift_reg_in(22 DOWNTO 0) & MOSI;
			MISO <= shift_reg_out(22);
			shift_reg_out <= shift_reg_out(21 DOWNTO 0) & '0'; -- Shift right with zero padding (for this example)
		END IF;

	END PROCESS;

	-- Concurrent version
	--shift_reg_in <= (others => '0') when RESET = '0' else
	--					 (shift_reg_in(22 downto 0) & MOSI) when (rising_edge(SCLK) and SS = '0');
	--					 
	--shift_reg_out <= DATA_IN(22 downto 0) when (RESET = '0' or SS = '1') else
	--					(shift_reg_out(21 downto 0) & '0') when (rising_edge(SCLK) and SS = '0');
	--
	--MISO <= DATA_IN(23) when (RESET = '0' or SS = '1') else
	--		  shift_reg_out(22) when (rising_edge(SCLK) and SS = '0');
	--		  
	--DATA_OUT <= (others => '0') when RESET = '0' else
	--				shift_reg_in when SS = '1';

END Behavioral;