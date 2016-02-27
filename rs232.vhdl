library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

ENTITY rs232 IS
PORT(
	CLOCK_50: IN STD_LOGIC; 		--pin 17
	KEY: IN STD_LOGIC;  				--pin144
	UART_TX: OUT STD_LOGIC;			--pin96
	UART_RX: IN STD_LOGIC;			--pin97
	LED: inOUT STD_LOGIC;				--pin3
  commands : out axisCommands;
  reset : in std_logic;
  throttleCmd : out throttleType
); 

END rs232;


ARCHITECTURE MAIN OF rs232 IS
	SIGNAL TX_DATA: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL TX_START: STD_LOGIC := '0';
	SIGNAL TX_BUSY: STD_LOGIC;
	
	SIGNAL RX_BUSY: STD_LOGIC;

  signal stByte : std_logic;
  
  signal tmp : std_logic_vector(7 downto 0);

  signal data : std_logic_vector(7 downto 0);


	COMPONENT TX
		PORT( 
			CLK: IN STD_LOGIC; 
			START: IN STD_LOGIC;
			BUSY: OUT STD_LOGIC;
			DATA: IN STD_LOGIC_VECTOR(7 downto 0); 
			TX_LINE: BUFFER STD_LOGIC 
		);
	END COMPONENT TX;
	
	COMPONENT RX
		PORT(
			CLK: IN STD_LOGIC; 
			BUSY: OUT STD_LOGIC;
			DATA: OUT STD_LOGIC_VECTOR(7 downto 0); 
			RX_LINE: IN STD_LOGIC 
		); 
	END COMPONENT RX;
	
	BEGIN
	TRANSMIT_DATA: TX PORT MAP (CLOCK_50, TX_START, TX_BUSY, TX_DATA, UART_TX);
	RECEIVE_DATA: RX PORT MAP (CLOCK_50, RX_BUSY, data, UART_RX);
	
	
	PROCESS(RX_BUSY, reset)
	BEGIN
    if reset = '1' then
      commands <= (others => to_signed(0, 16));
      throttleCmd <= to_unsigned(0, 16);
	elsIF (RX_BUSY'EVENT AND RX_BUSY = '0') THEN
    if stByte = '1' then
      if data(7 downto 6) = "11" then
        tmp <= data;
        stByte <= '0';
      end if;
    else
      stByte <= '1';
      if data(7 downto 6) = "10" then
        case to_integer(signed(data(5 downto 4))) is
          when ROLL =>
            -- commands(ROLL) <= to_signed(0, 16);
            commands(ROLL) <= (6 downto 0 => data(3)) & signed(data(2 downto 0)) & signed(tmp(5 downto 0));
            -- commands(ROLL) <= shift_left(resize(signed((signed(tmp(3 downto 0)) & signed(data(5 downto 0))) - 500), 16), 6);
          when PITCH =>
            -- commands(PITCH) <= to_signed(0, 16);
            commands(PITCH) <= (6 downto 0 => data(3)) & signed(data(2 downto 0)) & signed(tmp(5 downto 0));
            -- commands(PITCH) <= shift_left(resize(signed((signed(tmp(3 downto 0)) & signed(data(5 downto 0))) - 500), 16), 6);
          when YAW =>
            -- LED <= not LED;
            commands(YAW) <= to_signed(0, 16);
            -- commands(YAW) <= shift_left(resize(signed((signed(tmp(3 downto 0)) & signed(data(5 downto 0))) - 500), 16), 6);
            -- commands(YAW) <= to_signed(0, 10);
          when THROTTLE =>
            throttleCmd <= "000000" & unsigned(data(3 downto 0)) & unsigned(tmp(5 downto 0));
            -- throttleCmd <= to_unsigned(100, 16);
            -- LCDInt <= to_integer(unsigned(data(3 downto 0)) & unsigned(tmp(5 downto 0)));
          when others =>
        end case;
      end if;
    end if;
	END IF;
	END PROCESS;
	
	
	PROCESS(CLOCK_50)
	BEGIN
		IF rising_edge(CLOCK_50) THEN
			IF (KEY = '0' and TX_BUSY = '0') THEN
				TX_DATA <= "01000001";
				TX_START <= '1';
			ELSE
				TX_START <= '0';
			END IF;
		END IF;
	END PROCESS;
END MAIN;
