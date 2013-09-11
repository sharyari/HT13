with Ada.Text_IO, Ada.Float_Text_IO;
use Ada.Text_IO, Ada.Float_Text_IO;
with Ada.Calendar; use Ada.Calendar;
with Ada.Numerics.Discrete_Random;-- use Ada.Numerics.Float_Random;

procedure CyclicTwo is
   subtype F3ET is Integer range 1000 .. 7000;
   package DIO is new Ada.Text_Io.Fixed_Io(Duration);
   package Random_Execution_Time is new Ada.Numerics.Discrete_Random(F3ET);
   use Random_Execution_Time;
   
   G : Generator; --Generator for creating random execution time
   T : Time := Clock; --The next whole second to run the schedule
   ST : Time := T; --Start time (for outputs to make sense)
   F3Flip : Boolean := True; --Flag to toggle if it is a second that F3 should be executed
   
   --Task to monitor procedure F3's execution time
   task type Watchdog is
      entry F3Begin; --Start watching
      entry F3End(B : out Boolean); --End watching, output wheter or not F3 missed deadline on B
   end Watchdog;
   
   F3Watchdog : Watchdog;
   
   --Procedure that is executed at the start of every new second if F3 keeps deadline, otherwise skip a full second 
   procedure F1 is
   begin
      Put("In F1. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");   
   end F1;
   --Procedure that starts as soon as F1 ends
   procedure F2 is
   begin
      Put("In F2. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");   
   end F2;
   --Procedure that is executed every other second 0.5s after F1 started (randomly skips deadline of 0.5s)
   procedure F3 is
   begin
      Put("In F3. Start time is "); Put(Duration'Image(Clock-ST)); Put_Line("");
      delay Duration(Float(Random(G)) / 10000.0); --Delay for random execution time 
      Put("In F3. End time is "); Put(Duration'Image(Clock-ST)); Put_Line("");
   end F3;
   
   task body Watchdog is
   begin
      loop
	 --Start watching procedure
	 accept F3Begin do
	    Put_Line("Watching F3.");   
	 end F3Begin;
	 select
	    delay 0.5;
	    -- F3 took too long to finish, write a warning and output that it missed its deadline
	    Put("Warning! F3 went over its budget" & Duration'Image(Clock-ST)); Put_Line("");
	    --Stop watching with missed deadline
	    accept F3End(B : out Boolean) do
	       Put_Line("F3 done");	  
	       B := True; --Missed deadline 
	    end F3End;
	 or 
	    --Stop watching with met deadline
	    accept F3End(B : out Boolean) do
	       Put_Line("F3 done");
	       B := False; --Met deadline 	    
	    end F3End;
	 end select;
      end loop;
   end Watchdog;
   B : Boolean := False; --Deadline flag
begin
   Reset(G); --Create new random execution time
   loop 
      --Set next time F1 should be executed 
      T := T + 1.0;
      --Run procedures	
      F1;
      F2;
      if F3Flip then --If second when F3 should be run
	 delay until (T-0.5); --Set starting time for F3 to 0.5s after start of F1
	 F3Watchdog.F3Begin; --Start watchdog
	 F3; --execute F3
	 F3Watchdog.F3End(B); --End watchdog
	 if B then --If missed deadline
	    T := T + 1.0; --Set next execution time for F1 to the next second instead
	    F3Flip := not F3Flip; -- Run F3 next round as well, since we skip one second.
	 end if;
      end if;
      F3Flip := not F3Flip; --Toggle F3 run-second
      Put_Line("");
      delay until T;
   end loop;
end CyclicTwo;
