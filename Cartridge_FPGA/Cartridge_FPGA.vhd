-- Copyright (C) 2023  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details, at
-- https://fpgasoftware.intel.com/eula.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 22.1std.2 Build 922 07/20/2023 SC Lite Edition"
-- CREATED		"Tue Nov 21 16:37:04 2023"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY Cartridge_FPGA IS 
	PORT
	(
		reset :  IN  STD_LOGIC;
		SCLK :  IN  STD_LOGIC;
		MOSI :  IN  STD_LOGIC;
		SS :  IN  STD_LOGIC;
		CLOCK_50 :  IN  STD_LOGIC;
		cpu_rw_nes :  IN  STD_LOGIC;
		m2 :  IN  STD_LOGIC;
		romsel :  IN  STD_LOGIC;
		cpu_adr_in :  IN  STD_LOGIC_VECTOR(14 DOWNTO 0);
		cpu_data_nes :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		ppu_adr_in :  IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
		ppu_data_nes :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		MISO :  OUT  STD_LOGIC;
		LOCKED :  OUT  STD_LOGIC
	);
END Cartridge_FPGA;

ARCHITECTURE bdf_type OF Cartridge_FPGA IS 

COMPONENT oc_mem
GENERIC (ADDRESS_BITS : INTEGER
			);
	PORT(clk : IN STD_LOGIC;
		 we : IN STD_LOGIC;
		 data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 read_address : IN INTEGER RANGE 0 to 65535;
		 write_address : IN INTEGER RANGE 0 to 65535;
		 data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT inout_mux
	PORT(rw_1 : IN STD_LOGIC;
		 rw_2 : IN STD_LOGIC;
		 sel : IN STD_LOGIC;
		 adr_1 : IN INTEGER RANGE 0 to 65535;
		 adr_2 : IN INTEGER RANGE 0 to 65535;
		 data_1_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 data_2_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 data_mem_out : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 rw_mem : OUT STD_LOGIC;
		 adr_mem : OUT INTEGER RANGE 0 to 65535;
		 data_1_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 data_2_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 data_mem_in : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT cart_pll
	PORT(areset : IN STD_LOGIC;
		 inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC;
		 locked : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT nes_input
	PORT(CLK : IN STD_LOGIC;
		 cpu_rw_in : IN STD_LOGIC;
		 ppu_rd : IN STD_LOGIC;
		 ppu_wr : IN STD_LOGIC;
		 m2 : IN STD_LOGIC;
		 romsel : IN STD_LOGIC;
		 cpu_adr_in : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
		 cpu_data_nes : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 cpu_data_out : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_adr_in : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
		 ppu_data_nes : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_data_out : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 cpu_rw_out : OUT STD_LOGIC;
		 ppu_rw_out : OUT STD_LOGIC;
		 cpu_adr_out : OUT INTEGER RANGE 0 to 65535;
		 cpu_data_in : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_adr_out : OUT INTEGER RANGE 0 to 65535;
		 ppu_data_in : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT spi_input
	PORT(CLK : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 SCLK : IN STD_LOGIC;
		 MOSI : IN STD_LOGIC;
		 SS : IN STD_LOGIC;
		 cpu_data_out : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_data_out : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 MISO : OUT STD_LOGIC;
		 ppu_rw : OUT STD_LOGIC;
		 cpu_rw : OUT STD_LOGIC;
		 sel_dev : OUT STD_LOGIC;
		 cpu_adr : OUT INTEGER RANGE 0 to 65535;
		 cpu_data_in : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_adr : OUT INTEGER RANGE 0 to 65535;
		 ppu_data_in : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	SYNTHESIZED_WIRE_37 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_38 : INTEGER RANGE 0 to 65535;
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_39 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_8 :  INTEGER RANGE 0 to 65535;
SIGNAL	SYNTHESIZED_WIRE_9 :  INTEGER RANGE 0 to 65535;
SIGNAL	SYNTHESIZED_WIRE_10 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_11 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_12 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_13 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_15 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_16 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_17 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_20 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_22 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_23 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_40 :  INTEGER RANGE 0 to 65535;
SIGNAL	SYNTHESIZED_WIRE_26 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_27 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_29 :  INTEGER RANGE 0 to 65535;
SIGNAL	SYNTHESIZED_WIRE_30 :  INTEGER RANGE 0 to 65535;
SIGNAL	SYNTHESIZED_WIRE_31 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_32 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_33 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_35 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_36 :  STD_LOGIC_VECTOR(7 DOWNTO 0);


BEGIN 
SYNTHESIZED_WIRE_15 <= '0';
SYNTHESIZED_WIRE_16 <= '0';



b2v_cpu_mem : oc_mem
GENERIC MAP(ADDRESS_BITS => 16
			)
PORT MAP(clk => SYNTHESIZED_WIRE_37,
		 we => SYNTHESIZED_WIRE_1,
		 data_in => SYNTHESIZED_WIRE_2,
		 read_address => SYNTHESIZED_WIRE_38,
		 write_address => SYNTHESIZED_WIRE_38,
		 data_out => SYNTHESIZED_WIRE_12);


b2v_cpu_mux : inout_mux
PORT MAP(rw_1 => SYNTHESIZED_WIRE_5,
		 rw_2 => SYNTHESIZED_WIRE_6,
		 sel => SYNTHESIZED_WIRE_39,
		 adr_1 => SYNTHESIZED_WIRE_8,
		 adr_2 => SYNTHESIZED_WIRE_9,
		 data_1_in => SYNTHESIZED_WIRE_10,
		 data_2_in => SYNTHESIZED_WIRE_11,
		 data_mem_out => SYNTHESIZED_WIRE_12,
		 rw_mem => SYNTHESIZED_WIRE_1,
		 adr_mem => SYNTHESIZED_WIRE_38,
		 data_1_out => SYNTHESIZED_WIRE_17,
		 data_2_out => SYNTHESIZED_WIRE_35,
		 data_mem_in => SYNTHESIZED_WIRE_2);




b2v_inst12 : cart_pll
PORT MAP(areset => SYNTHESIZED_WIRE_13,
		 inclk0 => CLOCK_50,
		 c0 => SYNTHESIZED_WIRE_37,
		 locked => LOCKED);


SYNTHESIZED_WIRE_13 <= NOT(reset);





b2v_nes_ctrl : nes_input
PORT MAP(CLK => SYNTHESIZED_WIRE_37,
		 cpu_rw_in => cpu_rw_nes,
		 ppu_rd => SYNTHESIZED_WIRE_15,
		 ppu_wr => SYNTHESIZED_WIRE_16,
		 m2 => m2,
		 romsel => romsel,
		 cpu_adr_in => cpu_adr_in,
		 cpu_data_nes => cpu_data_nes,
		 cpu_data_out => SYNTHESIZED_WIRE_17,
		 ppu_adr_in => ppu_adr_in,
		 ppu_data_nes => ppu_data_nes,
		 ppu_data_out => SYNTHESIZED_WIRE_20,
		 cpu_rw_out => SYNTHESIZED_WIRE_5,
		 ppu_rw_out => SYNTHESIZED_WIRE_26,
		 cpu_adr_out => SYNTHESIZED_WIRE_8,
		 cpu_data_in => SYNTHESIZED_WIRE_10,
		 ppu_adr_out => SYNTHESIZED_WIRE_29,
		 ppu_data_in => SYNTHESIZED_WIRE_31);


b2v_ppu_mem : oc_mem
GENERIC MAP(ADDRESS_BITS => 16
			)
PORT MAP(clk => SYNTHESIZED_WIRE_37,
		 we => SYNTHESIZED_WIRE_22,
		 data_in => SYNTHESIZED_WIRE_23,
		 read_address => SYNTHESIZED_WIRE_40,
		 write_address => SYNTHESIZED_WIRE_40,
		 data_out => SYNTHESIZED_WIRE_33);


b2v_ppu_mux : inout_mux
PORT MAP(rw_1 => SYNTHESIZED_WIRE_26,
		 rw_2 => SYNTHESIZED_WIRE_27,
		 sel => SYNTHESIZED_WIRE_39,
		 adr_1 => SYNTHESIZED_WIRE_29,
		 adr_2 => SYNTHESIZED_WIRE_30,
		 data_1_in => SYNTHESIZED_WIRE_31,
		 data_2_in => SYNTHESIZED_WIRE_32,
		 data_mem_out => SYNTHESIZED_WIRE_33,
		 rw_mem => SYNTHESIZED_WIRE_22,
		 adr_mem => SYNTHESIZED_WIRE_40,
		 data_1_out => SYNTHESIZED_WIRE_20,
		 data_2_out => SYNTHESIZED_WIRE_36,
		 data_mem_in => SYNTHESIZED_WIRE_23);


b2v_spi_ctrl : spi_input
PORT MAP(CLK => SYNTHESIZED_WIRE_37,
		 reset => reset,
		 SCLK => SCLK,
		 MOSI => MOSI,
		 SS => SS,
		 cpu_data_out => SYNTHESIZED_WIRE_35,
		 ppu_data_out => SYNTHESIZED_WIRE_36,
		 MISO => MISO,
		 ppu_rw => SYNTHESIZED_WIRE_27,
		 cpu_rw => SYNTHESIZED_WIRE_6,
		 sel_dev => SYNTHESIZED_WIRE_39,
		 cpu_adr => SYNTHESIZED_WIRE_9,
		 cpu_data_in => SYNTHESIZED_WIRE_11,
		 ppu_adr => SYNTHESIZED_WIRE_30,
		 ppu_data_in => SYNTHESIZED_WIRE_32);


END bdf_type;