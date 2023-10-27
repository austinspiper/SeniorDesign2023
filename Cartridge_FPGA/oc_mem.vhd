library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity oc_mem is
    generic (
        ADDRESS_BITS : integer := 16
    );
    Port ( 
        data : inout std_logic_vector(7 downto 0) := x"00";
        addr : in std_logic_vector(ADDRESS_BITS-1 downto 0) := x"0000";
        we : in std_logic := '0';
        clk : in std_logic := '0';
		  reset : in std_logic := '1'
        );
end oc_mem;

architecture Behavioral of oc_mem is
    --type mem_array is array((2**ADDRESS_BITS)-1 downto 0) of 
	 type mem_array is array((2**3)-1 downto 0) of  -- Reduced memory size to make testing easier
        std_logic_vector(7 downto 0);
        
    signal data_out : std_logic_vector(7 downto 0) := x"00";
begin
    data <= data_out when (we = '0') else "ZZZZZZZZ";
        
    memory_proc : process(clk, reset) 
		variable mem : mem_array := (others=>(others=>'0'));
    begin
			if (reset = '0') then
				data_out <= x"00";
				mem := (others=>(others=>'0'));
			elsif rising_edge(clk) then 
            if (we = '0') then
					 data_out <= mem(to_integer(unsigned(addr)));
            elsif (we = '1') then
                mem(to_integer(unsigned(addr))) := data;
            end if;
        end if;
    end process;
end Behavioral;