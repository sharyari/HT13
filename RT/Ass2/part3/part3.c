#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

DeclareTask(HelloworldTask);
DeclareTask(MotorcontrolTask);
DeclareTask(EventdispatcherTask);
DeclareTask(UltrasonicTask);

DeclareCounter(SysTimerCnt);

#define LIGHTSENSOR NXT_PORT_S1
#define TOUCHSENSOR NXT_PORT_S2
#define ULTRASONICSENSOR NXT_PORT_S3
#define LIGHTVAL ecrobot_get_light_sensor(LIGHTSENSOR)
#define ULTRAVAL ecrobot_get_sonar_sensor(ULTRASONICSENSOR)
#define TOUCHVAL ecrobot_get_touch_sensor(TOUCHSENSOR)
#define PRIO_IDLE 10
#define PRIO_BUTTON 20
#define SPEED 70
#define MCTP 50
#define BPTP 10
#define DTP 100
#define USTP 100

struct dc_t {
    U32 duration;
    S32 speed;
    int priority;
} dc = {0, 0, PRIO_IDLE};


void change_driving_command(int priority, int speed, int duration) {
	if (priority >= dc.priority) {
		dc.priority = priority;
		dc.speed = speed;
		dc.duration = duration;
	}
}


void ecrobot_device_initialize() {
ecrobot_init_sonar_sensor(ULTRASONICSENSOR) ;
  ecrobot_set_light_sensor_active(LIGHTSENSOR);
}
void ecrobot_device_terminate() {
ecrobot_term_sonar_sensor(ULTRASONICSENSOR) ;
  ecrobot_set_light_sensor_inactive(LIGHTSENSOR);
}

void display_light_intensity() {
      display_clear(1);
      display_goto_xy(0,0);
      display_unsigned(LIGHTVAL, 3);
      display_update();
}

void user_1ms_isr_type2(void){ (void)SignalCounter(SysTimerCnt); } 

int light_calibration_proc() {
  int threshold = 0;
  for (int i=0;i<10;i++){
    threshold += LIGHTVAL;
    systick_wait_ms(100);
  }
  return threshold /= 10;
}

TASK(ButtonpressTask){
	if (TOUCHVAL)
		change_driving_command(PRIO_BUTTON, -100, 1000); 		
	TerminateTask();
}

TASK(DisplayTask){

TerminateTask();
}

TASK(UltrasonicTask) {
	int d = ULTRAVAL;
	if (d > 20 && d < 100)
		change_driving_command(PRIO_BUTTON, 100, USTP);
	TerminateTask();
}

TASK(MotorcontrolTask) {
	if (dc.duration > 0){
    	nxt_motor_set_speed(NXT_PORT_A, dc.speed, 0);
   		nxt_motor_set_speed(NXT_PORT_B, dc.speed, 0);
		dc.duration-=MCTP;
	} else if (dc.priority == PRIO_IDLE)
		;
	else {
	    nxt_motor_set_speed(NXT_PORT_A, 0, 1);
	    nxt_motor_set_speed(NXT_PORT_B, 0, 1);
		dc.priority = PRIO_IDLE;
	}
	TerminateTask();
}

