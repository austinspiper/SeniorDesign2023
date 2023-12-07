LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY oc_mem IS
    PORT (
        clk: IN STD_LOGIC;
        data_in: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        write_address: IN INTEGER RANGE 0 to 65535;
        read_address: IN INTEGER RANGE 0 to 65535;
        we: IN STD_LOGIC;
        data_out: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END oc_mem;

ARCHITECTURE rtl OF oc_mem IS
    TYPE MEM IS ARRAY(0 TO ((2**15)-1)) OF STD_LOGIC_VECTOR(7 DOWNTO 0);  -- FPGA can support 65535 bytes RAM total, and we have 2 RAM instances
	 
	 FUNCTION initialize_ram
        return MEM is
        variable result : MEM;
    BEGIN 
        FOR i IN (2**15)-1 DOWNTO 0 LOOP
            result(i) := x"00";
        END LOOP; 
        RETURN result;
    END initialize_ram;
	 
    SIGNAL ram_block: MEM := initialize_ram;
BEGIN
    PROCESS (clk)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (we = '1') THEN
                ram_block(write_address) <= data_in;
            END IF;
            data_out <= ram_block(read_address); 
        END IF;
    END PROCESS;
END rtl;