library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
-- use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.utils.all;

entity DroneMotor is
  port (
    commands : in axisCommands;
    throttleCmd : in throttleType;
    clk50MHz	: 	in std_logic;
    pwm 	: 	 out std_logic;
    led	: inout std_logic;
    mixer : in mixerType;
    reset : in std_logic;
    clkPWM : in std_logic;
    currMotor : out signed(15 downto 0);
    maxMotor : in signed(15 downto 0);
    waiting : out std_logic;
    maxMotorReady : in std_logic;
    armed : in std_logic;
    -- led2	: out std_logic
    LCDInt : out integer
  );


end DroneMotor;

architecture Behavioral of DroneMotor is
	constant pwmFrequency : integer := 300;
	
	constant resolutionOfPWM : integer := 4;
	constant maximumPWMCounter : integer := 10000;  -- must be higher than resolutionOfPWM
	signal fulfillmentPWMCounter : integer range 1 to maximumPWMCounter := 1;

	signal s3Counter : integer range 0 to 5000 := 0;
	
  signal init : std_logic;
  signal init2 : std_logic;
  
  signal z : signed(15 downto 0);

  signal halfPWM : std_logic;
  signal limit, tmp : signed16bit;

  signal state : integer range 0 to 8;

  signal tmpCommands : axisCommands;

begin
	
	
  process (clkPWM, reset) is
  begin
    if reset = '1' then

      fulfillmentPWMCounter <= 1;
      pwm <= '0';
      s3Counter <= 0;
      z <= to_signed(0, 16);
      init <= '0';
      init2 <= '1';
       -- led2 <= '1';

    elsif rising_edge(clkPWM) then

      if init = '0' then

        if s3Counter < 60 then
          if fulfillmentPWMCounter < maximumPWMCounter then
            fulfillmentPWMCounter <= fulfillmentPWMCounter + 1;
            if fulfillmentPWMCounter <= 280 then
              pwm <= '1';
            else
              pwm <= '0';
            end if;
          else
            fulfillmentPWMCounter <= 1;
            s3Counter <= s3Counter + 1;
          end if;
        else
          init <= '1';
             -- led2 <= '1';
          fulfillmentPWMCounter <= 1;
          s3Counter <= 0;
        end if;

      elsif init2 = '0' then

        if s3Counter < 25 then
          if fulfillmentPWMCounter < maximumPWMCounter then
            fulfillmentPWMCounter <= fulfillmentPWMCounter + 1;
            if fulfillmentPWMCounter <= 700 then
              pwm <= '1';
            else
              pwm <= '0';
            end if;
          else
            fulfillmentPWMCounter <= 1;
            s3Counter <= s3Counter + 1;
          end if;
        else
          init2 <= '1';
             -- led2 <= '0';
          fulfillmentPWMCounter <= 1;
        end if;

      else

        -- LCDInt <= to_integer(unsigned(std_logic_vector'(""&halfPWM)));

        if fulfillmentPWMCounter < maximumPWMCounter then
          fulfillmentPWMCounter <= fulfillmentPWMCounter + 1;
          -- z <= to_unsigned(50, 8);
          if fulfillmentPWMCounter < z then
            pwm <= '1';
          else
            pwm <= '0';
          end if;

          -- if fulfillmentPWMCounter = maximumPWMCounter / 8 then
          --   halfPWM <= '1';
          -- elsif fulfillmentPWMCounter = 2 * maximumPWMCounter / 8 then
          --   halfPWM <= '0';
          -- elsif fulfillmentPWMCounter = 3 * maximumPWMCounter / 8 then
          --   halfPWM <= '1';
          -- elsif fulfillmentPWMCounter = 4 * maximumPWMCounter / 8 then
          --   halfPWM <= '0';
          -- elsif fulfillmentPWMCounter = 5 * maximumPWMCounter / 8 then
          --   halfPWM <= '1';
          -- elsif fulfillmentPWMCounter = 6 * maximumPWMCounter / 8 then
          --   halfPWM <= '0';
          -- elsif fulfillmentPWMCounter = 7 * maximumPWMCounter / 8 then
          --   halfPWM <= '1';
          -- end if;
        else
          
          -- halfPWM <= '0';
          fulfillmentPWMCounter <= 1;
          z <= limit;

        end if;

      end if;


    -- if fulfillmentPWMCounter = maximumPWMCounter then
    -- 	fulfillmentPWMCounter <= 1;
    -- 	if s3Counter < 150 then
    -- 		led <= '0';
    -- 		s3Counter <= s3Counter + 1;
    -- 	else 
    -- 		led <= '1';
    -- 	end if;
    -- elsif (s3Counter < 50) and fulfillmentPWMCounter < 27 then
    -- 	pwm <= '1';
    -- 	fulfillmentPWMCounter <= fulfillmentPWMCounter + 1;
    -- elsif (fulfillmentPWMCounter < 70) and (s3Counter >= 50) then
    -- 	pwm <= '1';
    -- 	fulfillmentPWMCounter <= fulfillmentPWMCounter + 1;
    -- else
    -- 	pwm <= '0';
    -- 	fulfillmentPWMCounter <= fulfillmentPWMCounter + 1;
    -- end if;

    end if;
  end process;

  process (clkPWM, reset) is

  begin

    if reset = '1' then

      limit <= to_signed(500, 16);
      state <= 0;

    elsif rising_edge(clkPWM) then

      if state = 0 then

        state <= state + 1;

        tmpCommands(ROLL) <= resize(mixer(ROLL) * commands(ROLL), 16);
        tmpCommands(PITCH) <= resize(mixer(PITCH) * commands(PITCH), 16);
        tmpCommands(YAW) <= resize(mixer(YAW) * commands(YAW), 16);

      elsif state = 1 then

        state <= state + 1;

        tmp <= signed(throttleCmd / 2 + 480) + shift_right(tmpCommands(PITCH), 1) + shift_right(tmpCommands(ROLL), 1) + shift_right(tmpCommands(YAW), 1);
        -- tmp <= unsigned(signed(tmp) + tmpCommands(ROLL));

      elsif state = 2 then

        state <= state + 1;

        currMotor <= tmp;
        
      elsif state = 3 then

        waiting <= '1';

        state <= state + 1;

      elsif state = 4 then

        if maxMotorReady = '1' then
          state <= state + 1;
          waiting <= '0';
        end if;

      elsif state = 5 then

        state <= state + 1;

        if maxMotor > 1000 then
          tmp <= tmp - (maxMotor - 1000);
        end if;

      else

        state <= 0;

        if tmp > 1000 then
          limit <= to_signed(1000, 16);
        elsif tmp < 540 then
          limit <= to_signed(540, 16);
        else
          limit <= tmp;
        end if;

		  if throttleCmd < THROTT_MIN_THRESH then
		    limit <= to_signed(540, 16);
		  end if;
		  
        if armed = '0' then
          limit <= to_signed(500, 16);
        end if;

      end if;

      -- tmpCommands(YAW) := resize(mixer(YAW) * commands(YAW), 16);

      -- tmpCommands(YAW) := shift_right(tmpCommands(YAW), 4);

        -- tmp := unsigned(signed(tmp) + tmpCommands(PITCH) + tmpCommands(ROLL));
        -- tmp := resize(unsigned(signed(resize(throttleCmd + 480, 12)) + tmpCommands(PITCH) + tmpCommands(ROLL)), 12);
        --tmp := resize(unsigned(signed(resize(throttleCmd + 480, 12)) + tmpCommands(YAW) + tmpCommands(PITCH) + tmpCommands(ROLL)), 12);
        -- tmp := unsigned(signed(resize(throttleCmd, 12)) + tmpCommands(ROLL) + tmpCommands(PITCH) + tmpCommands(YAW));
        -- tmp := tmp(11) & "0" & tmp(10 downto 1);

    end if;

  end process;

end Behavioral;
