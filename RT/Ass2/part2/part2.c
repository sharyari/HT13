#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

DeclareTask(MotorcontrolTask);
DeclareTask(EventdispatcherTask);
DeclareEvent(TouchOnEvent);
DeclareEvent(TouchOffEvent);
DeclareEvent(LightOnEvent);
DeclareEvent(LightOffEvent);

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
    systick_wait_ms(10);
  }
  return threshold /= 10;
}

TASK(EventdispatcherTask){
  /* buttonState is TRUE when the button is pressed, else FALSE */ 
  int buttonState = FALSE;
  /* tableState is TRUE when we are on the table, otherwise FALSE */
  int tableState = TRUE;

  /* Threshold holds the initial light settings. The robot must be on the working surface when initialized */	
  int threshold = light_calibration_proc();
  
  while (TRUE) { /* Forever! */
    if (buttonState != TOUCHVAL) { /* If button state has changed */
      buttonState = !buttonState; /* State changed, so we update the variable */
      if (buttonState) /* If button pressed */
	SetEvent(MotorcontrolTask, TouchOnEvent); /* Signal motors ok to run */
      else
	SetEvent(MotorcontrolTask, TouchOffEvent); /* Signal motors must stop */
    }
    
    if (tableState != (LIGHTVAL >= threshold*1.05)){ /* If the table state has changed */
      tableState = !tableState;
      if(tableState)
	SetEvent(MotorcontrolTask, LightOffEvent); /* Signal motors must stop */
      else
	SetEvent(MotorcontrolTask, LightOnEvent); /* Signal motors ok to run */
    }
    display_light_intensity(); /* Update the light values on the display*/
    systick_wait_ms(100); /* Do we need this? */
  }
}

TASK(MotorcontrolTask) {
  
  int table = FALSE;
  int button = FALSE;
  int okToDrive = FALSE;
  
  EventMaskType eventmask = 0;
  
  while(true) {

    /* The only time we have to reevaluate if it is ok to run is when something changes, so wait for the events. */
    WaitEvent(TouchOnEvent | LightOnEvent | TouchOffEvent | LightOffEvent);
    GetEvent(MotorcontrolTask, &eventmask);

    /* Set the state of button and table according to the recieved event. */
    if(eventmask & TouchOnEvent) {
      button = TRUE;
      ClearEvent(TouchOnEvent);
    }
    else if(eventmask & TouchOffEvent) {
      button = FALSE;
      ClearEvent(TouchOffEvent);
    }
    else if(eventmask & LightOnEvent) {
      table = TRUE;
      ClearEvent(LightOnEvent);
    }
    else if(eventmask & LightOffEvent) {
      table = FALSE;
      ClearEvent(LightOffEvent);
    }

    /* Update the OK to drive flag if all prerequisites are met. */
    if(button && table && !okToDrive) {
      okToDrive = TRUE;
      nxt_motor_set_speed(NXT_PORT_A, 100, 0);
      nxt_motor_set_speed(NXT_PORT_B, 100, 0);
    } else if((!button || !table) && okToDrive) {
      okToDrive = FALSE;
      nxt_motor_set_speed(NXT_PORT_A, 0, 1);
      nxt_motor_set_speed(NXT_PORT_B, 0, 1);
    }

  }
}

