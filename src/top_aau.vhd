----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/15/2026 11:33:58 PM
-- Design Name: 
-- Module Name: top_aau - structural
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

entity top_aau is
    Port (
        clk    : in  STD_LOGIC;
        rst_in : in  STD_LOGIC;
        SCLK   : in  STD_LOGIC;
        CS_b   : in  STD_LOGIC;
        MOSI   : in  STD_LOGIC;
        MISO   : out STD_LOGIC
    );
end top_aau;

architecture structural of top_aau is

    signal spi_data_out : std_logic_vector(15 downto 0);
    signal spi_data_in  : std_logic_vector(15 downto 0);

    signal fr_start : std_logic;
    signal fr_end   : std_logic;
    signal fr_err   : std_logic;
    signal wr_data  : std_logic;

    signal data_fr1    : std_logic_vector(15 downto 0);
    signal data_fr2    : std_logic_vector(15 downto 0);
    signal we_data_fr1 : std_logic;
    signal we_data_fr2 : std_logic;

    signal add_res : std_logic_vector(15 downto 0);
    signal mul_res : std_logic_vector(15 downto 0);

begin

    i_spi_if : entity work.spi_if(Behavioral)
        port map (
            clk       => clk,
            rst_in    => rst_in,
            SCLK      => SCLK,
            CS_b      => CS_b,
            MOSI      => MOSI,
            MISO      => MISO,
            data_out  => spi_data_out,
            data_in   => spi_data_in,
            load_data => wr_data,
            fr_start  => fr_start,
            fr_end    => fr_end,
            fr_err    => fr_err
        );


    i_pkt_ctrl : entity work.pkt_ctrl(Behavioral)
        port map (
            clk         => clk,
            rst_in      => rst_in,
            fr_start    => fr_start,
            fr_end      => fr_end,
            fr_err      => fr_err,
            data_out    => spi_data_out,
            data_in     => spi_data_in,
            wr_data     => wr_data,
            data_fr1    => data_fr1,
            data_fr2    => data_fr2,
            we_data_fr1 => we_data_fr1,
            we_data_fr2 => we_data_fr2,
            add_res     => add_res,
            mul_res     => mul_res
        );


    i_arith_unit : entity work.arith_unit(Behavioral)
        port map (
            clk         => clk,
            rst_in      => rst_in,
            data_fr1    => data_fr1,
            data_fr2    => data_fr2,
            we_data_fr1 => we_data_fr1,
            we_data_fr2 => we_data_fr2,
            add_res     => add_res,
            mul_res     => mul_res
        );

end structural;