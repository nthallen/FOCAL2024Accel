%%
CORE_FREQ = 4.0e6;
BAUD = 15000;
TRISE = 215;
BAUD_LOW = floor(((CORE_FREQ-BAUD*10-floor(TRISE*floor(BAUD/10)*floor(CORE_FREQ/10000)/1000)) ...
  *10 + 5)/(BAUD*10));
