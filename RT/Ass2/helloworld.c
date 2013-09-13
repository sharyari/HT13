#include <stdlib.h>
#include "kernel.h"
#include "kernel_id.h"
#include "ecrobot_interface.h"



DeclareTask(HelloworldTask);


void ecrobot_device_initialize() {}
void ecrobot_device_terminate() {}
void user_1ms_isr_type2(void) {}



TASK(HelloworldTask)
{

    // Your code comes here
	display_clear(1);
	display_string("Hello World!");
	display_update();
    TerminateTask();
}
