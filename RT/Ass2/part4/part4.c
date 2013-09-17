#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"

DeclareTask(HelloworldTask);
DeclareTask(MotorcontrolTask);
DeclareTask(EventdispatcherTask);
DeclareTask(CompetitionTask);

DeclareResource(DisplayTaskLock);

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
#define TURNSPEED 80

#define DEBUG_MODE 0

int counter;
int distance;
int firstrun = 3;
int color[3];

enum TURN {LEFT, RIGHT, FORW};

struct dc_t {
    int duration; // was unsigned.
    S32 speed;
    int priority;
	int t;
} dc = {0, 0, PRIO_IDLE};


void change_driving_command(int priority, int speed, int duration, int t) {
	if (priority >= dc.priority) {
		dc.priority = priority;
		dc.speed = speed;
		dc.duration = duration;
		dc.t = t;
	}
}


void ecrobot_device_initialize() {
	counter = 0; distance = 0;
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

void calibrate() {
	int a[3];
	for (int i=0;i<3;i++){
			a[i] = LIGHTVAL;
			systick_wait_ms(10);
	}
	color[firstrun] = (a[0]+a[1]+a[2])/3; 
	change_driving_command(PRIO_BUTTON, 100, 400, FORW);
	systick_wait_ms(1000); // Should (?) be moved back to calibrate()
}


TASK(ButtonpressTask){
	if (TOUCHVAL)
		change_driving_command(PRIO_BUTTON, -100, 1000, FORW); 		
	TerminateTask();
}

TASK(DisplayTask){
	GetResource(DisplayTaskLock);
	
	if (firstrun){
		firstrun--;
		calibrate();
	} else {
		display_string("[");
		display_int(color[0],3);
		display_string(",");
		display_int(color[1],3);
		display_string(",");
		display_int(color[2],3);
		display_string("]");
		display_update();
	}

	if(DEBUG_MODE) {
		display_int(firstrun,1);
		display_update();
	}

	ReleaseResource(DisplayTaskLock);
	TerminateTask();
}

TASK(CompetitionTask) {
	if (firstrun)
		TerminateTask();
	int l = LIGHTVAL;
	if (counter == 0)
		distance = ULTRAVAL;
	else
		counter = (counter+1%100);
	if (distance > 20 && distance < 100) {
		if (l > 500)
			change_driving_command(PRIO_BUTTON, 100, USTP, FORW);
		else if (l < 400)
			change_driving_command(PRIO_BUTTON, 100, USTP, FORW);
		else
			change_driving_command(PRIO_BUTTON, 100, USTP, FORW);
	}
	TerminateTask();
}

TASK(MotorcontrolTask) {
	int leftw = dc.speed; int rightw = dc.speed;
	if (dc.duration > 0){
		if (dc.t == LEFT){
			rightw = TURNSPEED;
		} else if (dc.t == RIGHT){
			leftw = TURNSPEED;
		} 
		nxt_motor_set_speed(NXT_PORT_A, leftw, 0);
   		nxt_motor_set_speed(NXT_PORT_B, rightw, 0);
		dc.duration -= MCTP;
		if(DEBUG_MODE) {
			display_string("M");
			display_update();
		}
	} else if (dc.priority == PRIO_IDLE)
		;
	else {
	    nxt_motor_set_speed(NXT_PORT_A, 0, 1);
	    nxt_motor_set_speed(NXT_PORT_B, 0, 1);
		dc.priority = PRIO_IDLE;
	}
	TerminateTask();
}

