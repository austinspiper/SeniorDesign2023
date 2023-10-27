LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY os_mem IS
	GENERIC (
		ADDRESS_BITS : INTEGER := 8
	);
	PORT (
		data : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
		addr : IN STD_LOGIC_VECTOR(ADDRESS_BITS - 1 DOWNTO 0) := x"00";
		we : IN STD_LOGIC := '0';
		clk : IN STD_LOGIC := '0';
		reset : IN STD_LOGIC := '1'
	);
END os_mem;

ARCHITECTURE Behavioral OF os_mem IS

	--type mem_array is array((2**ADDRESS_BITS)-1 downto 0) of 
	TYPE mem_array IS ARRAY((2 ** 3) - 1 DOWNTO 0) OF  -- Reduced memory size to make testing easier
	STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL data_out : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	SIGNAL mem : mem_array := (OTHERS => (OTHERS => '0'));
BEGIN

	data <= data_out WHEN (we = '0') ELSE "ZZZZZZZZ";

	memory_proc : PROCESS (clk)
	BEGIN
		IF (reset = '0') THEN
			mem <= (OTHERS => (OTHERS => '0'));
		ELSIF rising_edge(clk) THEN
			IF (we = '0') THEN
				data_out <= mem(to_integer(unsigned(addr)));
			ELSIF (we = '1') THEN
				mem(to_integer(unsigned(addr))) <= data;
			END IF;
		END IF;
	END PROCESS;
END Behavioral;