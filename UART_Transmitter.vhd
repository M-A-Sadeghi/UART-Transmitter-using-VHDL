library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.All;

entity UART_Transmitter is
    Generic ( DATA_WIDTH         :   integer := 8;
              CLK_PER_BAUDRATE   :   integer := 1042);  -- 10000000/9600
    Port    ( Data_in            :   in  std_logic_vector(DATA_WIDTH-1 downto 0);
              clk, rst, tx_start :   in  std_logic;
              Tx, Tx_done        :   out std_logic);
end UART_Transmitter;

architecture Behavioral of UART_Transmitter is
    type state is (IDLE, START, DATA, PARITY, STOP);
    signal r_next, r_state   : state := IDLE;
    signal data_frame        : std_logic_vector (DATA_WIDTH-1 downto 0);
    signal counter_wait      : unsigned(15 downto 0) := (others => '0');
    signal sent_bits_counter : unsigned (3 downto 0) := (others => '0');
    signal Tx_temp           : std_logic := '1';
    signal Tx_done_temp      : std_logic := '0';
    signal temp              : std_logic_vector (DATA_WIDTH downto 0) := (others => '0');
begin
    state_register : process (clk, rst) is
    begin
        if (rst = '1') then 
            r_state <= IDLE;
        elsif (rising_edge(clk)) then
            r_state <= r_next;            
        end if;
    end process;
    
    combinational_logic : process (r_state, tx_start, counter_wait, sent_bits_counter) is
    begin
        case r_state is 
            when IDLE =>
                if (tx_start = '1') then
                    r_next <= START;
                else
                    r_next <= IDLE;
                end if;
            when START =>
                if(counter_wait < CLK_PER_BAUDRATE-1) then
                    r_next <= START;
                else
                    r_next <= DATA;
                end if;
            when DATA =>
                if(sent_bits_counter = DATA_WIDTH-1) then
                    if(counter_wait < CLK_PER_BAUDRATE-1) then 
                        r_next <= DATA;
                    else
                        r_next <= PARITY;
                    end if;
                else
                    r_next <= DATA;
                    
                end if;
            when PARITY =>
                if(counter_wait < CLK_PER_BAUDRATE-1) then
                    r_next <= PARITY;
                else
                    r_next <= STOP;
                end if;  
            when STOP =>
                if(counter_wait < CLK_PER_BAUDRATE-1) then
                    r_next <= STOP;
                else
                    r_next <= IDLE;
                end if; 
        end case;   
    end process;
    
    counter_wait_haldling : process(clk,rst) is
    begin
        if (rst = '1') then
            counter_wait <= (others => '0');
        elsif (rising_edge(clk)) then
            if (r_state = START) then
                if (counter_wait < CLK_PER_BAUDRATE-1) then
                    counter_wait <= counter_wait + 1;
                else
                    counter_wait <= (others => '0');
                end if;
            elsif (r_state = DATA) then
                if (counter_wait = CLK_PER_BAUDRATE-1) then
                    if ( sent_bits_counter = DATA_WIDTH-1 ) then
                            sent_bits_counter <= (others => '0');
                    else
                            sent_bits_counter <= sent_bits_counter + 1;                            
                    end if;
                    counter_wait <= (others => '0');                    
                else
                    counter_wait <= counter_wait + 1;
                end if;
            elsif (r_state = PARITY) then
                if (counter_wait < CLK_PER_BAUDRATE-1) then
                    counter_wait <= counter_wait + 1;
                else
                    counter_wait <= (others => '0');
                end if;
            elsif (r_state = STOP) then
                if (counter_wait < CLK_PER_BAUDRATE-1) then
                    counter_wait <= counter_wait + 1;
                else
                    counter_wait <= (others => '0');
                    sent_bits_counter <= (others => '0');                                   
                end if;
            else
                    counter_wait <= (others => '0');
            end if;
        end if;
    end process;
    
    outputs : process(clk) is
    begin
        if(rising_edge(clk)) then
            case r_state is
                when IDLE => 
                    Tx_temp <= '1';
                    Tx_done_temp <= Tx_done_temp;
                when START =>
                    data_frame <= Data_in;
                    Tx_temp <= '0';
                    Tx_done_temp <= '0';
                when DATA =>
                        Tx_temp <= data_frame(to_integer(sent_bits_counter));
                        Tx_done_temp <= '0';
                        for j in 0 to DATA_WIDTH-1 loop
                        temp(j+1) <= temp(j) xor Data_frame(j);
                    end loop;
                when PARITY => 
                    Tx_temp <= not temp(DATA_WIDTH);
                    Tx_done_temp <= '0';
                when STOP => 
                    Tx_temp <= '1';
                    if (counter_wait >= CLK_PER_BAUDRATE-1) then
                        Tx_done_temp <= '1';
                    end if;
            end case;
        end if;
    end process;
    Tx <= Tx_temp;
    Tx_done <= Tx_done_temp;
end Behavioral;
