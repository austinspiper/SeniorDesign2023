library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

 
entity spi_input is
  port (
	 CLK : in std_logic := '0';
	 reset : in std_logic := '0';
	 S_SCLK : in std_logic := '0';
	 S_MOSI : in std_logic := '0';
	 s_MISO : out std_logic := '0';
    ppu_adr : out std_logic_vector(15 downto 0);
    cpu_adr : out std_logic_vector(15 downto 0);
	 ppu_data : inout std_logic_vector(7 downto 0);
	 cpu_data : inout std_logic_vector(7 downto 0);
    ppu_rw : out std_logic := '0';
	 cpu_rw : out std_logic := '0';
	 sel_dev : out std_logic := '0'
    );
end spi_input;
 
architecture Behavioral of spi_input is
  type s_state is (load_op, load_adr, load_len, load_data);
  type op_T is (write_cpu, write_ppu, read_cpu, read_ppu, toggle_write_prot, none);

  signal spi_state : s_state := load_op;
  
  signal s_din : std_logic_vector(7 downto 0) := x"00";
  signal s_din_vld : std_logic := '0';
  signal s_din_rdy : std_logic := '0';
  signal s_dout_vld : std_logic := '0';
  signal s_dout : std_logic_vector(7 downto 0);
  signal cpu_data_out : std_logic_vector(7 downto 0) := x"00";
  signal ppu_data_out : std_logic_vector(7 downto 0) := x"00";
  signal cpu_rw_int : std_logic := '0';
  signal ppu_rw_int : std_logic := '0';

begin
    cpu_data <= cpu_data_out when (cpu_rw_int = '1') else "ZZZZZZZZ";
    ppu_data <= ppu_data_out when (ppu_rw_int = '1') else "ZZZZZZZZ";
  
	 cpu_rw <= cpu_rw_int;
	 ppu_rw <= ppu_rw_int;
	 
	 handle_spi : process(CLK)
	 	type w_state is (lsb, msb);
	 
		variable len, adr : unsigned(15 downto 0) := x"0000";
		variable opcode : op_T := none;
		variable word_state : w_state := lsb;
		variable ready : boolean := true;
		variable write_proc : std_logic := '0';
	 begin
		cpu_rw_int <= '0';
		ppu_rw_int <= '0';
		s_din_vld <= '0';
		cpu_adr <= "ZZZZZZZZZZZZZZZZ";
		cpu_data <= "ZZZZZZZZ";
		 if (s_dout_vld = '1' and ready = true) then
			ready := false;
			case spi_state is
				when load_op =>
					case s_dout is
						when x"00" =>
							opcode := write_cpu;
							spi_state <= load_adr;
						when x"01" =>
							opcode := write_ppu;
							spi_state <= load_adr;
						when x"02" =>
							opcode := toggle_write_prot;
							write_proc := not(write_proc);
						when x"03" =>
							opcode := read_cpu;
							spi_state <= load_adr;
						when x"04" =>
							opcode := read_ppu;
							spi_state <= load_adr;
						when others =>
							opcode := none;
							spi_state <= load_op;
					end case;
				when load_adr =>
					if (word_state = lsb) then
						word_state := msb;
						adr(7 downto 0) := unsigned(s_dout);
					elsif (word_state = msb) then
						word_state := lsb;
						adr(15 downto 8) := unsigned(s_dout);
						spi_state <= load_len;
					end if;
				when load_len =>
					if (word_state = lsb) then
						word_state := msb;
						len(7 downto 0) := unsigned(s_dout);
					elsif (word_state = msb) then
						word_state := lsb;
						len(15 downto 8) := unsigned(s_dout);
						spi_state <= load_data;
					end if;
				when load_data =>
					if (opcode = write_cpu or opcode = write_ppu) then
						if (len = 0) then
							spi_state <= load_op;
							opcode := none;
						else
							if (opcode = write_cpu) then
								cpu_rw_int <= '1';
								cpu_adr <= std_logic_vector(adr);
								cpu_data_out <= s_dout;
							elsif (opcode = write_ppu) then
								ppu_rw_int <= '1';
								ppu_adr <= std_logic_vector(adr);
								ppu_data_out <= s_dout;
							end if;
							adr := adr + 1;
							len := len - 1;
							if (len = 0) then
								spi_state <= load_op;
								opcode := none;
							end if;
						end if;
					elsif (opcode = read_cpu or opcode = read_ppu) then
						if (len = 0) then
							spi_state <= load_op;
							opcode := none;
						else
							if (opcode = read_cpu) then
								cpu_rw_int <= '0';
								cpu_adr <= std_logic_vector(adr);
								s_din <= cpu_data;
								s_din_vld <= '1';
							elsif (opcode = read_ppu) then
								ppu_rw_int <= '0';
								ppu_adr <= std_logic_vector(adr);
								s_din <= ppu_data;
								s_din_vld <= '1';
							end if;
							adr := adr + 1;
							len := len - 1;
							if (len = 0) then
								spi_state <= load_op;
								opcode := none;
							end if;
						end if;
					end if;
			end case;
		 elsif (s_dout_vld = '0' and ready = false) then
			ready := true;
		 end if;
		 sel_dev <= write_proc;
	 end process;
	 
	 
	  slave_i : entity work.SPI_SLAVE
    port map (
        CLK      => CLK,
        RST      => reset,
        -- SPI MASTER INTERFACE
        SCLK     => S_SCLK,
        CS_N     => '0',
        MOSI     => S_MOSI,
        MISO     => s_MISO,
        -- USER INTERFACE
        DIN      => s_din,
        DIN_VLD  => s_din_vld,
        DIN_RDY  => s_din_rdy,
        DOUT     => s_dout,
        DOUT_VLD => s_dout_vld
    );
end Behavioral;