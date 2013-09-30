#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"


DeclareTask(CompetitionTask);
DeclareCounter(SysTimerCnt);

#define LIGHTSENSOR NXT_PORT_S1
#define ULTRASONICSENSOR NXT_PORT_S3
#define TOUCHSENSOR NXT_PORT_S2
#define TOUCHVAL ecrobot_get_touch_sensor(TOUCHSENSOR)
#define LIGHTVAL ecrobot_get_light_sensor(LIGHTSENSOR)
#define ULTRAVAL ecrobot_get_sonar_sensor(ULTRASONICSENSOR)

int distance;
int gray = 0;

void ecrobot_device_initialize() {
	distance = 0;
	ecrobot_init_sonar_sensor(ULTRASONICSENSOR) ;
	ecrobot_set_light_sensor_active(LIGHTSENSOR);
}

void ecrobot_device_terminate() {
	ecrobot_term_sonar_sensor(ULTRASONICSENSOR) ;
	ecrobot_set_light_sensor_inactive(LIGHTSENSOR);
}

void user_1ms_isr_type2(void){ (void)SignalCounter(SysTimerCnt); } 

TASK(USTask) {
  int tempgray;
  if (!gray) {
    tempgray = LIGHTVAL;
    while(!TOUCHVAL)
      ;
    gray = tempgray;
  }
  distance = ULTRAVAL;
  TerminateTask();
}

TASK(CompetitionTask) {
  int l = LIGHTVAL;
    nxt_motor_set_speed(NXT_PORT_A, 100, 0);
    nxt_motor_set_speed(NXT_PORT_B, 100, 0);
  if (distance > 20)
    if(l < gray)
      nxt_motor_set_speed(NXT_PORT_B, 50, 1);
    else
      nxt_motor_set_speed(NXT_PORT_A, 50, 1);
  else { 
    nxt_motor_set_speed(NXT_PORT_A, 0, 1);
    nxt_motor_set_speed(NXT_PORT_B, 0, 1);
  }
  TerminateTask();
}
