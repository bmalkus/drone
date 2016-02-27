library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

entity LCD is

  generic (
    onScreenTime : natural
  );

  port (
    clk50MHz : in std_logic;
    BCDInt_20bit : in LCDin;
    twoLines : in std_logic; --not yet implemented
    E : out std_logic;
    RS : out std_logic;
    data : out std_logic_vector(3 downto 0)
  );

end entity;

architecture behavioural of LCD is
  type stateType is ( RESET1, RESET2, RESET3, INTERFACE_SET, SEND_LOWER, SEND_UPPER, FUNC_SET, DISPLAY_OFF,
                       DISPLAY_ON, DISPLAY_CLEAR, MODE_SET, SEND_CHAR, TOGGLE_E_UPPER, TOGGLE_E_LOWER,
                       CHANGE_LINE, KEEP_ON_SCREEN, WAIT_FOR_INPUT, INIT_POSITION, SKIP_ZEROS );

  signal state : stateType := RESET1;
  signal next_command : stateType := RESET1;

  signal data_val : LCDChar;

  constant clkCntrMax : integer := 62500;
  
  signal clk1KHz : std_logic := '0';
  signal clk1KHzCntr : integer range 1 to clkCntrMax := 1;

  signal resetCntr : integer range 0 to 16 := 0;

  signal currLine : integer range 0 to 1 := 0;

  signal inputCopy : LCDin := BCDInt_20bit;
  
  signal sendCntr : integer range 0 to 19 := 19;

  signal onScreenCntr : integer range 0 to onScreenTime := 0;

  signal numSending : integer range 0 to 3;


begin
  
  process (clk50MHz) is
  begin
    if rising_edge(clk50MHz) then
      if clk1KHzCntr = clkCntrMax then
        clk1KHz <= not clk1KHz;
        clk1KHzCntr <= 1;
      else
        clk1KHzCntr <= clk1KHzCntr + 1;
      end if;
    end if;
  end process;

  process (clk1KHz) is
  begin
    if rising_edge(clk1KHz) then
      case state is
        when RESET1 =>
          RS <= '0';
          data_val <= "00000011";
          resetCntr <= resetCntr + 1;
          if resetCntr = 6 then
            resetCntr <= 0;
            state <= SEND_LOWER;
            next_command <= RESET2;
          end if;
        when RESET2 =>
          RS <= '0';
          data_val <= "00000011";
          resetCntr <= resetCntr + 1;
          if resetCntr = 2 then
            resetCntr <= 0;
            state <= SEND_LOWER;
            next_command <= RESET3;
          end if;
        when RESET3 =>
          RS <= '0';
          data_val <= "00000011";
          resetCntr <= resetCntr + 1;
          state <= SEND_LOWER;
          next_command <= INTERFACE_SET;
        when INTERFACE_SET =>
          RS <= '0';
          data_val <= "00000010";
          state <= SEND_LOWER;
          next_command <= FUNC_SET;
        when FUNC_SET =>
          RS <= '0';
          data_val <= "00101000";
          state <= SEND_UPPER;
          next_command <= DISPLAY_OFF;
        when DISPLAY_OFF =>
          RS <= '0';
          data_val <= "00001000";
          state <= SEND_UPPER;
          next_command <= DISPLAY_CLEAR;
        when DISPLAY_CLEAR =>
          RS <= '0';
          data_val <= "00000001";
          state <= SEND_UPPER;
          next_command <= MODE_SET;
        when MODE_SET =>
          RS <= '0';
          data_val <= "00000110";
          state <= SEND_UPPER;
          next_command <= DISPLAY_ON;
        when DISPLAY_ON =>
          RS <= '0';
          data_val <= "00001100";
          state <= SEND_UPPER;
          next_command <= INIT_POSITION;
        when WAIT_FOR_INPUT =>
          if inputCopy /= BCDInt_20bit then
            state <= INIT_POSITION;
            inputCopy <= BCDInt_20bit;
          end if;
        when INIT_POSITION =>
          RS <= '0';
          case numSending is
            when 0 =>
              data_val <= std_logic_vector(unsigned(LCDStLineEnd) - 13);
            when 1 =>
              data_val <= std_logic_vector(unsigned(LCDStLineEnd) - 5);
            when 2 =>
              data_val <= std_logic_vector(unsigned(LCDNdLineEnd) - 13);
            when 3 =>
              data_val <= std_logic_vector(unsigned(LCDNdLineEnd) - 5);
          end case;
          state <= SEND_UPPER;
          next_command <= SKIP_ZEROS;
        when SKIP_ZEROS =>
          if inputCopy(numSending)(sendCntr downto sendCntr - 3) /= "0000" or sendCntr = 3 then
            if inputCopy(numSending)(20) = '1' then
              RS <= '1';
              data_val <= LCDCodeMinus;
              state <= SEND_UPPER;
              next_command <= SEND_CHAR;
            else
              RS <= '1';
              data_val <= LCDCodeSpace;
              state <= SEND_UPPER;
              next_command <= SEND_CHAR;
            end if;
          else
            sendCntr <= sendCntr - 4;
            RS <= '1';
            data_val <= LCDCodeSpace;
            state <= SEND_UPPER;
            next_command <= SKIP_ZEROS;
          end if;
        when SEND_CHAR =>
          RS <= '1';
          data_val <= LCDCodeNums(to_integer(unsigned(inputCopy(numSending)(sendCntr downto sendCntr - 3))));
          state <= SEND_UPPER;
          if sendCntr = 3 then
            if numSending < 3 then
              numSending <= numSending + 1;
              next_command <= INIT_POSITION;
            else
              numSending <= 0;
              next_command <= KEEP_ON_SCREEN;
            end if;
            sendCntr <= 19;
          else
            sendCntr <= sendCntr - 4;
            next_command <= SEND_CHAR;
          end if;
        when CHANGE_LINE =>
          if currLine = 0 then
            data_val <= LCDStLineEnd;
          else
            data_val <= LCDNdLineEnd;
          end if;
          currLine <= 1 - currLine;
          state <= SEND_UPPER;
          next_command <= KEEP_ON_SCREEN;
        when KEEP_ON_SCREEN =>
          if onScreenCntr = onScreenTime then
            state <= WAIT_FOR_INPUT;
            onScreenCntr <= 0;
          else
            onScreenCntr <= onScreenCntr + 1;
          end if;
        when SEND_UPPER =>
          E <= '1';
          data <= data_val(7 downto 4);
          state <= TOGGLE_E_UPPER;
        when TOGGLE_E_UPPER =>
          E <= '0';
          state <= SEND_LOWER;
        when SEND_LOWER =>
          E <= '1';
          data <= data_val(3 downto 0);
          state <= TOGGLE_E_LOWER;
        when TOGGLE_E_LOWER =>
          E <= '0';
          state <= next_command;
      end case;
    end if;
  end process;
end architecture;
