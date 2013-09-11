with Ada.Text_IO, Ada.Float_Text_IO;
use Ada.Text_IO, Ada.Float_Text_IO;
with Ada.Calendar; use Ada.Calendar;


procedure Cyclic is
   package DIO is new Ada.Text_Io.Fixed_Io(Duration);
   T : Time := Clock;
   ST : Time := T;
   Flip : Boolean := True;
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
      Put("In F3. Current time is "); Put(Duration'Image(Clock-ST)); Put_Line("");
   end F3;
begin
   loop 
	T := T + 1.0;	
      F1;
      F2;  
      if Flip then
	 delay until (T-0.5);
	 F3;
      end if;
      Flip := not Flip;
      Put_Line("");
      delay until T;
   end loop;
end Cyclic;
