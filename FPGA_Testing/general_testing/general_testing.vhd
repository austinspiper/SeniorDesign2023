LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY general_testing IS
	PORT (
		CLK : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		S_SCLK : IN STD_LOGIC;
		S_MOSI : IN STD_LOGIC;
		S_MISO : OUT STD_LOGIC;
		S_SS : IN STD_LOGIC
	);
END general_testing;

ARCHITECTURE Behavioral OF general_testing IS
	TYPE s_state IS (load_op, load_adr, load_len, load_data);

	SIGNAL s_din : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"000000";
	SIGNAL s_dout : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"000000";
	SIGNAL ready : STD_LOGIC := '0';
	SIGNAL spi_state : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	SIGNAL adr : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	SIGNAL data : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	SIGNAL len : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	SIGNAL rw : STD_LOGIC := '0';

BEGIN

	test_proc : PROCESS (reset, S_SS)
	BEGIN
		IF (reset = '0') THEN
			spi_state <= "00";
		ELSIF (rising_edge(S_SS)) THEN
			CASE spi_state IS
				-- Loading data
				WHEN "00" =>
					spi_state <= "01";
				-- Loading Address
				WHEN "01" =>
					spi_state <= "00";
				-- Unreachable
				WHEN OTHERS =>
					spi_state <= "00";
			END CASE;
		END IF;
	END PROCESS;

	--Logic for debugging state
	--s_din <= x"010000" when spi_state = "00" else
	--			x"040000" when spi_state = "01" else
	--			x"100000" when spi_state = "10" else
	--			x"000000";
	
	-- Test logic, will accept 1 byte at a time from SPI (delimeted by SS)
	-- 1. First byte will be the address (MSb is read/write flag)
	-- 2. Second byte will be the data (Master sends 00 if read, but it doesn't really matter)
	-- 3. Repeat
	s_din <= x"000000" WHEN reset = '0' ELSE
		data & x"0000" WHEN S_SS = '1' ELSE
		s_din;
	adr <= x"00" WHEN reset = '0' ELSE
		'0' & s_dout(6 DOWNTO 0) WHEN spi_state = "01" AND S_SS = '1' ELSE
		adr;
	rw <= '0' WHEN reset = '0' ELSE
		s_dout(7) WHEN spi_state = "01" AND S_SS = '1' ELSE
		rw;
	data <= "ZZZZZZZZ" WHEN rw = '0' ELSE  -- Set data to high impedence to allow RAM logic to write to the signal
		x"00" WHEN reset = '0' ELSE
		s_dout(7 DOWNTO 0) WHEN spi_state = "00" AND S_SS = '1' ELSE
		data;

	slave_i : ENTITY work.SPI_SLAVE
		PORT MAP(
			RESET => reset,
			SCLK => S_SCLK,
			MOSI => S_MOSI,
			MISO => s_MISO,
			DATA_IN => s_din,
			DATA_OUT => s_dout,
			SS => S_SS
		);

	oc_mem : ENTITY work.os_mem
		PORT MAP(
			reset => reset,
			clk => CLK,
			data => data,
			addr => adr,
			we => rw
		);
END Behavioral;