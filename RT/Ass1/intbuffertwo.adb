with Ada.Text_Io; use Ada.Text_Io;
with Ada.Calendar; use Ada.Calendar;
with Ada.Numerics.Discrete_Random;

procedure Intbuffertwo is
   
   type Buffer_Array is array (0 .. 19) of Integer;
   subtype Random_Number is Integer range 0 .. 400;
   package Random_Number_Generator is new Ada.Numerics.Discrete_Random (Random_Number);
   use Random_Number_Generator;
   
   task Consumer;
   
   task Producer is 
      entry Quit;
   end Producer;   
      
   protected type Buffer is
      entry Read(I : out Integer);
      entry Write(I : Integer);
   private
      B : Buffer_Array; -- Array to represent cyclic buffer
      PW : Integer := 0; -- Write pointer
      PR : Integer := 0; -- Read pointer
      D : Integer := 0; -- Number of readable elements in buffer
      L : Integer := 20; -- The length of the cyclic buffer
   end Buffer;
   
   protected body Buffer is
      
      entry Write(I : Integer) 
      when D < L is
      begin
	 B(PW) := I;
	 -- Put_Line("  Buffer: Writing " & Integer'Image(I) & " at position " & Integer'Image(PW) & "");
	 PW := (PW + 1) mod L;
	 D := D + 1;
      end Write;
      
      entry Read(I : out Integer) --return Integer
      when D /= 0 is
      begin
	 -- Put_Line("  Buffer: Reading " & Integer'Image(B(PR)) & " from position " & Integer'Image(PR) & "");
	 I:= B(PR);	 
	 PR := (PR + 1) mod L;
	 D := D - 1;
      end Read;	 
   end Buffer;
   
   B : Buffer;
   
   -- Producer task
   task body Producer is 
      G : Generator;
      Q : Boolean := False;
      I : Integer;
   begin
      
      Reset(G);
      
      while (not Q) loop
 
	 select
	    delay Duration(Float(Random(G)) / 1000.0);
	 I := Random(G) mod 26;
	 Put_Line("Producer writes" & Integer'Image(I));
	 B.Write(I);
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
      C, I : Integer := 0;
   begin
      
      Reset(G);
      
      while (C < 100) loop
	 delay Duration(Float(Random(G)) / 1000.0);
	 B.Read(I);
	 C := C + I;
	 Put_Line("Consumer read" & Integer'Image(I) & ".");
      end loop;
      Producer.Quit;
      Put_Line("Consumer ended.");
      
   end Consumer;
   
begin
   null;
end Intbuffertwo;
