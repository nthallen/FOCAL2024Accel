/*
 * This file is based on code originally generated from Atmel START as usb_start.h
 * Whenever the Atmel START project is updated, changes to usb_start.h must be
 * reviewed and copied here as appropriate.
 */
#ifndef GPS_USB_H
#define GPS_USB_H
#include "gps_pins.h"
#include "subbus.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#include "hal_usb_device.h"

#include "cdcdf_acm.h"
#include "cdcdf_acm_desc.h"

void cdc_device_acm_init(void);

void USB_CTRL_CLOCK_init(void);
void USB_CTRL_init(void);

subbus_driver_t sb_usb;
#define SUBBUS_USB_BASE_ADDR 0xC
#define SUBBUS_USB_HIGH_ADDR (SUBBUS_USB_BASE_ADDR-1)
#define CDC_INPUT_BUFFER_SIZE 256
#define CDC_OUTPUT_BUFFER_SIZE 256

void usb_ser_init(void);
int  usb_ser_recv(uint8_t *buf, int nbytes);
int  usb_ser_write(const char *msg, int n);
void usb_ser_send_char(uint8_t c);
void usb_ser_flush_input(void);
void usb_ser_flush_output(void);

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // GPS_USB_H
