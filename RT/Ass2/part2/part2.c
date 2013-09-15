#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

DeclareTask(HelloworldTask);
DeclareTask(MotorcontrolTask);
DeclareTask(EventdispatcherTask);
DeclareEvent(TouchOnEvent);
DeclareEvent(TouchOffEvent);
DeclareEvent(LightChangeEvent);

#define LIGHTSENSOR NXT_PORT_S1
#define TOUCHSENSOR NXT_PORT_S2
#define LIGHTVAL ecrobot_get_light_sensor(LIGHTSENSOR)
#define TOUCHVAL ecrobot_get_touch_sensor(TOUCHSENSOR)

void ecrobot_device_initialize() {
  ecrobot_set_light_sensor_active(LIGHTSENSOR);
}
void ecrobot_device_terminate() {
  ecrobot_set_light_sensor_inactive(LIGHTSENSOR);
}

void display_light_intensity() {
      display_clear(1);
      display_goto_xy(0,0);
      display_unsigned(LIGHTVAL, 3);
      display_update();
}

void user_1ms_isr_type2(void) {}

int light_calibration_proc() {
  int threshold = 0;
  for (int i=0;i<10;i++){
    threshold += LIGHTVAL;
    systick_wait_ms(100);
  }
  return threshold /= 10;
}

TASK(EventdispatcherTask){
  int state = 0;
  int threshold = light_calibration_proc();

  while (1) {
    if (state != TOUCHVAL) {
      state++; state = state%2;
      if (state)
	SetEvent(MotorcontrolTask, TouchOnEvent);
      else
	SetEvent(MotorcontrolTask, TouchOffEvent);
    }

    if (state && LIGHTVAL >= threshold*1.05){
      SetEvent(MotorcontrolTask, LightChangeEvent);
      state = !state;
    }
    display_light_intensity();
    systick_wait_ms(100);
  }
}

TASK(MotorcontrolTask) {
  while(true) {
    WaitEvent(TouchOnEvent);
    ClearEvent(TouchOnEvent);
    nxt_motor_set_speed(NXT_PORT_A, 70, 0);
    nxt_motor_set_speed(NXT_PORT_B, 70, 0);

    //    Make the car move forward by activating the motor
    WaitEvent(TouchOffEvent | LightChangeEvent);
    ClearEvent(TouchOffEvent);   
    ClearEvent(LightChangeEvent);
    nxt_motor_set_speed(NXT_PORT_A, 0, 1);
    nxt_motor_set_speed(NXT_PORT_B, 0, 1);
  }
}

