library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.utils.all;

entity gyroCalibrator is
  port (
    calibrateGyro : in std_logic;
    calibratingGyro : inout std_logic;
    gyroReadings : in signed16bit3D;
    gyroOffsets : out signed16bit3D;
    clk : in std_logic;
    led : out std_logic;
    reset : in std_logic
  );
end entity;

architecture Behavioral of gyroCalibrator is

  signal sum : signed32bit3D;
  signal samples : integer;

begin
	
  process (clk, reset) is
  begin
    if reset = '1' then

      calibratingGyro <= '0';
      gyroOffsets <= (others => to_signed(0, 16));
      sum <= (others => to_signed(0, 32));
      samples <= 0;
      led <= '1';

    elsif rising_edge(clk) then

      if calibratingGyro = '0' then
        if calibrateGyro = '1' then
          calibratingGyro <= '1';
        end if;
      else
        if samples < 1024 then
          for axis in 0 to 2 loop
            sum(axis) <= sum(axis) + gyroReadings(axis);
          end loop;
          samples <= samples + 1;
        else
          for axis in 0 to 2 loop
            gyroOffsets(axis) <= resize(shift_right(sum(axis), 10), 16);
            sum(axis) <= to_signed(0, 32);
          end loop;
          if shift_right(sum(ROLL), 10) >= 1 then
            led <= '0';
          end if;
          samples <= 0;
          calibratingGyro <= '0';
        end if;
      end if;

    end if;

  end process;

end architecture;
