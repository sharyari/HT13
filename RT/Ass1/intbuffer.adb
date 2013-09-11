with Ada.Text_Io; use Ada.Text_Io;
with Ada.Calendar; use Ada.Calendar;
with Ada.Numerics.Discrete_Random;

procedure Intbuffer is
   
   type Buffer_Array is array (0 .. 19) of Integer;
   
   subtype Random_Number is Integer range 0 .. 400;
   
   package Random_Number_Generator is new Ada.Numerics.Discrete_Random (Random_Number);
   
   use Random_Number_Generator;
   
   -- Buffer task
   task Buffer is
      entry Write(I : Integer);
      entry Read(I : out Integer);
      entry Quit;
   end Buffer;
   
   task Consumer;
   
   task Producer is 
      entry Quit;
   end Producer;   
   
   
   task body Buffer is
      B : Buffer_Array; -- The array used for the cyclic buffer
      PR, PW : Integer := 0; -- Read and Write pointers
      D : Integer := 0; -- Numer of readable elements in cyclic buffer
      L : constant Integer := 20; -- Length of cyclic buffer
      Q : Boolean := False; -- Exit the task when Q = true
   begin
      
      while (not Q) loop
	 
	 select 
	    when (D < L) =>
	       accept Write(I : Integer) do
		  B(PW) := I;
		  -- Put_Line("  Buffer: Writing " & Integer'Image(I) & " at position " & Integer'Image(PW) & "");
		  PW := (PW + 1) mod L;
		  D := D + 1;
	       end Write;
	 or
	    when (D /= 0) =>
	       accept Read(I : out Integer) do		  
		  -- Put_Line("  Buffer: Reading " & Integer'Image(B(PR)) & " from position " & Integer'Image(PR) & "");
		  I := B(PR);	  
	       end Read;
	       PR := (PR + 1) mod L;      
	       D := D - 1;
	 or 
	    accept Quit do
	       Q := True;
	    end Quit;
	 or
	    delay 0.01;
	 end select;
	 
      end loop;
      
      Put_Line("Buffer ended.");
      
   end Buffer;
   
   -- Producer task
   task body Producer is 
      G : Generator;
      Q : Boolean := False;
      I : Integer;
   begin
      
      Reset(G);
      
      while (not Q) loop
	 I := Random(G) mod 26;
	 Put_Line("Producer writes" & Integer'Image(I));
	 Buffer.Write(I);
	 
	 select
	    delay Duration(Float(Random(G)) / 1000.0);
	 or
	    accept Quit do
	       Q := True;
	    end Quit;
	 end select;
      end loop;
      
      Put_Line("Producer ended.");
      
   end Producer;
     
   -- Consumer task
   task body Consumer is 
      G : Generator;
      C : Integer := 0;
      I : Integer := 0;
   begin
      
      Reset(G);
      
      while (C < 100) loop
	 delay Duration(Float(Random(G)) / 1000.0);
	 Buffer.Read(I);
	 C := C + I;
	 Put_Line("Consumer read" & Integer'Image(I) & ".");
      end loop;
      Producer.Quit;
      Buffer.Quit;
      Put_Line("Consumer ended.");
      
   end Consumer;
begin
   null;
end Intbuffer;
