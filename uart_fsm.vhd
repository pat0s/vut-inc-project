-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): Patrik Sehnoutek (xsehno01)
--
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
port(
  CLK              : in std_logic;
  RST              : in std_logic;
	DIN              : in std_logic;
	CNT_DIN          : in std_logic_vector(3 downto 0);
	CNT_TO_MID       : in std_logic_vector(4 downto 0);
	READING_EN       : out std_logic;
	CNT_TO_MID_EN    : out std_logic;
	VLD              : out std_logic
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
	-- all possible states
	type possible_states is (WAIT_FOR_START, WAIT_FOR_ZERO_BIT,
									READ_DATA, WAIT_FOR_STOP);
	signal current_state : possible_states;
	signal next_state : possible_states;
begin 
  -- Current state logic
	current_state_logic: process(CLK, RST)
	begin				
		-- reset FSM
		if (RST='1') then
			current_state <= WAIT_FOR_START;
		elsif CLK'event and CLK='1' then
			-- change current state
		  current_state <= next_state;
		end if;
	end process;
	
	-- Next state logic
	next_state_logic: process(current_state, DIN, CNT_TO_MID, CNT_DIN)
	begin
		case current_state is
				when WAIT_FOR_START =>
					if DIN='0' then
						next_state <= WAIT_FOR_ZERO_BIT;
					end if;
				when WAIT_FOR_ZERO_BIT =>
				  -- 23 CLK increase counter + 1 CLK reset = 24 CLK
					if CNT_TO_MID="10111" then
						next_state <= READ_DATA;
					end if;
				when READ_DATA =>
					if CNT_DIN="1000" then
						next_state <= WAIT_FOR_STOP;
					end if;
				when WAIT_FOR_STOP =>
					if DIN='1' then
						next_state <= WAIT_FOR_START;
					end if;
				when others => null;					
			end case;
	end process;
	
	-- Output logic
	output_logic: process(DIN, current_state)
	begin
	  case current_state is
	    when WAIT_FOR_START =>
	      VLD <= '0';
	      CNT_TO_MID_EN <= '0';
	      READING_EN <= '0';
	    when WAIT_FOR_ZERO_BIT =>
	      CNT_TO_MID_EN <= '1';
	      READING_EN <= '0';
	    when READ_DATA =>
	      CNT_TO_MID_EN <= '1';
	      READING_EN <= '1';
	    when WAIT_FOR_STOP =>
	      if (DIN = '1') then
	        VLD <= '1';
	      end if;
	      CNT_TO_MID_EN <= '0';
	      READING_EN <= '0';
	    when others =>
	      VLD <= '0';
	      CNT_TO_MID_EN <= '0';
	      READING_EN <= '0';
	  end case;
	end process;

end behavioral;
