with Ada.Text_Io; use Ada.Text_Io;
with Ada.Calendar; use Ada.Calendar;
with Ada.Numerics.Discrete_Random;

procedure Intbuffer is
   
   type Buffer_Array is array (0 .. 19) of Integer; --Buffer array with length of 20
   
   subtype Random_Number is Integer range 0 .. 400; --Random number between 0 and 400
   
   package Random_Number_Generator is new Ada.Numerics.Discrete_Random (Random_Number);
   use Random_Number_Generator;
   
   -- Buffer task
   task Buffer is
      entry Write(I : Integer); --Write input I to buffer
      entry Read(I : out Integer); --Read from buffer and output to I
      entry Quit; --Stop buffer task
   end Buffer;
   
   -- Producer task, inputs random numbers between 0 and 25 to buffer
   task Producer is 
      entry Quit; --Stop producer task
   end Producer;   
   
   -- Consumer task, reads from buffer
   task Consumer;
   
   task body Buffer is
      B : Buffer_Array; -- The array used for the cyclic buffer
      PR, PW : Integer := 0; -- Read and Write pointers
      D : Integer := 0; -- Number of readable elements in cyclic buffer
      L : constant Integer := 20; -- Length of cyclic buffer
      Q : Boolean := False; -- Exit the task when Q = true
   begin
      while (not Q) loop --Loop as long as we dont get a quit
	 
	 select 
	    when (D < L) => --If still free spots in buffer
	       accept Write(I : Integer) do --accept input I to write to buffer
		  B(PW) := I; --Write I to buffer
		  PW := (PW + 1) mod L; --Move Write pointer to next slot
		  D := D + 1; --A new spot has been filled, increase number of busy slots
	       end Write;
	 or
	    when (D /= 0) => --If there are any readable elements in the buffer
	       accept Read(I : out Integer) do	--accept the read command	  
		  I := B(PR); --output the first readable element in the buffer	  
	       end Read;
	       PR := (PR + 1) mod L; --move the read pointer to next readable element in buffer      
	       D := D - 1; --decrease number of busy slots
	 or 
	    accept Quit do
	       Q := True; --Quit the buffer
	    end Quit;
	 end select;
	 
      end loop;
      
      Put_Line("Buffer ended.");
      
   end Buffer;
   
   -- Producer task
   task body Producer is 
      G : Generator; --Generator for creating random number
      Q : Boolean := False; --Quit flag
      I : Integer; --Number to write to buffer
   begin 
      Reset(G); --Create new random number
      
      while (not Q) loop --As long as we shouldn't quit
	 
	 
	 select
	    delay Duration(Float(Random(G)) / 1000.0); --Randomize execution time
	    I := Random(G) mod 26; --Create random number between 0 and 25 to put to buffer
	    Put_Line("Producer writes" & Integer'Image(I));
	    Buffer.Write(I); --Write to buffer
	 or
	    accept Quit do --If quit command is run
	       Q := True; --set quit flag
	    end Quit;
	 end select;
      end loop;
      
      Put_Line("Producer ended.");
      
   end Producer;
   
   -- Consumer task
   -- Reads from buffer until numbers read add up at least 100
   task body Consumer is 
      G : Generator; --Generator for creating random number
      C : Integer := 0; --Counter summing up read values
      I : Integer := 0; --Value read from buffer
   begin
      
      Reset(G); --Create new random number
      
      while (C < 100) loop --if the sum is less than 100
      	 delay Duration(Float(Random(G)) / 1000.0); --Randomize execution time
	 Buffer.Read(I); --Read from buffer
	 C := C + I; --Add read value to the sum counter
	 Put_Line("Consumer read" & Integer'Image(I) & ".");
	 
      end loop;
      Producer.Quit; --quit the producer
      Buffer.Quit; --quit the buffer
      Put_Line("Consumer ended.");      
   end Consumer;
   
begin
   null;
end Intbuffer;
