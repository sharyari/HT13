with Ada.Text_Io; use Ada.Text_Io;
with Ada.Calendar; use Ada.Calendar;
with Ada.Numerics.Discrete_Random;

procedure Intbuffertwo is
   
   type Buffer_Array is array (0 .. 19) of Integer; --Buffer array with length of 20
   subtype Random_Number is Integer range 0 .. 400; --Random number between 0 and 400
   package Random_Number_Generator is new Ada.Numerics.Discrete_Random (Random_Number);
   use Random_Number_Generator;
   
   -- Consumer task, reads from buffer
   task Consumer;
   
   -- Producer task, inputs random numbers between 0 and 25 to buffer
   task Producer is 
      entry Quit;
   end Producer;   
   
   -- Protected shared buffer type that contains a circular buffer and entry points to interact with it   
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
      --Write to buffer
      entry Write(I : Integer) 
      when D < L is --if free slots left in buffer
      begin
	 B(PW) := I; --add input to buffer
		     -- Put_Line("  Buffer: Writing " & Integer'Image(I) & " at position " & Integer'Image(PW) & "");
	 PW := (PW + 1) mod L; --move write pointer to next free slot
	 D := D + 1; --increase number of used slots
      end Write;
      
      --Read from buffer
      entry Read(I : out Integer) --return Integer
      when D /= 0 is --if readable elements in buffer
      begin
	 -- Put_Line("  Buffer: Reading " & Integer'Image(B(PR)) & " from position " & Integer'Image(PR) & "");
	 I:= B(PR); --output element from buffer
	 PR := (PR + 1) mod L; --move read pointer to next readble element
	 D := D - 1; --decrease number of used slots
      end Read;	 
   end Buffer;
   
   B : Buffer;
   
   -- Producer task
   task body Producer is 
      G : Generator; --Generator for creating random numbers
      Q : Boolean := False; --Quit flag
      I : Integer; --Number to put on buffer
   begin
      
      Reset(G); --create new random number
      
      while (not Q) loop --As long as we shouldn't quit 
	 
	 select
	    delay Duration(Float(Random(G)) / 1000.0); --randomize execution time
	    I := Random(G) mod 26; --create random number between 0 and 25 to put to buffer
	    Put_Line("Producer writes" & Integer'Image(I));
	    B.Write(I); --put number to buffer
	 or
	    accept Quit do --If quit command
	       Q := True; --toggle quit flag
	    end Quit;
	 end select;
      end loop;
      
      Put_Line("Producer ended.");
      
   end Producer;
   
   -- Consumer task
   task body Consumer is 
      G : Generator; --Generator for creating random numbers
      C : Integer := 0; --Counter summing up read values
      I : Integer := 0; --Value read from buffer
   begin
      
      Reset(G); --create new random number
      
      while (C < 100) loop --if the sum is less than 100
	 delay Duration(Float(Random(G)) / 1000.0); --Randomize execution time
	 B.Read(I); --Read from buffer
	 C := C + I; --Add read value to the sum counter
	 Put_Line("Consumer read" & Integer'Image(I) & ".");
      end loop;
      Producer.Quit; --quit the producer
      Put_Line("Consumer ended.");
      
   end Consumer;
   
begin
   null;
end Intbuffertwo;
