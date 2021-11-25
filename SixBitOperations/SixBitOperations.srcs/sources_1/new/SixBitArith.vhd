----------------------------------------------------------------------------------
-- Company: Blackstock Designs
-- Engineer: George Henry
-- 
-- Create Date: 11/24/2021 02:39:24 PM
-- Design Name: 
-- Module Name: SixBitArith - Behavioral
-- Project Name: 
-- Target Devices: Digilent Basys3
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Code for controling the seven segment display based on 
-- https://www.fpga4student.com/2017/09/vhdl-code-for-seven-segment-display.html
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SixBitArith is
    Port ( sw : in std_logic_vector(15 downto 0); -- switches on the Basys 3
         led : out std_logic_vector(15 downto 0); -- leds on the Baysy 3
         btnL, btnR: in std_logic; -- left and right buttons on the Basys 3
         clock_100Mhz : in STD_LOGIC;-- 100Mhz clock on Basys 3 FPGA board           
         Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0);-- 4 Anode signals
         LED_out : out STD_LOGIC_VECTOR (6 downto 0)); -- seven segment display on the Basys 3
end SixBitArith;

architecture Behavioral of SixBitArith is
    signal displayed_number: STD_LOGIC_VECTOR (15 downto 0);
    -- counting decimal number to be displayed on 4-digit 7-segment display
    signal LED_BCD: STD_LOGIC_VECTOR (4 downto 0);
    signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
    -- creating 10.5ms refresh period
    signal LED_activating_counter: std_logic_vector(1 downto 0);
    -- the other 2-bit for creating 4 LED-activating signals
    -- count         0    ->  1  ->  2  ->  3
    -- activates    LED1    LED2   LED3   LED4
    -- and repeat
    signal num1, num2: std_logic_vector(5 downto 0);
    signal orVal, xorVal, andVal: std_logic_vector(5 downto 0);
    signal opeationChoice: std_logic_vector(2 downto 0);
    signal intNum1, intNum2, output, orNum, xorNum, andNum: integer :=0;
begin
    -- assign the leds on the board to light up when the coressponding switch is on
    led(0) <= sw(0);
    led(1) <= sw(1);
    led(2) <= sw(2);
    led(3) <= sw(3);
    led(4) <= sw(4);
    led(5) <= sw(5);
    led(6) <= sw(6);
    led(7) <= sw(7);
    led(8) <= sw(8);
    led(9) <= sw(9);
    led(10) <= sw(10);
    led(11) <= sw(11);
    led(12) <= sw(12);
    led(13) <= sw(13);
    led(14) <= sw(14);
    led(15) <= sw(15);

    -- the leftmost 6 switches are the first number
    num1(0) <= sw(0);
    num1(1) <= sw(1);
    num1(2) <= sw(2);
    num1(3) <= sw(3);
    num1(4) <= sw(4);
    num1(5) <= sw(5);

    -- the next 6 switches are the second number
    num2(0) <= sw(6);
    num2(1) <= sw(7);
    num2(2) <= sw(8);
    num2(3) <= sw(9);
    num2(4) <= sw(10);
    num2(5) <= sw(11);

    -- the three rightmost switches control the operation to perform on the numbers 
    -- 000 add 
    -- 001 subtract num2 - num1
    -- 010 multiply 
    -- 011 or 
    -- 100 xor 
    -- 101 and 
    -- 110 num2 > num1 ?
    -- 111 num2 < num1 ?
    opeationChoice(0) <= sw(13);
    opeationChoice(1) <= sw(14);
    opeationChoice(2) <= sw(15);

    -- convert from binary to signed integer
    intNum1 <= conv_integer(num1);
    intNum2 <= CONV_INTEGER(num2);

    -- the only way I found to make this give the correct results is to perform the logic operations here ...
    orVal <= num2 or num1;
    xorVal <= num2 xor num1;
    andVal <= num2 and num1;
    -- and then convert to signed integers right after. When I did this within the case statement below, it would pad the numbers to 
    -- 8 bits. This led to no negative numbers  
    orNum <= conv_integer(orVal);
    xorNum <= conv_integer(xorVal);
    andNum <= conv_integer(andVal);

    process(opeationChoice, btnL, btnR)
    begin
        if(btnL = '1') then
        -- holding down the left button will display the value of num2 as an integer
            output <= intNum2;
        elsif(btnR = '1') then
        -- holding down the right button will display the value of num1 as an integer
            output <= intNum1;
        else
        -- show the result of the chosen operation
            case opeationChoice is
                when "000" => output <= intNum2 + intNum1;
                when "001" => output <= intNum2 - intNum1;
                when "010" => output <= intNum1 * intNum2;
                --            when "011" => output <= conv_integer(num2 or num1);
                --            when "100" => output <= conv_integer(num2 xor num1);
                --            when "101" => output <= conv_integer(num2 and num1);
                when "011" => output <= orNum;
                when "100" => output <= xorNum;
                when "101" => output <= andNum;
                when "110" => if intNum2 > intNum1 then output <= 1; else output <= 0; end if;
                when "111" => if intNum2 < intNum1 then output <= 1; else output <= 0; end if;
            end case;
        end if;
    end process;

    -- VHDL code for BCD to 7-segment decoder
    -- Cathode patterns of the 7-segment LED display 
    process(LED_BCD)
    begin
        case LED_BCD is
            when "00000" => LED_out <= "0000001"; -- "0"     
            when "00001" => LED_out <= "1001111"; -- "1" 
            when "00010" => LED_out <= "0010010"; -- "2" 
            when "00011" => LED_out <= "0000110"; -- "3" 
            when "00100" => LED_out <= "1001100"; -- "4" 
            when "00101" => LED_out <= "0100100"; -- "5" 
            when "00110" => LED_out <= "0100000"; -- "6" 
            when "00111" => LED_out <= "0001111"; -- "7" 
            when "01000" => LED_out <= "0000000"; -- "8"     
            when "01001" => LED_out <= "0000100"; -- "9" 
            when "01010" => LED_out <= "0000010"; -- a

            when "01011" => LED_out <= "1100000"; -- b
            when "01100" => LED_out <= "0110001"; -- C
            when "01101" => LED_out <= "1000010"; -- d
            when "01110" => LED_out <= "0110000"; -- E
            when "01111" => LED_out <= "0111000"; -- F
            when "10000" => LED_out <= "1111111"; -- off
            when "10001" => LED_out <= "1111110"; -- -
            when others => LED_out <= "1111111"; -- off

        end case;
    end process;
    -- 7-segment display controller
    -- generate refresh period of 10.5ms
    process(clock_100Mhz)
    begin
        if(rising_edge(clock_100Mhz)) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    LED_activating_counter <= refresh_counter(19 downto 18);
    -- 4-to-1 MUX to generate anode activating signals for 4 LEDs 
    process(LED_activating_counter)
        variable posVal, diffVal: integer;
        variable hundred, ten, one: integer;
        variable outVal: std_logic_vector(4 downto 0);
    begin
        case LED_activating_counter is
            when "00" =>
                Anode_Activate <= "0111";
                -- activate LED1 and Deactivate LED2, LED3, LED4
                if output < 0 then
                    LED_BCD <= "10001"; -- put in the negative sign
                else
                    LED_BCD <= "10000"; -- leave blank
                end if;
            when "01" =>
                Anode_Activate <= "1011";
                -- activate LED2 and Deactivate LED1, LED3, LED4
                posVal := abs(output);
                hundred := posVal/100; -- get the hundreds digit
                outVal := CONV_STD_LOGIC_VECTOR(hundred,5);
                LED_BCD <= outVal;
            when "10" =>
                Anode_Activate <= "1101";
                -- activate LED3 and Deactivate LED2, LED1, LED4
                posVal := abs(output);
                hundred := posVal/100;
                diffVal := posVal - hundred * 100;
                ten := diffVal / 10;
                outVal := CONV_STD_LOGIC_VECTOR(ten,5);
                LED_BCD <= outVal;
            when "11" =>
                Anode_Activate <= "1110";
                -- activate LED4 and Deactivate LED2, LED3, LED1
                posVal := abs(output);
                hundred := posVal/100;
                diffVal := posVal - hundred * 100;
                ten := diffVal / 10;
                one := diffVal - ten * 10;
                outVal := CONV_STD_LOGIC_VECTOR(one,5);
                LED_BCD <= outVal;
        end case;
    end process;

end Behavioral;
