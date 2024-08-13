library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_Transmitter_tb is
end UART_Transmitter_tb;

architecture Behavioral of UART_Transmitter_tb is

    COMPONENT UART_Transmitter
        Generic ( DATA_WIDTH         :   integer := 8;
                  CLK_PER_BAUDRATE   :   integer := 1042); 
        Port    ( Data_in            :   in  std_logic_vector(DATA_WIDTH-1 downto 0);
                  clk, rst, tx_start :   in  std_logic;
                  Tx, Tx_done        :   out std_logic);
    END COMPONENT;
 
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal Tx_start : std_logic := '0';
   signal Data_in : std_logic_vector(7 downto 0) := (others => '0');
   signal Tx, Tx_done : std_logic;
   
   constant clk_period : time := 100 ns;
 
BEGIN
    Tx_block: UART_Transmitter PORT MAP (
          clk => clk,
          rst => rst,
          Data_in => Data_in,
          tx_start => tx_start,
          Tx => Tx,
          Tx_done => Tx_done
    );
    
   clk_process :process
      begin
        clk <= '0';
      wait for clk_period/2;
      clk <= '1';
      wait for clk_period/2;
  end process;

   stim_proc: process
  begin  
          rst <= '1';
          tx_start <= '0';
          Data_in <= "01010101";
          wait for clk_period;
            rst <= '0';
          wait for clk_period;
            tx_start <= '1';
          wait;
       end process;

end Behavioral;
