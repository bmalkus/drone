library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.utils.all;

entity ControlMPU is

  port (
    clk50MHz : in std_logic;
    SCL : inout std_logic;
    SDA : inout std_logic;
    gyro : out signed16bit3D;
    magn : out signed16bit3D;
    accel : out signed16bit3D;
    reset : in std_logic
  );

end entity;

architecture behavioral of ControlMPU is

  type stateType is ( INIT_COND, SEND_ADDRESS, ADDRESS_ACK, SEND_DATA, SEND_DATA_ACK, READ_DATA, READ_DATA_ACK,
                      READ_DATA_NACK, STOP_COND );
  signal state : stateType := STOP_COND;

  signal sdaClk : std_logic := '0';

  signal sclClkCntr : integer range 0 to 124 := 0;

  signal sendCntr : integer range 0 to 8;
  
  signal initDone : boolean;

  type dataArray is array(natural range<>) of std_logic_vector(8 downto 0);
  signal initData : dataArray(0 to 16);
  signal data : dataArray(0 to 4);

  signal dataCntr : integer range 0 to 256 := 0;
  
  signal readData : signed(15 downto 0);
  signal readCntr : integer range 0 to 15 := 15;

  signal lastAddress : std_logic_vector(8 downto 0);
  
  signal lastWrite : std_logic_vector(7 downto 0);
  signal contReadCntr : integer range 0 to 7;

  signal prevGyro : signed16bit3D;

begin

  process (clk50MHz) is
  begin

    if rising_edge(clk50MHz) then

      if reset = '1' then

        sclClkCntr <= 0;
        sdaClk <= '0';

      else

        if sclClkCntr < 124 then
          sclClkCntr <= sclClkCntr + 1;
        else
          sclClkCntr <= 0;
        end if;

        case sclClkCntr is

          when 0 to 30 =>
            SCL <= '0';
            sdaClk <= '0';

          when 31 to 61 =>
            SCL <= '0';
            sdaClk <= '1';

          when 62 =>
            SCL <= 'Z';
            sdaClk <= '0';

          when 63 to 92 =>
            SCL <= 'Z';
            if SCL = '0' then
              sclClkCntr <= 62;
            end if;
            sdaClk <= '0';

          when 93 to 124 =>
            SCL <= 'Z';
            sdaClk <= '1';

        end case;

      end if;

    end if;

  end process;

  process (sdaClk, reset) is
  begin

    if reset = '1' then

      state <= STOP_COND;
      sendCntr <= 8;
      initDone <= false;
      initData <= (
              MPUSlaveAddressW & "1",
              x"6B" & "0",
              "00000011" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"25" & "0",
              -- x"8C" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"26" & "0",
              -- x"03" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"27" & "0",
              -- "10000110" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"28" & "0",
              -- x"0C" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"29" & "0",
              -- x"0A" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"2A" & "0",
              -- "10000001" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"64" & "0",
              -- "00000001" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"6A" & "0",
              -- "00100000" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"34" & "0",
              -- "00000100" & "0",
              -- MPUSlaveAddressW & "1",
              -- x"67" & "0",
              -- "00000011" & "0",
              MPUSlaveAddressW & "1",
              x"1B" & "0",
              "00011000" & "0",
              MPUSlaveAddressW & "1",
              x"1A" & "0",
              "00000001" & "0",
              MPUSlaveAddressW & "1",
              x"13" & "0",
              MPUGyroXOffset(15 downto 8) & "0",
              MPUGyroXOffset(7 downto 0) & "0",
              MPUGyroYOffset(15 downto 8) & "0",
              MPUGyroYOffset(7 downto 0) & "0",
              MPUGyroZOffset(15 downto 8) & "0",
              MPUGyroZOffset(7 downto 0) & "0"
            );
      data <= (
              -- MPUSlaveAddressW & "1",
              -- MPUAccelXAddr & "0",
              -- MPUSlaveAddressR & "1",
              -- MPUSlaveAddressR & "1",
              -- MPUSlaveAddressR & "1",
              MPUSlaveAddressW & "1",
              MPUGyroXAddr & "0",
              MPUSlaveAddressR & "1",
              MPUSlaveAddressR & "1",
              MPUSlaveAddressR & "1"
              -- MPUSlaveAddressW & "1",
              -- MPUMagnXAddr & "0",
              -- MPUSlaveAddressR & "1",
              -- MPUSlaveAddressR & "1",
              -- MPUSlaveAddressR & "1"
            );
      dataCntr <= 0;
      readCntr <= 15;
      SDA <= '1';
      lastAddress <= x"00" & "1";
      contReadCntr <= 0;
      lastWrite <= x"00";
      gyro <= (others => x"0000");
      accel <= (others => x"0000");
      magn <= (others => x"0000");
      prevGyro <= (others => x"0000");

    elsif rising_edge(sdaClk) then

      if SCL /= '0' then

        if state = INIT_COND then

          sendCntr <= 8;
          SDA <= '0';
          if initData'length = 0 then
            initDone <= true;
          end if;
          state <= SEND_ADDRESS;

        elsif state = ADDRESS_ACK then

          if SDA /= '0' then
            state <= INIT_COND;
          else
            dataCntr <= dataCntr + 1;
            if initDone then
              lastAddress <= data(dataCntr);
            else
              lastAddress <= initData(dataCntr);
            end if;
            if (initDone and data(dataCntr)(1) = '1') or
               (not initDone and initData(dataCntr)(1) = '1') then
              state <= READ_DATA;
            else
              state <= SEND_DATA;
            end if;
          end if;

        elsif state = SEND_DATA_ACK then

          lastWrite <= data(dataCntr)(8 downto 1);
          dataCntr <= dataCntr + 1;
          if initDone then

            if dataCntr + 1 >= data'length then
              dataCntr <= 0;
              state <= INIT_COND;
            elsif data(dataCntr + 1)(0) = '0' then
              state <= SEND_DATA;
            else
              state <= INIT_COND;
            end if;

          else

            if dataCntr + 1 >= initData'length then
              initDone <= true;
              dataCntr <= 0;
              state <= INIT_COND;
            elsif initData(dataCntr + 1)(0) = '0' then
              state <= SEND_DATA;
            else
              state <= INIT_COND;
            end if;

          end if;

        elsif state = READ_DATA then

          readData(readCntr) <= SDA;

          if readCntr = 0 then

            readCntr <= 15;
            contReadCntr <= contReadCntr + 1;

            if lastWrite = MPUAccelXAddr then
              accel(contReadCntr) <= readData;
            elsif lastWrite = MPUGyroXAddr then
              if prevGyro(contReadCntr) /= shift_right(readData, 2) then
                if shift_right(readData, 2) < prevGyro(contReadCntr) - 800 then
                  gyro(contReadCntr) <= prevGyro(contReadCntr) - 800;
                  prevGyro(contReadCntr) <= prevGyro(contReadCntr) - 800;
                elsif shift_right(readData, 2) > prevGyro(contReadCntr) + 800 then
                  gyro(contReadCntr) <= prevGyro(contReadCntr) + 800;
                  prevGyro(contReadCntr) <= prevGyro(contReadCntr) + 800;
                else
                  gyro(contReadCntr) <= shift_right(readData, 2);
                  prevGyro(contReadCntr) <= shift_right(readData, 2);
                end if;
              end if;
            elsif lastWrite = MPUMagnXAddr then
              magn(contReadCntr) <= readData;
            end if;

            if dataCntr < data'length and data(dataCntr) = lastAddress then
              state <= READ_DATA_ACK;
              dataCntr <= dataCntr + 1;
            else
              state <= READ_DATA_NACK;
              contReadCntr <= 0;
            end if;

          elsif readCntr = 8 then

            readCntr <= readCntr - 1;
            state <= READ_DATA_ACK;

          else

            readCntr <= readCntr - 1;

          end if;

        elsif state = READ_DATA_ACK then

          state <= READ_DATA;

        elsif state = READ_DATA_NACK then

          if initDone and dataCntr >= data'length then
            dataCntr <= 0;
            state <= STOP_COND;
          elsif not initDone and dataCntr >= initData'length then
            initDone <= true;
            dataCntr <= 0;
            state <= STOP_COND;
          else
            state <= STOP_COND;
          end if;

        elsif state = STOP_COND then

          SDA <= 'Z';
          state <= INIT_COND;

        end if;

      else

        case state is

          when INIT_COND =>
            SDA <= 'Z';

          when SEND_ADDRESS =>
            if sendCntr >= 1 then
              if (initDone and data(dataCntr)(sendCntr) = '1') or
                 (not initDone and initData(dataCntr)(sendCntr) = '1') then
                SDA <= 'Z';
              else
                SDA <= '0';
              end if;
              sendCntr <= sendCntr - 1;
              state <= SEND_ADDRESS;
            else
              sendCntr <= 8;
              SDA <= 'Z';
              state <= ADDRESS_ACK;
            end if;

          when SEND_DATA =>
            if sendCntr >= 1 then
              if (initDone and data(dataCntr)(sendCntr) = '1') or
                 (not initDone and initData(dataCntr)(sendCntr) = '1') then
                SDA <= 'Z';
              else
                SDA <= '0';
              end if;
              sendCntr <= sendCntr - 1;
              state <= SEND_DATA;
            else
              sendCntr <= 8;
              SDA <= 'Z';
              state <= SEND_DATA_ACK;
            end if;

          when READ_DATA =>
            SDA <= 'Z';

          when READ_DATA_ACK =>
            SDA <= '0';

          when READ_DATA_NACK =>
            SDA <= 'Z';

          when STOP_COND =>
            SDA <= '0';

          when others =>

        end case;


      end if;

    end if;

  end process;

end architecture;
