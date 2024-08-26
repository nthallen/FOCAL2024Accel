#ifdef __cplusplus
extern "C" {
#endif

// #include "gps_drv_init.h"
#include <hal_init.h>
#include "gps_usb.h"
#include "commands.h"
#include "ser_control.h"
#include "rtc_timer.h"
#include "i2c_icm20948.h"
#include "ser_control.h"

#ifdef __cplusplus
}
#endif

int main(void)
{
	/* Initializes MCU, drivers and middleware */
	init_mcu();

  if (subbus_add_driver(&sb_base)
   || subbus_add_driver(&sb_fail_sw)
   || subbus_add_driver(&sb_board_desc)
   || subbus_add_driver(&sb_cmd)
#ifdef CTRL_USB_SER
   || subbus_add_driver(&sb_usb)
#endif
   || subbus_add_driver(&sb_rtc)
   || subbus_add_driver(&sb_i2c_icm)
   || subbus_add_driver(&sb_control)
  ) {
    while (true) ; // some driver is misconfigured.
  }
  subbus_reset(); // Resets all drivers
  while (1) {
    subbus_poll();
  }
}
