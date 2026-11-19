----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/15/2026 11:38:57 PM
-- Design Name: 
-- Module Name: spi_if - Behavioral
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

entity spi_if is
    Port ( clk : in STD_LOGIC;
           rst_in : in STD_LOGIC;
           SCLK : in STD_LOGIC;
           CS_b : in STD_LOGIC;
           MOSI : in STD_LOGIC;
           MISO : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (15 downto 0);
           data_in : in STD_LOGIC_VECTOR (15 downto 0);
           load_data : in STD_LOGIC;
           fr_start : out STD_LOGIC;
           fr_end : out STD_LOGIC;
           fr_err : out STD_LOGIC);
end spi_if;

architecture Behavioral of spi_if is
    signal sclk_meta : std_logic := '1';
    signal sclk_sync : std_logic := '1';
    signal sclk_prev : std_logic := '1';

    signal cs_meta   : std_logic := '1';
    signal cs_sync   : std_logic := '1';
    signal cs_prev   : std_logic := '1';

    signal mosi_meta : std_logic := '0';
    signal mosi_sync : std_logic := '0';

    signal sclk_re   : std_logic;
    signal sclk_fe   : std_logic;

    signal cs_re     : std_logic;
    signal cs_fe     : std_logic;
    
    signal rx_shift  : std_logic_vector(15 downto 0) := (others => '0');
    signal bit_count : integer range 0 to 31 := 0;

    signal tx_shift : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_count : integer range 0 to 15 := 0;
    signal miso_reg : std_logic := '0';

begin
    
    p_sync : process(clk)
    begin
        if rising_edge(clk) then

            if rst_in = '1' then
                sclk_meta <= '1';
                sclk_sync <= '1';
                sclk_prev <= '1';

                cs_meta   <= '1';
                cs_sync   <= '1';
                cs_prev   <= '1';

                mosi_meta <= '0';
                mosi_sync <= '0';

            else
                sclk_meta <= SCLK;
                sclk_sync <= sclk_meta;
                sclk_prev <= sclk_sync;

                cs_meta   <= CS_b;
                cs_sync   <= cs_meta;
                cs_prev   <= cs_sync;

                mosi_meta <= MOSI;
                mosi_sync <= mosi_meta;
            end if;

        end if;
    end process;


    sclk_re <= sclk_sync and not sclk_prev;
    sclk_fe <= not sclk_sync and sclk_prev;

    cs_re <= cs_sync and not cs_prev;
    cs_fe <= not cs_sync and cs_prev;
    
    p_rx : process(clk)
    begin
        if rising_edge(clk) then

            -- Default values
            fr_start <= '0';
            fr_end   <= '0';
            fr_err   <= '0';

            if rst_in = '1' then
                rx_shift  <= (others => '0');
                bit_count <= 0;
                data_out  <= (others => '0');

            else

                -- Start of frame
                if cs_fe = '1' then
                    rx_shift  <= (others => '0');
                    bit_count <= 0;
                    fr_start  <= '1';

                -- End of frame
                elsif cs_re = '1' then

                    fr_end <= '1';

                    if bit_count = 16 then
                        data_out <= rx_shift;
                    else
                        fr_err <= '1';
                    end if;

                -- Receive bit from MOSI
                elsif (cs_sync = '0') and (sclk_re = '1') then

                    if bit_count < 16 then
                        rx_shift(bit_count) <= mosi_sync;
                    end if;

                    if bit_count < 31 then
                        bit_count <= bit_count + 1;
                    end if;

                end if;

            end if;

        end if;
    end process;


    p_tx : process(clk)
    begin
        if rising_edge(clk) then

            if rst_in = '1' then
                tx_shift <= (others => '0');
                tx_count <= 0;
                miso_reg <= '0';

            else

                -- Load data to be transmitted
                if load_data = '1' then
                    tx_shift <= data_in;
                end if;

                -- Start of frame
                if cs_fe = '1' then
                    tx_count <= 0;

                -- Send next bit on falling edge of SCLK
                elsif (cs_sync = '0') and (sclk_fe = '1') then
                    miso_reg <= tx_shift(tx_count);

                    if tx_count < 15 then
                        tx_count <= tx_count + 1;
                    end if;

                -- End of frame
                elsif cs_re = '1' then
                    miso_reg <= '0';
                end if;

            end if;

        end if;
    end process;


    MISO <= miso_reg;

end Behavioral;
