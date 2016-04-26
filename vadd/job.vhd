LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY job_control IS
PORT
(
  -- AFU Control Interface
  ha_jval           :  IN STD_LOGIC;
  ha_jcom           :  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  ha_jcompar        :  IN STD_LOGIC;
  ha_jea            :  IN STD_LOGIC_VECTOR(63 DOWNTO 0);
  ha_jeapar         :  IN STD_LOGIC;
  ah_jrunning       : OUT STD_LOGIC;
  ah_jdone          : OUT STD_LOGIC;
  ah_jcack          : OUT STD_LOGIC;
  ah_jerror         : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
  ah_jyield         : OUT STD_LOGIC;
  ah_tbreq          : OUT STD_LOGIC;
  ah_paren          : OUT STD_LOGIC;
  ha_pclock         :  IN STD_LOGIC
);
END ENTITY;

ARCHITECTURE logic OF job_control IS

-- Control Commands on ha_jcom
CONSTANT START    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"90";
CONSTANT RESTART  : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"80";
-- States in the state machine
TYPE JOB_STATE IS (POWERON, RESET, AFU_WAIT, RUNNING, DONE);

SIGNAL afu_cur_state    : JOB_STATE := POWERON;
SIGNAL afu_next_state   : JOB_STATE := POWERON;
SIGNAL datapath_running : STD_LOGIC;
SIGNAL datapath_done    : STD_LOGIC;
SIGNAL reset_ack        : STD_LOGIC;

BEGIN

  my_state: PROCESS(ha_pclock, afu_cur_state, ha_jval)
  BEGIN
    -- Always handle incoming request
    IF(ha_jval = '1') THEN
      CASE ha_jcom IS
        WHEN START =>
          afu_next_state <= RUNNING;
        WHEN RESTART =>
          afu_next_state <= RESET;
        WHEN OTHERS =>
          afu_next_state <= afu_cur_state;
      END CASE;
    ELSE
      CASE afu_cur_state IS
        WHEN RESET =>
          afu_next_state <= AFU_WAIT;
        WHEN RUNNING =>
          afu_next_state <= DONE;
        WHEN DONE =>
          afu_next_state <= AFU_WAIT;
        WHEN OTHERS =>
          afu_next_state <= afu_cur_state;
      END CASE;
    END IF;
    IF(ha_pclock = '1' AND ha_pclock'EVENT) THEN
      afu_cur_state <= afu_next_state;
    END IF;
  END PROCESS;

  my_signals: PROCESS(afu_cur_state, ha_pclock)
  BEGIN
    datapath_running <='0';
    reset_ack <= '0';
    datapath_done<= '0';    
    CASE afu_cur_state IS
      WHEN POWERON =>
      WHEN AFU_WAIT =>
      WHEN RUNNING =>
        datapath_running <='1';
      WHEN RESET =>
        reset_ack <= '1';
      WHEN DONE =>
        datapath_done <='1';
    END CASE;
  END PROCESS;

  ah_jdone <= datapath_done or reset_ack;
  ah_jrunning <= datapath_running;
  -- AFU supports parity on PSL Interfaces
  ah_paren <= '1';
  -- AFU ignores errors and does not forward them to host
  ah_jerror <= (OTHERS => '0');
  -- Signals below are unused and set to default values 
  ah_jcack <= '0';
  ah_jyield <= '0';
  ah_tbreq <= '0';

END logic;
