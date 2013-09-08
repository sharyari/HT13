with Ada.Text_IO, Ada.Float_Text_IO;
use Ada.Text_IO, Ada.Float_Text_IO;
with Ada.Calendar; use Ada.Calendar;
with Ada.Numerics.Discrete_Random;-- use Ada.Numerics.Float_Random;

procedure CyclicTwo is
   subtype F3ET is Integer range 1000 .. 7000 ; 
   package DIO is new Ada.Text_Io.Fixed_Io(Duration);
   package Random_Execution_Time is new Ada.Numerics.Discrete_Random (F3ET);
   use Random_Execution_Time;
   
   G : Generator;
   T : Time := Clock;
   ST : Time := T;
   F3Flip : Boolean := True;
   
   task type Watchdog is
      entry F3Begin;
      entry F3End;
   end Watchdog;
   
   F3Watchdog : Watchdog;
   
   procedure F1 is
   begin
      Put("In F1. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");   
   end F1;
   procedure F2 is
   begin
      Put("In F2. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");   
   end F2;
   procedure F3 is
   begin
      Put("In F3. Start time is "); Put(Duration'Image(Clock-ST)); Put_Line("");
      delay until (Clock+Duration(Float(Random(G))/10000.0));
      Put("In F3. End time is "); Put(Duration'Image(Clock-ST)); Put_Line("");
   end F3;
   task body Watchdog is
   begin
      loop
	 accept F3Begin do
	    Put_Line("Watching F3.");   
	 end F3Begin; 
	 select when (True) =>
	    delay 0.5;
	    -- F3 took too long to finish, write a warning and increase the delay until the
	    -- next second.
	    Put("Warning! F3 went over its budget");
	    Put(Duration'Image(Clock-ST)); Put_Line("");
	    T := T + 1.0;
	    accept F3End do
	       Put_Line("F3 done");	    
	    end F3End;
	 or
	    accept F3End do
	       Put_Line("F3 done");	    
	    end F3End;
	 end select;
      end loop;
   end Watchdog;
begin
   Reset(G);
   loop 
      F1;
      F2;
      T := T + 1.0;
      if F3Flip = True then
	 delay until (T-0.5);
	 F3Watchdog.F3Begin;
	 F3;
	 F3Watchdog.F3End;
      end if;
      F3Flip := not F3Flip;
      Put_Line("");
      delay until T;
   end loop;
end CyclicTwo;
