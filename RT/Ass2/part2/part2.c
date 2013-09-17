#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

DeclareTask(MotorcontrolTask);
DeclareTask(EventdispatcherTask);
DeclareEvent(TouchOnEvent);
DeclareEvent(TouchOffEvent);
DeclareEvent(LightChangeEvent);

#define LIGHTSENSOR NXT_PORT_S1
#define TOUCHSENSOR NXT_PORT_S2
#define LIGHTVAL ecrobot_get_light_sensor(LIGHTSENSOR)
#define TOUCHVAL ecrobot_get_touch_sensor(TOUCHSENSOR)

void user_1ms_isr_type2(void) {}

void ecrobot_device_initialize() {
  ecrobot_set_light_sensor_active(LIGHTSENSOR);
}
void ecrobot_device_terminate() {
  ecrobot_set_light_sensor_inactive(LIGHTSENSOR);
}

/* This function will print the light intensity on the LCD */
void display_light_intensity() {
  display_clear(1);
  display_goto_xy(0,0);
  display_string("Light: ");
  display_unsigned(LIGHTVAL, 3);
  display_update();
}

/*  This function will take 10 light intensity values, waiting 100ms between each measurement
    and return the mean measurement value. This is used for initial calibration */
int light_calibration_proc() {
  int threshold = 0;
  for (int i = 0; i < 10; i++){
    threshold += LIGHTVAL;
    systick_wait_ms(100);
  }
  return threshold /= 10;
}

TASK(EventdispatcherTask){
  /* state is TRUE when the button is pressed, else FALSE */ 
  int state = FALSE;
  /* Threshold holds the initial light settings. The robot must be on the working surface when initialized */	
  int threshold = light_calibration_proc();
  
  while (TRUE) { /* Forever! */
    if (state != TOUCHVAL) { /* If state has changed */
      state = !state; /* State changed, so we update the variable */
      if (state) /* If button pressed */
	SetEvent(MotorcontrolTask, TouchOnEvent); /* Signal motors to run */
      else
	SetEvent(MotorcontrolTask, TouchOffEvent); /* Signal motors to stop */
    }
    
    if (state && LIGHTVAL >= threshold*1.05){ /* If we're running, and the table can't be detected */
      SetEvent(MotorcontrolTask, LightChangeEvent); /* Stop the motors */
      state = !state;
    }
    display_light_intensity(); /* Update the light values on the display*/
    systick_wait_ms(100); /* Do we need this? */
  }
}

TASK(MotorcontrolTask) {
  while(true) {
    WaitEvent(TouchOnEvent); /* Wait until told to drive */
    ClearEvent(TouchOnEvent);
    nxt_motor_set_speed(NXT_PORT_A, 100, 0);
    nxt_motor_set_speed(NXT_PORT_B, 100, 0);
    
    /* Wait for a break command, either from a button release or because the table went undetected */
    WaitEvent(TouchOffEvent | LightChangeEvent); 
    ClearEvent(TouchOffEvent);   
    ClearEvent(LightChangeEvent);
    nxt_motor_set_speed(NXT_PORT_A, 0, 1); /* Break */
    nxt_motor_set_speed(NXT_PORT_B, 0, 1);
  }
}

