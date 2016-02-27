library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

entity commandProcessor is

  port (
    commands : in axisCommands;
    throttleCmd : in throttleType;
    processedCmds : out axisCommands;
    processedThrottle : out throttleType;
    clk50MHz : in std_logic
  );

end entity;

architecture behavioral of commandProcessor is

  constant clkCntrMax : integer := 62500;
  
  signal clk1KHz : std_logic := '0';
  signal clk1KHzCntr : integer range 1 to clkCntrMax := 1;

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

      processedCmds(ROLL) <= shift_right(commands(ROLL), 6);
      processedCmds(PITCH) <= shift_right(commands(PITCH), 6);
      processedCmds(YAW) <= shift_right(commands(YAW), 7);
      processedThrottle <= shift_right(throttleCmd, 1);

    end if;

  end process;

end architecture;
