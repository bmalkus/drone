library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

entity drone is

port(
	UART_TX: OUT STD_LOGIC;			--pin96
	UART_RX: IN STD_LOGIC;			--pin97
	led: inOUT STD_LOGIC;				--pin3
	clk50MHz	: 	in std_logic;
	pwm 	: 	 out std_logic_vector(3 downto 0);
  SDA : inout std_logic;
  SCL : inout std_logic;
  E : out std_logic;
  RS : out std_logic;
  LCDData : out std_logic_vector(3 downto 0);
	led2 : inout std_logic;
  RX : in std_logic_vector(3 downto 0)
);



end entity;

architecture behavioural of drone is

  signal commands : axisCommands;
  signal throttleCmd : throttleType;
  signal processedCmds : axisCommands;
  signal processedThrottle : throttleType;
  signal gyro : signed16bit3D;
  signal accel : signed16bit3D;
  signal magn : signed16bit3D;

  signal LCDInt : integer;

  signal BCDInt_20bit : LCDin;

  signal tmpInt : integer;
  
  component LCD is
    generic (
      onScreenTime : natural
    );
    port (
      clk50MHz : in std_logic;
      BCDInt_20bit : in LCDin;
      twoLines : in std_logic;
      E : out std_logic;
      RS : out std_logic;
      data : out std_logic_vector(3 downto 0)
    );
  end component;

  component intToBCD_16bit is
    
    port (
      input : in integer;
      output : out std_logic_vector(20 downto 0)
    );

  end component;

  component DroneMotor
    port (
      commands : in axisCommands;
      throttleCmd : in throttleType;
      clk50MHz	: 	in std_logic;
      pwm 	: 	 out std_logic;
      led	: out std_logic;
           -- led2	: out std_logic
      mixer : in mixerType;
      reset : in std_logic;
      clkPWM : in std_logic;
      currMotor : out signed(15 downto 0);
      maxMotor : in signed(15 downto 0);
      waiting : inout std_logic;
      maxMotorReady : in std_logic;
      armed : in std_logic;
      LCDInt : out integer
    );
  end component;

  component rs232 
    port (
      CLOCK_50: IN STD_LOGIC; 		--pin 17
      KEY: IN STD_LOGIC;  				--pin144
      UART_TX: OUT STD_LOGIC;			--pin96
      UART_RX: IN STD_LOGIC;			--pin97
      LED: inOUT STD_LOGIC;				--pin3
      commands : out axisCommands;
      reset : in std_logic;
      throttleCmd : out throttleType
    ); 
  end component;

  component commRX
    port (
      inputPIN : in std_logic;
      clk1MHz	: in std_logic;
      reset : in std_logic;
      cmdOut : out signed16bit
  );
  end component;

  component throttRX
    port (
      inputPIN : in std_logic;
      clk1MHz	: in std_logic;
      reset : in std_logic;
      led : inout std_logic;
      throttle : out unsigned16bit
  );
  end component;

  component commandProcessor
    port (
      commands : in axisCommands;
      throttleCmd : in throttleType;
      processedCmds : out axisCommands;
      processedThrottle : out throttleType;
      clk50MHz : in std_logic
    );
  end component;

  component gyroCalibrator
    port (
      calibrateGyro : in std_logic;
      calibratingGyro : inout std_logic;
      gyroReadings : in signed16bit3D;
      gyroOffsets : out signed16bit3D;
      clk : in std_logic;
      led : out std_logic;
      reset : in std_logic
    );
  end component;

  component GyroPID 
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
  end component;

  component ControlMPU is
  port (
    clk50MHz : in std_logic;
    SCL : inout std_logic;
    SDA : inout std_logic;
    gyro : out signed16bit3D;
    magn : out signed16bit3D;
    accel : out signed16bit3D;
    reset : in std_logic
  );
  end component;

  component stickCommands is
    port (
      commands : in axisCommands;
      throttleCmd : in throttleType;
      armed : out std_logic;
      calibrateGyro : inout std_logic;
      calibratingGyro : in std_logic;
      clk : in std_logic;
      reset : in std_logic
    );
  end component;

	signal reset : std_logic;
	signal resetCntr : integer range 0 to 10000 := 0;

  signal buf1 : axisCommands;
  signal buf2 : axisCommands;

  signal MPUbuf1 : signed16bit3D;
  signal MPUbuf2 : signed16bit3D;

  signal ThBuf1 : throttleType;
  signal ThBuf2 : throttleType;

  signal motor1cmd : signed16bit;
  signal motor2cmd : signed16bit;
  signal motor3cmd : signed16bit;
  signal motor4cmd : signed16bit;

  signal maxMotor : signed16bit;

  signal waiting : std_logic_vector(3 downto 0);
  signal maxMotorReady : std_logic_vector(3 downto 0);


	constant clkCntrMax : integer := 50;--50000000/pwmFrequency/2*maximumPWMCounter;
	signal clkPWM : std_logic := '0';
	signal clkPWMCounter : integer range 1 to clkCntrMax := 1;
	
  constant clkPIDCntrMax : integer := (25 * 2800) / 5; -- 4 kHz
  
  signal clkPID : std_logic := '0'; -- 0.5 KHz
  signal clkPIDCntr : integer range 1 to clkPIDCntrMax := 1;

  signal clk1MHz : std_logic := '0';
  signal clk1MHzCntr : integer := 0;

  signal clk1kHz : std_logic := '0';
  signal clk1kHzCntr : integer := 0;

  -- signal smoothGyro : signed16bit3D;
  signal offsetedGyro : signed16bit3D;
  signal outGyro : signed16bit3D;
  signal prevGyro1 : signed16bit3D;
  signal prevGyro2 : signed16bit3D;

  signal armed : std_logic;

  signal idle : std_logic;

  signal calibrateGyro, calibratingGyro : std_logic;
  signal gyroOffsets : signed16bit3D;

  function MAX (LEFT, RIGHT: signed16bit) return signed16bit is
  begin
    if LEFT > RIGHT then
      return LEFT;
    else
      return RIGHT;
    end if;
  end MAX;

begin

  process (clk50MHz) is
  begin
    if rising_edge(clk50MHz) then
      if armed = '1' then
        led <= '0';
      else
        led <= '1';
      end if;
    end if;
  end process;

	process (clk50MHz) is
	begin
    if rising_edge(clk50MHz) then
      if resetCntr < 100 then
        reset <= '1';
        resetCntr <= resetCntr + 1;
    -- led2 <= '1';

      else
        reset <= '0';
    -- led2 <= '0';
      end if;
    end if;
	end process;


  process (clkPWM) is
  begin

    if rising_edge(clkPWM) then

      buf1 <= processedCmds;
      buf2 <= buf1;

      ThBuf1 <= throttleCmd;
      ThBuf2 <= ThBuf1;

    end if;

  end process;


  process (clkPID, reset) is
  begin
    if reset = '1' then

      outGyro <= (others => x"0000");
      prevGyro1 <= (others => x"0000");
      prevGyro2 <= (others => x"0000");

    elsif rising_edge(clkPID) then

      for axis in 0 to 2 loop

        if MPUbuf2(axis) /= prevGyro1(axis) then

          outGyro(axis) <= (MPUbuf2(axis) + prevGyro1(axis) + prevGyro2(axis)) / 3;

          prevGyro2(axis) <= shift_right(MPUbuf2(axis) + prevGyro1(axis), 1);

          prevGyro1(axis) <= MPUbuf2(axis);

        end if;

        offsetedGyro(axis) <= outGyro(axis) - gyroOffsets(axis);

      end loop;

      -- if MPUbuf2(0) /= previousGyro(0) then
        -- smoothGyro(0) <= shift_right(resize(smoothGyro(0) * 7, 16) + MPUbuf2(0), 3);
        -- smoothGyro(0) <= (resize(smoothGyro(0) * 4, 16) + MPUbuf2(0)) / 5;
      -- end if;
      -- if MPUbuf2(1) /= previousGyro(1) then
        -- smoothGyro(1) <= (resize(smoothGyro(1) * 4, 16) + MPUbuf2(1)) / 5;
      -- end if;
      -- if MPUbuf2(2) /= previousGyro(2) then
        -- smoothGyro(2) <= (resize(smoothGyro(2) * 4, 16) + MPUbuf2(2)) / 5;
      -- end if;

    end if;

  end process;

  process (clkPID) is
  begin

    if rising_edge(clkPID) then

      MPUbuf1 <= gyro;
      MPUbuf2 <= MPUbuf1;

    end if;

  end process;

	process (clk50MHz, reset) is
	begin
		if reset = '1' then
			clkPWM <= '0';
			clkPWMCounter <= 1;
		elsif rising_edge(clk50MHz) then
			if clkPWMCounter = clkCntrMax then
				clkPWM <= not clkPWM;
				clkPWMCounter <= 1;
			else
				clkPWMCounter <= clkPWMCounter + 1;
			end if;
		end if;
	end process;

	process (clk50MHz, reset) is
	begin
		if reset = '1' then
			clk1MHz <= '0';
			clk1MHzCntr <= 0;
		elsif rising_edge(clk50MHz) then
			if clk1MHzCntr < 25 then
        clk1MHzCntr <= clk1MHzCntr + 1;
			else
				clk1MHz <= not clk1MHz;
				clk1MHzCntr <= 0;
			end if;
		end if;
	end process;

	process (clk50MHz, reset) is
	begin
		if reset = '1' then
			clk1kHz <= '0';
			clk1kHzCntr <= 0;
		elsif rising_edge(clk50MHz) then
			if clk1kHzCntr < 25000 then
        clk1kHzCntr <= clk1kHzCntr + 1;
			else
				clk1kHz <= not clk1kHz;
				clk1kHzCntr <= 0;
			end if;
		end if;
	end process;

  process (clk50MHz) is
  begin

    if rising_edge(clk50MHz) then
      if clkPIDCntr = clkPIDCntrMax then
        clkPID <= not clkPID;
        clkPIDCntr <= 1;
      else
        clkPIDCntr <= clkPIDCntr + 1;
      end if;
    end if;

  end process;

  mpu: ControlMPU
  port map (
    clk50MHz => clk50MHz,
    SCL => SCL,
    SDA => SDA,
    gyro => gyro,
    magn => magn,
    accel => accel,
    reset => reset
  );

  -- processor : commandProcessor
  -- port map (
  --   commands => commands,
  --   throttleCmd => throttleCmd,
  --   processedCmds => processedCmds,
  --   processedThrottle => processedThrottle,
  --   clk50MHz => clk50MHz
  -- );


  conv : intToBCD_16bit
    port map (
      -- input => clkPWMCounter, --to_integer(throttleCmd),
      -- input => to_integer(throttleCmd),
      -- input => to_integer(signed(press)),
      input => to_integer(gyroOffsets(ROLL)),
      output => BCDInt_20bit(0)
    );

  conv2 : intToBCD_16bit
    port map (
      -- input => clkPWMCounter, --to_integer(throttleCmd),
      -- input => to_integer(throttleCmd),
      -- input => to_integer(signed(press)),
      input => to_integer(gyroOffsets(PITCH)),
      output => BCDInt_20bit(1)
    );

  conv3 : intToBCD_16bit
    port map (
      -- input => clkPWMCounter, --to_integer(throttleCmd),
      -- input => to_integer(throttleCmd),
      -- input => to_integer(signed(press)),
      input => to_integer(gyroOffsets(YAW)),
      output => BCDInt_20bit(2)
    );

  conv4 : intToBCD_16bit
    port map (
      -- input => clkPWMCounter, --to_integer(throttleCmd),
      -- input => to_integer(throttleCmd),
      -- input => to_integer(signed(press)),
      input => to_integer(offsetedGyro(ROLL)),
      output => BCDInt_20bit(3)
    );

  LCDScreen : LCD
    generic map (
      onScreenTime => 80
    )
    port map (
      clk50MHz => clk50MHz,
      BCDInt_20bit => BCDInt_20bit,
      twoLines => '0',
      E => E,
      RS => RS,
      data => LCDData
    );
	

  gPID : GyroPID
  port map (
      commands => commands,
      readings => offsetedGyro,
      clk50MHz => clk50MHz,
      PIDcoeff => (to_signed(14, 16), to_signed(30, 16), to_signed(8, 16)),
      reset => reset,
      clkPID => clkPID,
      -- LCDInt => tmpInt,
      throttleCmd => ThBuf2,
      PID => processedCmds
    );

  calib : gyroCalibrator
  port map (
    calibrateGyro => calibrateGyro,
    calibratingGyro => calibratingGyro,
    gyroreadings => outgyro,
    gyrooffsets => gyrooffsets,
    clk => clk1kHz,
    led => led2,
    reset => reset
  );

  stickCmds : stickCommands
    port map (
      commands => commands,
      throttleCmd => ThBuf2,
      armed => armed,
      calibrateGyro => calibrateGyro,
      calibratingGyro => calibratingGyro,
      clk => clk1MHz,
      reset => reset
    );

  process (clkPWM) is
  begin
    if rising_edge(clkPWM) then
      if idle = '1' then
        idle <= '0';
        maxMotorReady <= "0000";
      else
        if waiting = "1111" then
          maxMotor <= max(max(max(motor1cmd, motor2cmd), motor3cmd), motor4cmd);
          maxMotorReady <= "1111";
          idle <= '1';
        end if;
      end if;
    end if;
  end process;


  motor1 : DroneMotor
  port map (
             commands => buf2,
             -- commands => commands,
             throttleCmd => ThBuf2,
             clk50MHz	=> clk50MHz,
             pwm => pwm(0),
             mixer => (to_signed(-1, 2), to_signed(1, 2), to_signed(1, 2)),
             reset => reset,
             currMotor => motor1cmd,
             maxMotor => maxMotor,
             -- led => led,
             waiting => waiting(0),
             maxMotorReady => maxMotorReady(0),
             armed => armed,
             clkPWM => clkPWM
           );

  motor2 : DroneMotor
  port map (
             commands => buf2,
             -- commands => commands,
             throttleCmd => ThBuf2,
             clk50MHz	=> clk50MHz,
             pwm => pwm(1),
             mixer => (to_signed(-1, 2), to_signed(-1, 2), to_signed(-1, 2)),
             reset => reset,
             currMotor => motor2cmd,
             maxMotor => maxMotor,
             waiting => waiting(1),
             maxMotorReady => maxMotorReady(1),
             armed => armed,
             clkPWM => clkPWM
           );

  motor3 : DroneMotor
  port map (
             commands => buf2,
             -- commands => commands,
             throttleCmd => ThBuf2,
             clk50MHz	=> clk50MHz,
             pwm => pwm(2),
             mixer => (to_signed(1, 2), to_signed(-1, 2), to_signed(1, 2)),
             reset => reset,
             currMotor => motor3cmd,
             maxMotor => maxMotor,
             waiting => waiting(2),
             maxMotorReady => maxMotorReady(2),
             armed => armed,
             clkPWM => clkPWM
           );

  motor4 : DroneMotor
  port map (
             commands => buf2,
             -- commands => commands,
             throttleCmd => ThBuf2,
             clk50MHz	=> clk50MHz,
             pwm => pwm(3),
             mixer => (to_signed(1, 2), to_signed(1, 2), to_signed(-1, 2)),
             reset => reset,
             currMotor => motor4cmd,
             maxMotor => maxMotor,
             waiting => waiting(3),
             maxMotorReady => maxMotorReady(3),
             armed => armed,
             clkPWM => clkPWM
           );

  -- rs2322: rs232
  -- port map (
  --            CLOCK_50 => clk50MHz,
  --            KEY => '1', 
  --            UART_TX => UART_TX,
  --            UART_RX => UART_RX, 
  --            LED => led2,
  --            commands => commands,
  --            reset => reset,
  --            throttleCmd => throttleCmd
  --          );

  rollRX: commRX
  port map (
    inputPIN => RX(0),
    clk1MHz	=> clk1MHz,
    reset => reset,
    cmdOut => commands(ROLL)
  );

  pitchRX: commRX
  port map (
    inputPIN => RX(1),
    clk1MHz	=> clk1MHz,
    reset => reset,
    cmdOut => commands(PITCH)
  );

  throttleRX: throttRX
  port map (
    inputPIN => RX(2),
    clk1MHz	=> clk1MHz,
    reset => reset,
    -- led => led,
    throttle => throttleCmd
  );

  yawRX: commRX
  port map (
    inputPIN => RX(3),
    clk1MHz	=> clk1MHz,
    reset => reset,
    cmdOut => commands(YAW)
  );

end architecture;
