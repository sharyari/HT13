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


void ecrobot_device_initialize() {
  ecrobot_init_sonar_sensor(ULTRASONICSENSOR) ; // initiate sensors
  ecrobot_set_light_sensor_active(LIGHTSENSOR);
}
void ecrobot_device_terminate() {
  ecrobot_term_sonar_sensor(ULTRASONICSENSOR) ; // turn sensors off
  ecrobot_set_light_sensor_inactive(LIGHTSENSOR);
}

void user_1ms_isr_type2(void){ (void)SignalCounter(SysTimerCnt); } 

void change_driving_command(int priority, int speed, int duration) {
  /* If a new driving command is sent, overwrite the previous if the new
     command has higher priority than the current. */
  if (priority >= dc.priority) {
    dc.priority = priority;
    dc.speed = speed;
    dc.duration = duration;
  }
}

/* This function will print the light intensity on the LCD */
void display_light_intensity() {
  display_clear(1);
  display_goto_xy(0,0);
  display_string("Light:  ");
  display_unsigned(LIGHTVAL, 3);
  display_update();
}

/*  This function will take 10 light intensity values, waiting 100ms between each measurement
    and return the mean measurement value. This is used for initial calibration */
int light_calibration_proc() {
  int threshold = 0;
  for (int i=0;i<10;i++){
    threshold += LIGHTVAL;
    systick_wait_ms(100);
  }
  return threshold /= 10;
}

/* If the button is pressed, reverse for 1 second
   (actually, from pressed and for approximately one second after release time) */
TASK(ButtonpressTask){
  if (TOUCHVAL)
    change_driving_command(PRIO_BUTTON, -100, 1000); 		
  TerminateTask();
}

TASK(DisplayTask){
  display_light_intensity();
  TerminateTask();
}

/* If an obstacle is closer than 100cm away, but further than 20cm
   move forward. (100cm because the accuracy above 100ms is low, and we
   also want the robot to stop, so we don't have to chase it around) */
TASK(UltrasonicTask) {
  int preferred_speed = 95;
  int d = ULTRAVAL; /* read the ultrasonic value, see #define */

  // If we are not at around 20 cm from the object in front of us.
  if (d > 21 || d < 19) {
  
    // Decrease the speed if we are close to the target distance.
    double temp = preferred_speed * ((d-20)/6);
    int speed = temp;

    // Make sure we keep within the preferred speed interval.
    if(speed < -preferred_speed)
      speed = -preferred_speed; 
    else if(speed > preferred_speed) 
      speed = preferred_speed;
    
    // Send drive command, at lower prio than reverse button.
    change_driving_command(PRIO_BUTTON - 1, speed, USTP);
    
  }

  TerminateTask();
}

TASK(MotorcontrolTask) {
  if (dc.duration > 0){ /* if we should drive... */
    nxt_motor_set_speed(NXT_PORT_A, dc.speed, 0); /* ... drive */
    nxt_motor_set_speed(NXT_PORT_B, dc.speed, 0);
    dc.duration-=MCTP; /* decrease drive time with the period of this task */
  } else if (dc.priority != PRIO_IDLE) { 
    /* if duration is negative or zero, stop */
    nxt_motor_set_speed(NXT_PORT_A, 0, 1);
    nxt_motor_set_speed(NXT_PORT_B, 0, 1);
    dc.priority = PRIO_IDLE;
  }
  TerminateTask();
}
