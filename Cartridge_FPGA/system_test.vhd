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
-- CREATED		"Sun Oct 15 13:33:09 2023"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY system_test IS 
	PORT
	(
		ppu_rd_nes :  IN  STD_LOGIC;
		CLOCK_50 :  IN  STD_LOGIC;
		reset :  IN  STD_LOGIC;
		SCLK :  IN  STD_LOGIC;
		MOSI :  IN  STD_LOGIC;
		MISO : OUT STD_LOGIC;
		romsel :  IN  STD_LOGIC;
		m2 :  IN  STD_LOGIC;
		ppu_wr_nes :  IN  STD_LOGIC;
		cpu_rw_nes :  IN  STD_LOGIC;
		cpu_adr_in :  IN  STD_LOGIC_VECTOR(14 DOWNTO 0);
		cpu_data_nes :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		ppu_adr_in :  IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
		ppu_data_nes :  INOUT  STD_LOGIC_VECTOR(7 DOWNTO 0);
		spi_dbg : OUT STD_LOGIC
	);
END system_test;

ARCHITECTURE bdf_type OF system_test IS 

COMPONENT nes_input
	PORT(CLK : IN STD_LOGIC;
		 cpu_rw_in : IN STD_LOGIC;
		 ppu_rd : IN STD_LOGIC;
		 ppu_wr : IN STD_LOGIC;
		 m2 : IN STD_LOGIC;
		 romsel : IN STD_LOGIC;
		 cpu_adr_in : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
		 cpu_data : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 cpu_data_nes : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_adr_in : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
		 ppu_data : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_data_nes : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 cpu_rw_out : OUT STD_LOGIC;
		 ppu_rw_out : OUT STD_LOGIC;
		 cpu_adr_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 ppu_adr_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT spi_input
	PORT(CLK : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 S_SCLK : IN STD_LOGIC;
		 S_MOSI : IN STD_LOGIC;
		 S_MISO : OUT STD_LOGIC;
		 cpu_data : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_data : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 ppu_rw : OUT STD_LOGIC;
		 cpu_rw : OUT STD_LOGIC;
		 sel_dev : OUT STD_LOGIC;
		 cpu_adr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		 ppu_adr : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT system_pll
	PORT(inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT inout_mux
	PORT(rw_1 : IN STD_LOGIC;
		 rw_2 : IN STD_LOGIC;
		 sel : IN STD_LOGIC;
		 adr_1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 adr_2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 data_1 : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 data_2 : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 data_mem : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 rw_mem : OUT STD_LOGIC;
		 adr_mem : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT oc_mem
GENERIC (ADDRESS_BITS : INTEGER
			);
	PORT(we : IN STD_LOGIC;
		 clk : IN STD_LOGIC;
		 addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		 data : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 reset : IN STD_LOGIC
	);
END COMPONENT;

SIGNAL	gdfx_temp0 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	gdfx_temp1 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	gdfx_temp2 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	gdfx_temp3 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	gdfx_temp4 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	gdfx_temp5 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_18 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_19 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_10 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_11 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_12 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_14 :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_15 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_17 :  STD_LOGIC_VECTOR(15 DOWNTO 0);


BEGIN 



b2v_inst : nes_input
PORT MAP(CLK => CLOCK_50,
		 cpu_rw_in => cpu_rw_nes,
		 ppu_rd => ppu_rd_nes,
		 ppu_wr => ppu_wr_nes,
		 m2 => m2,
		 romsel => romsel,
		 cpu_adr_in => cpu_adr_in,
		 cpu_data => gdfx_temp1,
		 cpu_data_nes => cpu_data_nes,
		 ppu_adr_in => ppu_adr_in,
		 ppu_data => gdfx_temp0,
		 ppu_data_nes => ppu_data_nes,
		 cpu_rw_out => SYNTHESIZED_WIRE_7,
		 ppu_rw_out => SYNTHESIZED_WIRE_2,
		 cpu_adr_out => SYNTHESIZED_WIRE_10,
		 ppu_adr_out => SYNTHESIZED_WIRE_5);


b2v_inst2 : spi_input
PORT MAP(CLK => CLOCK_50,
		 reset => reset,
		 S_SCLK => SCLK,
		 S_MOSI => MOSI,
		 S_MISO => MISO,
		 cpu_data => gdfx_temp5,
		 ppu_data => gdfx_temp3,
		 ppu_rw => SYNTHESIZED_WIRE_3,
		 cpu_rw => SYNTHESIZED_WIRE_8,
		 sel_dev => SYNTHESIZED_WIRE_19,
		 cpu_adr => SYNTHESIZED_WIRE_11,
		 ppu_adr => SYNTHESIZED_WIRE_6);


b2v_inst3 : system_pll
PORT MAP(inclk0 => CLOCK_50,
		 c0 => SYNTHESIZED_WIRE_18);


b2v_inst6 : inout_mux
PORT MAP(rw_1 => SYNTHESIZED_WIRE_2,
		 rw_2 => SYNTHESIZED_WIRE_3,
		 sel => SYNTHESIZED_WIRE_19,
		 adr_1 => SYNTHESIZED_WIRE_5,
		 adr_2 => SYNTHESIZED_WIRE_6,
		 data_1 => gdfx_temp0,
		 data_2 => gdfx_temp3,
		 data_mem => gdfx_temp2,
		 rw_mem => SYNTHESIZED_WIRE_12,
		 adr_mem => SYNTHESIZED_WIRE_14);


b2v_inst71 : inout_mux
PORT MAP(rw_1 => SYNTHESIZED_WIRE_7,
		 rw_2 => SYNTHESIZED_WIRE_8,
		 sel => SYNTHESIZED_WIRE_19,
		 adr_1 => SYNTHESIZED_WIRE_10,
		 adr_2 => SYNTHESIZED_WIRE_11,
		 data_1 => gdfx_temp1,
		 data_2 => gdfx_temp5,
		 data_mem => gdfx_temp4,
		 rw_mem => SYNTHESIZED_WIRE_15,
		 adr_mem => SYNTHESIZED_WIRE_17);


b2v_inst8 : oc_mem
GENERIC MAP(ADDRESS_BITS => 16
			)
PORT MAP(we => SYNTHESIZED_WIRE_12,
		 clk => CLOCK_50,
		 addr => SYNTHESIZED_WIRE_14,
		 data => gdfx_temp2,
		 reset => reset);


b2v_inst9 : oc_mem
GENERIC MAP(ADDRESS_BITS => 16
			)
PORT MAP(we => SYNTHESIZED_WIRE_15,
		 clk => CLOCK_50,
		 addr => SYNTHESIZED_WIRE_17,
		 data => gdfx_temp4,
		 reset => reset);


END bdf_type;