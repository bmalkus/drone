library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.utils.all;

entity throttRX is port (
  inputPIN : in std_logic;
	clk1MHz	: in std_logic;
  reset : in std_logic;
  led : inout std_logic;
  throttle : out unsigned16bit
);

end throttRX;

architecture Behavioral of throttRX is

  signal len : integer;

begin
	
  process (clk1MHz, reset) is
  begin
    if reset = '1' then

      throttle <= to_unsigned(0, 16);
      len <= 0;

    elsif rising_edge(clk1MHz) then

      if inputPIN = '1' then
        len <= len + 1;
      else
        len <= 0;

        if len > 1000 and len < 2000 then
          throttle <= to_unsigned(len - 1000, 16);
        end if;
      end if;

    end if;

  end process;

end Behavioral;
