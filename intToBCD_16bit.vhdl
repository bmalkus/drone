library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity intToBCD_16bit is
  
  port (
    input : in integer;
    output : out std_logic_vector(20 downto 0)
  );

end entity;

architecture behavioral of intToBCD_16bit is
begin

  process (input) is

    -- Double dabble algorithm to convert integer to
    -- binary-coded decimal (BCD) form

    variable tmp : std_logic_vector(15 downto 0);
    variable bcd : std_logic_vector(19 downto 0);

  begin

    bcd := (others => '0');

    tmp := std_logic_vector(to_unsigned(abs(input), 16));

    for i in 0 to 15 loop

      if bcd(3 downto 0) > "0100" then
        bcd(3 downto 0) := std_logic_vector(unsigned(bcd(3 downto 0)) + 3);
      end if;

      if bcd(7 downto 4) > "0100" then
        bcd(7 downto 4) := std_logic_vector(unsigned(bcd(7 downto 4)) + 3);
      end if;
      
      if bcd(11 downto 8) > "0100" then
        bcd(11 downto 8) := std_logic_vector(unsigned(bcd(11 downto 8)) + 3);
      end if;

      if bcd(15 downto 12) > "0100" then
        bcd(15 downto 12) := std_logic_vector(unsigned(bcd(15 downto 12)) + 3);
      end if;

      bcd := bcd(18 downto 0) & tmp(15);
      tmp := tmp(14 downto 0) & '0';

    end loop;

    if input < 0 then
      output <= '1' & bcd;
    else
      output <= '0' & bcd;
    end if;

  end process;

end architecture;
