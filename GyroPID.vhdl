library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

entity GyroPID is

  port (
    commands : in axisCommands;
    readings : in signed16bit3D;
    clk50MHz : in std_logic;
    PIDcoeff : in signed16bit3D;
    reset : in std_logic;
    clkPID : in std_logic;
    LCDInt : out integer;
    throttleCmd : in throttleType;
    PID : out axisCommands
  );

end entity;

architecture behavioral of GyroPID is


  signal errorI : signed16bit3D;
  signal lastReadings : signed16bit3D;
  signal oldDelta1, oldDelta2 : signed16bit3D;

  constant maxState : integer := 4;
  signal state : integer range 0 to maxState;
  -- signal axis : integer range 0 to 2;

  signal errorOnAxis : signed16bit3D;

  signal PTerm, ITerm, DTerm : signed32bit3D;

  signal delta : signed16bit3D;

  signal changed : std_logic;

  signal readingsInt : signed16bit3D;

begin


  process (clkPID, reset) is

    -- variable delta : signed16bit;
    -- variable axis : integer;
    -- variable tmpErrorI : signed16bit;

    -- procedure computePIDForAxis(axis : integer) is

    -- begin

    --   errorOnAxis := commands(axis) - shift_right(readings(axis), 6);
      
    --   PTerm := errorOnAxis * PIDcoeff(P);

      -- tmpErrorI := errorI(axis) + errorOnAxis;

      -- if tmpErrorI < -16000 then
      --   tmpErrorI := to_signed(-16000, 16);
      -- elsif tmpErrorI > 16000 then
      --   tmpErrorI := to_signed(16000, 16);
      -- end if;

      -- errorI(axis) <= tmpErrorI;

      -- ITerm := shift_left(tmpErrorI * PIDcoeff(I), 10);
      -- 
      -- delta := readings(axis) - lastReadings(axis);

      -- DTerm := shift_left((delta + oldDelta1(axis) + oldDelta2(axis)) * PIDcoeff(D), 10);

      -- oldDelta2(axis) <= oldDelta1(axis);
      -- oldDelta1(axis) <= delta;

      -- PID(axis) <= PTerm(31 downto 16) + ITerm(31 downto 16) - DTerm(31 downto 16); 
      -- PID(axis) <= PTerm(15 downto 0); 

    -- end procedure;

  begin

    if reset = '1' then

      errorI <= (others => x"0000");
      lastReadings <= (others => x"0000");
      oldDelta1 <= (others => x"0000");
      oldDelta2 <= (others => x"0000");
      PID <= (others => x"0000");
      state <= 0;
      errorOnAxis <= (others => to_signed(0, 16));
      -- axis <= 0;
      readingsInt <= (others => to_signed(0, 16));

    elsif rising_edge(clkPID) then

      -- computePIDForAxis(state);

      if state < maxState then
        state <= state + 1;
      else
        state <= 0;
      end if;

      case state is

        when 0 =>

          for axis in 0 to 2 loop

            readingsInt(axis) <= readings(axis);

          end loop;
        
        when 1 =>

          for axis in 0 to 2 loop

            errorOnAxis(axis) <= shift_left(commands(axis), 1) - readingsInt(axis);
            -- errorOnAxis(axis) <= shift_right(commands(axis), 1) - readingsInt(axis);

            delta(axis) <= readingsInt(axis) - lastReadings(axis);
            lastReadings(axis) <= readingsInt(axis);

          end loop;

          -- if lastReadings(axis) /= readings(axis) then
          --   changed <= '1';
          -- else
          --   changed <= '0';
          -- end if;
          
        when 2 =>

          for axis in 0 to 2 loop

            PTerm(axis) <= shift_right(errorOnAxis(axis) * PIDcoeff(P), 6);
            DTerm(axis) <= shift_right((delta(axis) + oldDelta1(axis) + oldDelta2(axis)) * PIDcoeff(D), 6);
            oldDelta2(axis) <= oldDelta1(axis);
            oldDelta1(axis) <= delta(axis);

            if readingsInt(axis) > 640 then
              errorI(axis) <= to_signed(0, 16);
            elsif readingsInt(axis) < -640 then
              errorI(axis) <= to_signed(0, 16);
            else
              if errorI(axis) + errorOnAxis(axis) < -16000 then
                errorI(axis) <= to_signed(-16000, 16);
              elsif errorI(axis) + errorOnAxis(axis) > 16000 then
                errorI(axis) <= to_signed(16000, 16);
              else
                errorI(axis) <= errorI(axis) + errorOnAxis(axis);
              end if;
            end if;

            if throttleCmd < THROTT_MIN_THRESH then
              errorI(axis) <= to_signed(0, 16);
            end if;

          end loop;

        when 3 =>

          for axis in 0 to 2 loop

            ITerm(axis) <= shift_right(shift_right(errorI(axis), 7) * PIDcoeff(I), 6);
          end loop;

        when 4 =>

          for axis in 0 to 2 loop

            PID(axis) <= resize(PTerm(axis) + ITerm(axis) - DTerm(axis), 16);
            -- LCDInt <= to_integer(resize(shift_right(PTerm, 6), 16) + resize(DTerm, 16));

          end loop;

      end case;

      -- errorOnAxis := commands(YAW) - readings(YAW);

      -- PTerm := errorOnAxis * PIDcoeff(P);

      -- tmpErrorI := errorI(YAW) + errorOnAxis;

      -- if tmpErrorI < -16000 then
      --   tmpErrorI := to_signed(-16000, 16);
      -- elsif tmpErrorI > 16000 then
      --   tmpErrorI := to_signed(16000, 16);
      -- end if;

      -- errorI(YAW) <= tmpErrorI;

      -- ITerm := tmpErrorI * PIDcoeff(I);

      -- PID(YAW) <= PTerm(31 downto 16) + ITerm(31 downto 16); 
      -- PID(YAW) <= PTerm(15 downto 0); 

    end if;

  end process;

end architecture;
