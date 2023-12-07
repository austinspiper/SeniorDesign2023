LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY spi_input IS
	PORT (
		CLK : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		SCLK : IN STD_LOGIC;
		MOSI : IN STD_LOGIC;
		MISO : OUT STD_LOGIC;
		SS : IN STD_LOGIC;
		ppu_adr : out INTEGER RANGE 0 to 65535;
		cpu_adr : out INTEGER RANGE 0 to 65535;
		ppu_data_in : out std_logic_vector(7 downto 0);
		ppu_data_out : in std_logic_vector(7 downto 0);
		cpu_data_in : out std_logic_vector(7 downto 0);
		cpu_data_out : in std_logic_vector(7 downto 0);
		ppu_rw : out std_logic := '0';
		cpu_rw : out std_logic := '0';
		sel_dev : out std_logic := '0'
	);
END spi_input;

ARCHITECTURE Behavioral OF spi_input IS
	TYPE state_T IS (load_op, load_len, load_data);
	type op_T is (write_cpu, write_ppu, read_cpu, read_ppu, toggle_write_prot, none);

	SIGNAL write_proc : std_logic := '0';
	SIGNAL din : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"000000";
	SIGNAL dout : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"000000";
	SIGNAL spi_state : state_T := load_op;
	SIGNAL opcode : op_T := none;
	SIGNAL adr_int : INTEGER RANGE 0 to 65535 := 16#0000#;
	SIGNAL len : INTEGER RANGE 0 to 65535 := 16#0000#;
	
	SIGNAL SS_sync, SS_sync_prev: STD_LOGIC := '0';

BEGIN

	PROCESS(reset, CLK)
	BEGIN
		IF reset = '0' THEN
			SS_sync <= '1';
			SS_sync_prev <= '1';
		ELSIF rising_edge(CLK) THEN
			SS_sync_prev <= SS_sync;
			SS_sync <= SS;
		END IF;
   END PROCESS;
	

	test_proc : PROCESS (reset, CLK, SS_sync, SS_sync_prev)
	BEGIN
		IF (reset = '0') THEN
			opcode <= none;
			spi_state <= load_op;
			adr_int <= 16#0000#;
			len <= 16#0000#;
			write_proc <= '0';
		ELSIF rising_edge(CLK) AND SS_sync = '1' AND SS_sync_prev = '0' THEN
			CASE spi_state IS
				-- Loading data
				WHEN load_op =>
					case dout(7 DOWNTO 0) is
						when x"00" =>
							opcode <= write_cpu;
							spi_state <= load_len;
							adr_int <= to_integer(unsigned(dout(23 DOWNTO 8)));
						when x"01" =>
							opcode <= write_ppu;
							spi_state <= load_len;
							adr_int <= to_integer(unsigned(dout(23 DOWNTO 8)));
						when x"02" =>
							opcode <= toggle_write_prot;
							write_proc <= not(write_proc);
							spi_state <= load_op;
						when x"03" =>
							opcode <= read_cpu;
							spi_state <= load_len;
							adr_int <= to_integer(unsigned(dout(23 DOWNTO 8)));
						when x"04" =>
							opcode <= read_ppu;
							spi_state <= load_len;
							adr_int <= to_integer(unsigned(dout(23 DOWNTO 8)));
						when others =>
							opcode <= none;
							spi_state <= load_op;
					end case;
				-- Loading Address
				WHEN load_len =>
					spi_state <= load_data;
					len <= to_integer(unsigned(dout(15 DOWNTO 0)));
				WHEN load_data =>
					if (len = 1) then
						spi_state <= load_op;
						opcode <= none;
					else
						adr_int <= adr_int + 1;
						len <= len - 1;
					end if;
				-- Unreachable
				WHEN OTHERS =>
					spi_state <= load_op;
					opcode <= none;
			END CASE;
		END IF;
	END PROCESS;
	
	sel_dev <= write_proc;
	
	din <= ppu_data_out & x"0000" WHEN opcode = read_ppu ELSE
			 cpu_data_out & x"0000" WHEN opcode = read_cpu ELSE
			(others => '-');
	ppu_data_in <= dout(7 DOWNTO 0) WHEN spi_state = load_data AND opcode = write_ppu ELSE (OTHERS => '-');
	cpu_data_in <= dout(7 DOWNTO 0) WHEN spi_state = load_data AND opcode = write_cpu ELSE (OTHERS => '-');
	
	ppu_rw <= '1' WHEN opcode = write_ppu AND spi_state = load_data ELSE '0';
	cpu_rw <= '1' WHEN opcode = write_cpu AND spi_state = load_data ELSE '0';
	
	cpu_adr <= adr_int;
	ppu_adr <= adr_int;

	slave_i : ENTITY work.SPI_SLAVE
		PORT MAP(
			CLK => CLK,
			RESET => reset,
			SCLK => SCLK,
			MOSI => MOSI,
			MISO => MISO,
			DATA_IN => din,
			DATA_OUT => dout,
			SS => SS
		);
END Behavioral;