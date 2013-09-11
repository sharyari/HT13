with Ada.Text_IO, Ada.Float_Text_IO;
use Ada.Text_IO, Ada.Float_Text_IO;
with Ada.Calendar; use Ada.Calendar;


procedure Cyclic is
   package DIO is new Ada.Text_Io.Fixed_Io(Duration);
   T : Time := Clock; --The next whole second to run the schedule
   ST : Time := T; --Start time (for outputs to make sense)
   Flip : Boolean := True; --Flag to toggle if it is a second that F3 should be executed
   
   --Procedure that is executed at the start of every new second 
   procedure F1 is
   begin
      Put("In F1. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");   
   end F1;
   
   --Procedure that starts as soon as F1 ends
   procedure F2 is
   begin
      Put("In F2. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");   
   end F2;
   
   --Procedure that is executed every other second 0.5s after F1 started
   procedure F3 is
   begin
      Put("In F3. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");
   end F3;
begin
   loop
      --Set next time F1 should be executed 
      T := T + 1.0;
      --Run procedures	
      F1;
      F2;  
      if Flip then --If second when F3 should be run
	 delay until (T-0.5); --Set starting time for F3 to 0.5s after start of F1
	 F3;
      end if;
      Flip := not Flip; --Toggle F3 execution
      Put_Line("");
      delay until T;
   end loop;
end Cyclic;
