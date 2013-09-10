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
      function Read return Integer;
      procedure Write(I : Integer);
      procedure PR_Increase;
   private
      --function Pread return Integer;
      --procedure Pwrite(I : Integer);
      B : Buffer_Array;
      PW : Integer := 0;
      PR : Integer := -1;
      Q : Boolean := False;
   end Buffer;
   
   protected body Buffer is
      
      --procedure Write(I : Integer) is
      --begin
	 --Pwrite(I);
      --end Write;
      
      --function Read return Integer is
      --begin
	-- return Pread;
      --end Read;
      
      procedure PR_Increase is
      begin
	 if (PR mod 20 /= PW) then
	    PR := (PR + 1) mod 20;
	 end if;
      end PR_Increase;
      
      procedure Write(I : Integer) is
      begin
	 if ((PW+1) mod 20 /= PR) then
	    B(PW) := I;
	    Put_Line("  Buffer: Writing " & Integer'Image(I) & " at position " & Integer'Image(PW) & "");
	    PW := (PW + 1) mod 20;
	 end if;
      end Write;
      
      function Read return Integer is
      begin
	 --if (PR mod 20 /= PW) then
	    --   delay 0.1;
	    --end loop;
	 Put_Line("  Buffer: Reading " & Integer'Image(B(PR)) & " from position " & Integer'Image(PR) & "");
	 return B(PR);	 
	 --end if;
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
	 I := Random(G) mod 26;
	 Put_Line("Producer writes" & Integer'Image(I));
	 B.Write(I);
	 
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
      C, I : Integer := 0;
   begin
      
      Reset(G);
      
      while (C < 100) loop
	 delay Duration(Float(Random(G)) / 100.0);
	 B.PR_Increase;
	 I := B.Read;
	 C := C + I;
	 Put_Line("Consumer read" & Integer'Image(I) & ".");
      end loop;
      Producer.Quit;
      Put_Line("Consumer ended.");
      
   end Consumer;
   
begin
   null;
end Intbuffertwo;
