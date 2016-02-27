library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.utils.all;

entity stickCommands is
  port (
    commands : in axisCommands;
    throttleCmd : in throttleType;
    armed : inout std_logic;
    calibrateGyro : inout std_logic;
    calibratingGyro : in std_logic;
    clk : in std_logic;
    reset : in std_logic
  );
end entity;

architecture Behavioral of stickCommands is

  signal waitingForCalib : boolean;

begin
	
  process (clk, reset) is
  begin
    if reset = '1' then

      armed <= '0';
      calibrateGyro <= '0';
      waitingForCalib <= false;

    elsif rising_edge(clk) then

      if waitingForCalib then
        if calibratingGyro = '1' then
          waitingForCalib <= false;
          calibrateGyro <= '0';
        end if;
      else
        if commands(ROLL) < COMM_MIN_THRESH and commands(PITCH) < COMM_MIN_THRESH then
          if throttleCmd < THROTT_MIN_THRESH and commands(YAW) < COMM_MIN_THRESH then
            if armed = '0' then
              waitingForCalib <= true;
              calibrateGyro <= '1';
            end if;
          end if;
        elsif throttleCmd < THROTT_MIN_THRESH then
          if commands(YAW) > COMM_MAX_THRESH then
            if calibrateGyro = '0' and calibratingGyro = '0' then
              armed <= '1';
            end if;
          elsif commands(YAW) < COMM_MIN_THRESH then
            armed <= '0';
          end if;
        end if;
      end if;

    end if;

  end process;

end Behavioral;
