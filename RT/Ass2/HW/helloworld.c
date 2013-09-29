#include <stdlib.h>
#include <stdio.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"



DeclareTask(HelloworldTask);


void ecrobot_device_initialize() {
  ecrobot_set_light_sensor_active(NXT_PORT_S1);
}
void ecrobot_device_terminate() {
  ecrobot_set_light_sensor_inactive(NXT_PORT_S1);
}
void user_1ms_isr_type2(void) {}



TASK(HelloworldTask)
{
  boolean a = true;
  display_clear(1);
  while (true) {
    display_string("Hello World!\n");
    if (a)
      display_string("Din mamma\n");
    a = !a;
    int number = ecrobot_get_light_sensor(NXT_PORT_S1);
    char t[10];
    for (int i = 5; i >= 0; i--) {
      t[i] = number % 10 + 48;
      number /= 10;
    }
    display_string(t);
    display_update();
    systick_wait_ms(100);
  }

  TerminateTask();
}
