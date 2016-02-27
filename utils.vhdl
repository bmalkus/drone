library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is

  subtype LCDChar is std_logic_vector(7 downto 0);
  type LCDLine is array(0 to 15) of LCDChar;
  type LCDTwoLines is array(0 to 1) of LCDLine;
  type intArray is array(natural range<>) of integer range 0 to 255;

  type LCDin is array(0 to 3) of std_logic_vector(20 downto 0);

  subtype signed16bit is signed(15 downto 0);
  subtype signed32bit is signed(31 downto 0);
  type signed16bit3D is array(0 to 2) of signed16bit;
  type signed32bit3D is array(0 to 2) of signed32bit;

  subtype unsigned16bit is unsigned(15 downto 0);

  subtype axisCommand is signed (15 downto 0);
  type axisCommands is array(0 to 2) of axisCommand;

  subtype throttleType is unsigned (15 downto 0);

  subtype mixerVal is signed (1 downto 0);
  type mixerType is array(0 to 2) of mixerVal;

  constant ROLL : integer := 0;
  constant PITCH : integer := 1;
  constant YAW : integer := 2;
  constant THROTTLE : integer := 3;

  constant P : integer := 0;
  constant I : integer := 1;
  constant D : integer := 2;

  constant MPUGyroXOffsetInt : integer := 0;
  constant MPUGyroYOffsetInt : integer := 0;
  constant MPUGyroZOffsetInt : integer := 0;

  constant THROTT_MIN_THRESH : integer := 200;
  constant COMM_MIN_THRESH : integer := -300;
  constant COMM_MAX_THRESH : integer := 300;

  constant LCDStLineEnd : LCDChar := "10001111";
  constant LCDNdLineEnd : LCDChar := "11001111";

  type codesArrayType is array(0 to 9) of LCDChar;
  constant LCDCodeNums : codesArrayType;
  constant LCDCodeColon : LCDChar := "00111010";
  constant LCDCodeSemicolon : LCDChar := "00111011";
  constant LCDCodeMinus : LCDChar := "00101101";
  constant LCDCodeSpace : LCDChar := "00100000";
  constant LCDCodePercent : LCDChar := "00100101";
  constant LCDCodeExcl : LCDChar := "00100001";
  constant LCDCodeUA : LCDChar := "01000001";
  constant LCDCodeUB : LCDChar := "01000010";
  constant LCDCodeUC : LCDChar := "01000011";
  constant LCDCodeUD : LCDChar := "01000100";
  constant LCDCodeUE : LCDChar := "01000101";
  constant LCDCodeUF : LCDChar := "01000110";
  constant LCDCodeUG : LCDChar := "01000111";
  constant LCDCodeUH : LCDChar := "01001000";
  constant LCDCodeUI : LCDChar := "01001001";
  constant LCDCodeUJ : LCDChar := "01001010";
  constant LCDCodeUK : LCDChar := "01001011";
  constant LCDCodeUL : LCDChar := "01001100";
  constant LCDCodeUM : LCDChar := "01001101";
  constant LCDCodeUN : LCDChar := "01001110";
  constant LCDCodeUO : LCDChar := "01001111";
  constant LCDCodeUP : LCDChar := "01010000";
  constant LCDCodeUQ : LCDChar := "01010001";
  constant LCDCodeUR : LCDChar := "01010010";
  constant LCDCodeUS : LCDChar := "01010011";
  constant LCDCodeUT : LCDChar := "01010100";
  constant LCDCodeUU : LCDChar := "01010101";
  constant LCDCodeUV : LCDChar := "01010110";
  constant LCDCodeUW : LCDChar := "01010111";
  constant LCDCodeUX : LCDChar := "01011000";
  constant LCDCodeUY : LCDChar := "01011001";
  constant LCDCodeUZ : LCDChar := "01011010";
  constant LCDCodeLA : LCDChar := "01100001";
  constant LCDCodeLB : LCDChar := "01100010";
  constant LCDCodeLC : LCDChar := "01100011";
  constant LCDCodeLD : LCDChar := "01100100";
  constant LCDCodeLE : LCDChar := "01100101";
  constant LCDCodeLF : LCDChar := "01100110";
  constant LCDCodeLG : LCDChar := "01100111";
  constant LCDCodeLH : LCDChar := "01101000";
  constant LCDCodeLI : LCDChar := "01101001";
  constant LCDCodeLJ : LCDChar := "01101010";
  constant LCDCodeLK : LCDChar := "01101011";
  constant LCDCodeLL : LCDChar := "01101100";
  constant LCDCodeLM : LCDChar := "01101101";
  constant LCDCodeLN : LCDChar := "01101110";
  constant LCDCodeLO : LCDChar := "01101111";
  constant LCDCodeLP : LCDChar := "01110000";
  constant LCDCodeLQ : LCDChar := "01110001";
  constant LCDCodeLR : LCDChar := "01110010";
  constant LCDCodeLS : LCDChar := "01110011";
  constant LCDCodeLT : LCDChar := "01110100";
  constant LCDCodeLU : LCDChar := "01110101";
  constant LCDCodeLV : LCDChar := "01110110";
  constant LCDCodeLW : LCDChar := "01110111";
  constant LCDCodeLX : LCDChar := "01111000";
  constant LCDCodeLY : LCDChar := "01111001";
  constant LCDCodeLZ : LCDChar := "01111010";
  
  constant MPUSlaveAddressR : std_logic_vector(7 downto 0) := "11010001";
  constant MPUSlaveAddressW : std_logic_vector(7 downto 0) := "11010000";
  constant MPUMagnAddressR : std_logic_vector(7 downto 0) := "00011001";
  constant MPUMagnAddressW : std_logic_vector(7 downto 0) := "00011000";
  constant BMPAddressR : std_logic_vector(7 downto 0) := "11101111";
  constant BMPAddressW : std_logic_vector(7 downto 0) := "11101110";

  constant MPUAccelXAddr : std_logic_vector(7 downto 0) := x"3B";
  constant MPUGyroXAddr : std_logic_vector(7 downto 0) := x"43";
  constant MPUMagnXAddr : std_logic_vector(7 downto 0) := x"49";

  constant MPUGyroXOffset : std_logic_vector := std_logic_vector(to_signed(MPUGyroXOffsetInt, 16));
  constant MPUGyroYOffset : std_logic_vector := std_logic_vector(to_signed(MPUGyroYOffsetInt, 16));
  constant MPUGyroZOffset : std_logic_vector := std_logic_vector(to_signed(MPUGyroZOffsetInt, 16));

  constant LCDEmptyLine : LCDLine := (
    others => LCDCodeSpace
  );

end package;

package body utils is

  constant LCDCodeNums : codesArrayType := (
    0 => "00110000",
    1 => "00110001",
    2 => "00110010",
    3 => "00110011",
    4 => "00110100",
    5 => "00110101",
    6 => "00110110",
    7 => "00110111",
    8 => "00111000",
    9 => "00111001"
  );

end package body;
