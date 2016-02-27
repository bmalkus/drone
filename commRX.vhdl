library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.utils.all;

entity commRX is port (
  inputPIN : in std_logic;
	clk1MHz	: in std_logic;
  reset : in std_logic;
  cmdOut : out signed16bit
);
end commRX;

architecture Behavioral of commRX is

  signal len : integer;

begin
	
  process (clk1MHz, reset) is
  begin
    if reset = '1' then

      cmdOut <= to_signed(0, 16);
      len <= 0;

    elsif rising_edge(clk1MHz) then

      if inputPIN = '1' then
        len <= len + 1;
      else
        len <= 0;
        if len > 1000 and len < 2000 then
          cmdOut <= to_signed(len - 1500, 16);
        end if;
      end if;

    end if;

  end process;

end Behavioral;
