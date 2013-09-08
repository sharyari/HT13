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
      entry Read; -- ska returna
      entry Quit;
   end Buffer;
   
   task Consumer is
      entry Receive(I : Integer);
   end Consumer;
   
   task Producer is 
      entry Quit;
   end Producer;   
   
   
   task body Buffer is
      B : Buffer_Array;
      PR, PW : Integer := 0;
      Q : Boolean := False;
   begin
      
      while (not Q) loop
	 
	 select 
	    when ((PW+1) mod 20 /= PR) =>
	       accept Write(I : Integer) do
		  B(PW) := I;
		  Put_Line("  Buffer: Writing " & Integer'Image(I) & " at position " & Integer'Image(PW) & "");
		  PW := (PW + 1) mod 20;
	       end Write;
	 or
	    when (PR mod 20 /= PW) =>
	       accept Read do		  
		  Put_Line("  Buffer: Reading " & Integer'Image(B(PR)) & " from position " & Integer'Image(PR) & "");
	       end Read;
	       Consumer.Receive(B(PR));
	       PR := (PR + 1) mod 20;      
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
   begin
      
      Reset(G);
      
      while (C < 100) loop
	 delay Duration(Float(Random(G)) / 1000.0);
	 Buffer.Read;
	 accept Receive(I : Integer) do
	    C := C + I;
	    Put_Line("Consumer read" & Integer'Image(I) & ".");
	 end Receive;
      end loop;
      Producer.Quit;
      Buffer.Quit;
      Put_Line("Consumer ended.");
      
   end Consumer;
begin
   null;
end Intbuffer;
