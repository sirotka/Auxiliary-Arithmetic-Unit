----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/17/2026 10:32:32 PM
-- Design Name: 
-- Module Name: arith_unit - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity arith_unit is
    Port (
        clk          : in  STD_LOGIC;
        rst_in       : in  STD_LOGIC;

        data_fr1     : in  STD_LOGIC_VECTOR (15 downto 0);
        data_fr2     : in  STD_LOGIC_VECTOR (15 downto 0);
        we_data_fr1  : in  STD_LOGIC;
        we_data_fr2  : in  STD_LOGIC;

        add_res      : out STD_LOGIC_VECTOR (15 downto 0);
        mul_res      : out STD_LOGIC_VECTOR (15 downto 0)
    );
end arith_unit;

architecture Behavioral of arith_unit is

    signal operand1_reg : signed(15 downto 0) := (others => '0');
    signal operand2_reg : signed(15 downto 0) := (others => '0');

    signal add_res_reg  : signed(15 downto 0) := (others => '0');
    signal mul_res_reg  : signed(15 downto 0) := (others => '0');

begin

    p_arith : process(clk)
        variable add_full   : signed(16 downto 0);
        variable mul_full   : signed(31 downto 0);
        variable mul_scaled : signed(31 downto 0);
    begin
        if rising_edge(clk) then

            if rst_in = '1' then
                operand1_reg <= (others => '0');
                operand2_reg <= (others => '0');
                add_res_reg  <= (others => '0');
                mul_res_reg  <= (others => '0');

            else

                if we_data_fr1 = '1' then
                    operand1_reg <= signed(data_fr1);
                end if;

                if we_data_fr2 = '1' then
                    operand2_reg <= signed(data_fr2);

                    add_full :=
                        resize(operand1_reg, 17) +
                        resize(signed(data_fr2), 17);

                    if add_full > to_signed(32767, 17) then
                        add_res_reg <= to_signed(32767, 16);

                    elsif add_full < to_signed(-32768, 17) then
                        add_res_reg <= to_signed(-32768, 16);

                    else
                        add_res_reg <= resize(add_full, 16);
                    end if;


                    mul_full :=
                        operand1_reg * signed(data_fr2);

                    mul_scaled :=
                        shift_right(mul_full, 8);

                    if mul_scaled > to_signed(32767, 32) then
                        mul_res_reg <= to_signed(32767, 16);

                    elsif mul_scaled < to_signed(-32768, 32) then
                        mul_res_reg <= to_signed(-32768, 16);

                    else
                        mul_res_reg <= resize(mul_scaled, 16);
                    end if;

                end if;

            end if;

        end if;
    end process;


    add_res <= std_logic_vector(add_res_reg);
    mul_res <= std_logic_vector(mul_res_reg);

end Behavioral;
