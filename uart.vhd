-- uart.vhd: UART controller - receiving part
-- Author(s): Patrik Sehnoutek (xsehno01) 
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------
entity UART_RX is
port(	
  CLK		      : 	in std_logic;
	RST		      : 	in std_logic;
	DIN	     	 : 	in std_logic;
	DOUT		     : 	out std_logic_vector(7 downto 0);
	DOUT_VLD	  : 	out std_logic
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is
signal cnt_din 			      : std_logic_vector(3 downto 0);
signal cnt_to_mid  		   : std_logic_vector(4 downto 0);
signal reading_en 		    : std_logic;
signal cnt_to_mid_en 	  : std_logic;
signal clr_mid          : std_logic;
signal clr_din          : std_logic;
signal vld              : std_logic;

begin
	finite_state_machine : entity work.UART_FSM(behavioral)
	port map ( 
		CLK			  	       => CLK,
		RST				        => RST,
		DIN				        => DIN,
		CNT_DIN			      => cnt_din,
		CNT_TO_MID 		   => cnt_to_mid,
		VLD			          => vld,
		READING_EN		    => reading_en,
		CNT_TO_MID_EN   => cnt_to_mid_en
	);	
	
	-- Count clock cycles to mid bit
	--   firstly it is used to count 24 clock cycles,
	--   (the beginning of start bit -> midbit of first bit)
	--   then it is used to count 16 clock cycles,
	--   (every 16th clock cycle is midbit)
	count_to_mid: process (CLK)
	begin
	  if CLK'event and CLK = '1' then
	    if cnt_to_mid_en = '1' then
	      if clr_mid = '1' then
	        cnt_to_mid <= "00000";
	      else
	        cnt_to_mid <= cnt_to_mid + 1;
	      end if;
	    else
	      cnt_to_mid <= "00000";
	    end if;
	  end if;
	end process;
	-- 15 CLK increase counter + 1 CLK reset = 16 CLK
	clr_mid <= '1' when ((cnt_to_mid = "01111" or cnt_to_mid(4) ='1') and reading_en = '1') else '0';  
	
	-- Count the read data
	count_din: process (CLK)
	begin
    if CLK'event and CLK = '1' then
	    if reading_en = '1' then
	      if clr_din = '1' then
	        cnt_din <= "0000";
	      elsif (cnt_to_mid = "01111" or cnt_to_mid(4) = '1') then
	        cnt_din <= cnt_din + 1;
	      end if;
	     else
	      cnt_din <= "0000";
	    end if;
	  end if; 
	end process;
	clr_din <= '1' when (cnt_din = "1000") else '0';
			
  -- Read data from input
  read_data : process (CLK, RST)
  begin
    if (RST = '1') then
      DOUT <= "00000000";
    elsif CLK'event and CLK = '1' then
      if reading_en = '1' and (cnt_to_mid = "01111" or cnt_to_mid(4) = '1') then
        --write input bit to output
    			  if cnt_din="0000" then 
        		   DOUT(0) <= DIN;
            elsif	cnt_din="0001" then 
               DOUT(1) <= DIN;
            elsif cnt_din="0010" then 
               DOUT(2) <= DIN;
            elsif cnt_din="0011" then 
               DOUT(3) <= DIN;
            elsif cnt_din="0100" then 
                 DOUT(4) <= DIN;
              elsif cnt_din="0101" then 
               DOUT(5) <= DIN;
            elsif cnt_din="0110" then 
               DOUT(6) <= DIN;
            elsif cnt_din="0111" then 
      			     DOUT(7) <= DIN;
  				  end if; 
      end if;
    end if;
  end process;
  
  -- Validate output data
  vld_data : process (CLK)
  begin
    if CLK'event and CLK = '1' then
      if (vld = '1') then
        DOUT_VLD <= '1';
      else
        DOUT_VLD <= '0';
      end if;
    
    end if; 
  end process;
	
end behavioral;
