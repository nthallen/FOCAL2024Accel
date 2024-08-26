#include "commands.h"
#include "serial_num.h"
#include "subbus.h"
#include "rtc_timer.h"
#ifdef HAVE_VIBE_SENSOR
#include "i2c_icm20948.h"
#endif

static void commands_init(void) {
}

// Cache , Wvalue, readable, was_read, writable, written, dynamic
// I2C Status I2C_ICM_STATUS_NREGS
static subbus_cache_word_t cmd_cache[CMD_HIGH_ADDR-CMD_BASE_ADDR+1] = {
  { 0, 0, false,  false, true, false, false } // Offset 0: R: ADC Flow 0
};


#ifdef TIMED_COMMANDS

typedef struct {
  int when;
  uint16_t cmd;
} timed_cmd_t;

static timed_cmd_t timed_cmds[] = TIMED_COMMANDS;
#define N_TIMED_CMDS (sizeof(timed_cmds)/sizeof(timed_cmd_t))
static int timed_cmds_executed = 0;

#endif

static void cmd_poll(void) {
  uint16_t cmd;

#ifdef N_TIMED_CMDS
  bool have_cmd = false;
  if (timed_cmds_executed < N_TIMED_CMDS && rtc_current_count >= timed_cmds[timed_cmds_executed].when) {
    cmd = timed_cmds[timed_cmds_executed++].cmd;
    have_cmd = true;
  } else if (subbus_cache_iswritten(&sb_cmd, CMD_BASE_ADDR, &cmd)) {
    have_cmd = true;
  }
  if (have_cmd) {
#else
  if (subbus_cache_iswritten(&sb_cmd, CMD_BASE_ADDR, &cmd)) {
#endif
#ifdef HAVE_VIBE_SENSOR
    switch (cmd) {
      case 40: i2c_icm_set_mode(ICM_MODE_NO); break;
      case 41: i2c_icm_set_mode(ICM_MODE_SLOW); break;
      case 42: i2c_icm_set_mode(ICM_MODE_FAST); break;
      case 43: i2c_icm_set_mode(ICM_MODE_MAXG); break;
      case 50: i2c_icm_set_fs(ICM_FS_2G); break;
      case 51: i2c_icm_set_fs(ICM_FS_4G); break;
      case 52: i2c_icm_set_fs(ICM_FS_8G); break;
      case 53: i2c_icm_set_fs(ICM_FS_16G); break;
      default: break;
    }
#endif
  }
}

static void cmd_reset(void) {
  commands_init();
  if (!sb_cmd.initialized) {
    sb_cmd.initialized = true;
  }
}

subbus_driver_t sb_cmd = {
  CMD_BASE_ADDR, CMD_HIGH_ADDR, // address range
  cmd_cache,
  cmd_reset,
  cmd_poll,
  false
};
