library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY RX IS
PORT(
	CLK: IN STD_LOGIC; 
	BUSY: OUT STD_LOGIC;
	DATA: OUT STD_LOGIC_VECTOR(7 downto 0); 
	RX_LINE: IN STD_LOGIC 
); 
END RX;


ARCHITECTURE MAIN OF RX IS
 SIGNAL PRSCL: INTEGER RANGE 0 TO 5208  := 0;
 SIGNAL INDEX: INTEGER RANGE 0 TO 9 := 0;
 SIGNAL DATAFLL: STD_LOGIC_VECTOR(9 downto 0);
 SIGNAL RX_FLG: STD_LOGIC := '0';
 
BEGIN 
PROCESS(CLK)
	BEGIN
	IF rising_edge(CLK) THEN
		IF(RX_FLG = '0' AND RX_LINE = '0') THEN
			RX_FLG <= '1';
			BUSY <= '1';
			PRSCL <= 0;
			INDEX <= 0; 
		END IF;
		IF(RX_FLG = '1') THEN 
			DATAFLL(INDEX) <= RX_LINE;
			IF(PRSCL < 5207) THEN
				 PRSCL <= PRSCL + 1;
			ELSE
				PRSCL <= 0; 
			END IF;
			IF(PRSCL = 2500) THEN
				IF(INDEX <= 9) THEN
					INDEX <= INDEX + 1;
				ELSE
					IF(DATAFLL(0) = '0' AND DATAFLL(9) = '1') THEN
						DATA <= DATAFLL(8 downto 1);
					ELSE
						DATA <= (OTHERS => '0');
					END IF;
				RX_FLG <= '0';
				BUSY <= '0';
				END IF;
			END IF;
		END IF;
	END IF;
END PROCESS;
END MAIN;