----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/16/2026 12:10:47 AM
-- Design Name: 
-- Module Name: tb_aau - Behavioral
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

entity tb_aau is
end tb_aau;

architecture Behavioral of tb_aau is

    constant c_CLK_per  : time := 10 ns;
    constant c_SCLK_per : time := 1 us;
    constant c_DATA_W   : natural := 16;

    type t_SPI_MOSI is record
        SCLK : std_logic;
        CS_b : std_logic;
        MOSI : std_logic;
    end record;

    type t_SPI_MISO is record
        MISO : std_logic;
    end record;

    signal run_clk_gen : std_logic := '0';
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';

    signal dut_mosi : t_SPI_MOSI;
    signal dut_miso : t_SPI_MISO;


    procedure send_frame(
        constant data_in  : in  integer;
        variable data_out : out integer;
        signal spi_mosi   : out t_SPI_MOSI;
        signal spi_miso   : in  t_SPI_MISO
    ) is

        variable data2send : std_logic_vector(c_DATA_W-1 downto 0);
        variable data_rcv  : std_logic_vector(c_DATA_W-1 downto 0);

    begin

        data2send := std_logic_vector(to_signed(data_in, c_DATA_W));

        spi_mosi.CS_b <= '0';

        for idx in 0 to c_DATA_W-1 loop

            wait for c_SCLK_per/2;

            spi_mosi.SCLK <= '0';
            spi_mosi.MOSI <= data2send(idx);

            wait for c_SCLK_per/2;

            spi_mosi.SCLK <= '1';
            data_rcv(idx) := spi_miso.MISO;

        end loop;

        wait for c_SCLK_per/2;

        spi_mosi.CS_b <= '1';

        data_out := to_integer(signed(data_rcv));

    end procedure;


    procedure test_operation(
        constant test_name    : in string;
        constant operand1     : in integer;
        constant operand2     : in integer;
        constant expected_sum : in integer;
        constant expected_mul : in integer;
        signal spi_mosi       : out t_SPI_MOSI;
        signal spi_miso       : in  t_SPI_MISO
    ) is

        variable tmp1    : integer;
        variable tmp2    : integer;
        variable sum_res : integer;
        variable mul_res : integer;

    begin

        send_frame(operand1, tmp1, spi_mosi, spi_miso);
        wait for c_SCLK_per*2;

        send_frame(operand2, tmp2, spi_mosi, spi_miso);
        wait for c_SCLK_per*2;

        send_frame(0, sum_res, spi_mosi, spi_miso);
        wait for c_SCLK_per*2;

        send_frame(0, mul_res, spi_mosi, spi_miso);
        wait for c_SCLK_per*2;

        report test_name & " sum: " & integer'image(sum_res);
        report test_name & " mul: " & integer'image(mul_res);

        if sum_res /= expected_sum then
            report test_name & " SUM ERROR" severity error;
        else
            report test_name & " SUM OK" severity note;
        end if;

        if mul_res /= expected_mul then
            report test_name & " MUL ERROR" severity error;
        else
            report test_name & " MUL OK" severity note;
        end if;

    end procedure;


begin

    i_dut : entity work.top_aau(structural)
        port map (
            clk    => clk,
            rst_in => rst,
            SCLK   => dut_mosi.SCLK,
            CS_b   => dut_mosi.CS_b,
            MOSI   => dut_mosi.MOSI,
            MISO   => dut_miso.MISO
        );


    p_clk_bfm : process
    begin

        if run_clk_gen = '1' then
            clk <= '0';
            wait for c_CLK_per/2;

            clk <= '1';
            wait for c_CLK_per/2;

        else
            wait until run_clk_gen = '1';
        end if;

    end process;


    p_stimuli : process
    begin

        dut_mosi.CS_b <= '1';
        dut_mosi.SCLK <= '1';
        dut_mosi.MOSI <= '0';

        run_clk_gen <= '1';

        rst <= '1';
        wait for 10*c_CLK_per;

        rst <= '0';
        wait for 10*c_CLK_per;


        test_operation(
            "TC_BASIC",
            512,
            768,
            1280,
            1536,
            dut_mosi,
            dut_miso
        );


        test_operation(
            "TC_NEGATIVE",
            -512,
            768,
            256,
            -1536,
            dut_mosi,
            dut_miso
        );


        test_operation(
            "TC_FLOOR",
            300,
            -200,
            100,
            -235,
            dut_mosi,
            dut_miso
        );


        test_operation(
            "TC_POS_SAT",
            25600,
            25600,
            32767,
            32767,
            dut_mosi,
            dut_miso
        );


        test_operation(
            "TC_NEG_SUM_SAT",
            -25600,
            -25600,
            -32768,
            32767,
            dut_mosi,
            dut_miso
        );


        test_operation(
            "TC_NEG_MUL_SAT",
            -25600,
            25600,
            0,
            -32768,
            dut_mosi,
            dut_miso
        );


        wait for 10*c_CLK_per;

        run_clk_gen <= '0';

        report "Simulation done" severity note;

        wait;

    end process;

end Behavioral;