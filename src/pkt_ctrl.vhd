----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/17/2026 09:26:05 PM
-- Design Name: 
-- Module Name: pkt_ctrl - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pkt_ctrl is
    Port (
        clk          : in  STD_LOGIC;
        rst_in       : in  STD_LOGIC;
        fr_start     : in  STD_LOGIC;
        fr_end       : in  STD_LOGIC;
        fr_err       : in  STD_LOGIC;
        data_out     : in  STD_LOGIC_VECTOR (15 downto 0);
        data_in      : out STD_LOGIC_VECTOR (15 downto 0);
        wr_data      : out STD_LOGIC;
        data_fr1     : out STD_LOGIC_VECTOR (15 downto 0);
        data_fr2     : out STD_LOGIC_VECTOR (15 downto 0);
        we_data_fr1  : out STD_LOGIC;
        we_data_fr2  : out STD_LOGIC;
        add_res      : in  STD_LOGIC_VECTOR (15 downto 0);
        mul_res      : in  STD_LOGIC_VECTOR (15 downto 0)
    );
end pkt_ctrl;

architecture Behavioral of pkt_ctrl is

    type t_state is (
        WAIT_FR1,
        RECEIVE_FR1,
        WAIT_FR2,
        RECEIVE_FR2
    );

    constant c_TIMEOUT_CYCLES : natural := 100000;

    signal current_state : t_state := WAIT_FR1;
    signal next_state    : t_state := WAIT_FR1;

    signal timeout_count : natural range 0 to c_TIMEOUT_CYCLES := 0;
    signal timeout       : std_logic := '0';

begin

    p_state_reg : process(clk)
    begin
        if rising_edge(clk) then
            if rst_in = '1' then
                current_state <= WAIT_FR1;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;


    p_next_state : process(current_state, fr_start, fr_end, fr_err, timeout)
    begin
        next_state <= current_state;

        case current_state is

            when WAIT_FR1 =>
                if fr_start = '1' then
                    next_state <= RECEIVE_FR1;
                end if;

            when RECEIVE_FR1 =>
                if fr_err = '1' then
                    next_state <= WAIT_FR1;
                elsif fr_end = '1' then
                    next_state <= WAIT_FR2;
                end if;

            when WAIT_FR2 =>
                if fr_start = '1' then
                    next_state <= RECEIVE_FR2;
                elsif timeout = '1' then
                    next_state <= WAIT_FR1;
                end if;

            when RECEIVE_FR2 =>
                if fr_err = '1' then
                    next_state <= WAIT_FR1;
                elsif fr_end = '1' then
                    next_state <= WAIT_FR1;
                end if;

            when others =>
                next_state <= WAIT_FR1;

        end case;
    end process;


    p_timeout : process(clk)
    begin
        if rising_edge(clk) then

            timeout <= '0';

            if rst_in = '1' then
                timeout_count <= 0;

            elsif current_state /= WAIT_FR2 then
                timeout_count <= 0;

            elsif fr_start = '1' then
                timeout_count <= 0;

            elsif timeout_count = c_TIMEOUT_CYCLES - 1 then
                timeout_count <= 0;
                timeout <= '1';

            else
                timeout_count <= timeout_count + 1;
            end if;

        end if;
    end process;


    p_data : process(clk)
    begin
        if rising_edge(clk) then

            we_data_fr1 <= '0';
            we_data_fr2 <= '0';

            if rst_in = '1' then
                data_fr1 <= (others => '0');
                data_fr2 <= (others => '0');

            else

                case current_state is

                    when RECEIVE_FR1 =>
                        if (fr_end = '1') and (fr_err = '0') then
                            data_fr1    <= data_out;
                            we_data_fr1 <= '1';
                        end if;

                    when RECEIVE_FR2 =>
                        if (fr_end = '1') and (fr_err = '0') then
                            data_fr2    <= data_out;
                            we_data_fr2 <= '1';
                        end if;

                    when others =>
                        null;

                end case;

            end if;

        end if;
    end process;


    p_tx : process(clk)
    begin
        if rising_edge(clk) then

            wr_data <= '0';

            if rst_in = '1' then
                data_in <= (others => '0');

            else

                if fr_start = '1' then

                    case current_state is

                        when WAIT_FR1 =>
                            data_in <= add_res;
                            wr_data <= '1';

                        when WAIT_FR2 =>
                            data_in <= mul_res;
                            wr_data <= '1';

                        when others =>
                            null;

                    end case;

                end if;

            end if;

        end if;
    end process;

end Behavioral;