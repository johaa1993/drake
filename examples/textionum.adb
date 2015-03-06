with Ada.Text_IO;
with Ada.Wide_Text_IO;
with Ada.Wide_Wide_Text_IO;
-- all Integer_Text_IO
with Ada.Short_Short_Integer_Text_IO;
with Ada.Short_Integer_Text_IO;
with Ada.Integer_Text_IO;
with Ada.Long_Integer_Text_IO;
with Ada.Long_Long_Integer_Text_IO;
-- all Float_Text_IO
with Ada.Short_Float_Text_IO;
with Ada.Float_Text_IO;
with Ada.Long_Float_Text_IO;
with Ada.Long_Long_Float_Text_IO;
procedure textionum is
	type I is range -100 .. 100;
	package IIO is new Ada.Text_IO.Integer_IO (I);
	type M is mod 100;
	package MIO is new Ada.Text_IO.Modular_IO (M);
	type F is digits 3;
	package FIO is new Ada.Text_IO.Float_IO (F);
	type O is delta 0.1 range 0.1 .. 1.0;
	package OIO is new Ada.Text_IO.Fixed_IO (O);
	type D1 is delta 0.1 digits 3;
	package D1IO is new Ada.Text_IO.Decimal_IO (D1);
	type D2 is delta 10.0 digits 3;
	package D2IO is new Ada.Text_IO.Decimal_IO (D2);
	S : String (1 .. 12);
begin
	D1IO.Put (10.0, Fore => 5); Ada.Text_IO.New_Line;
	D1IO.Put (-12.3, Aft => 3); Ada.Text_IO.New_Line;
	D2IO.Put (10.0); Ada.Text_IO.New_Line;
	D2IO.Put (-1230.0); Ada.Text_IO.New_Line;
	pragma Assert (Integer (Float'(5490.0)) = 5490);
	Ada.Float_Text_IO.Put (5490.0); Ada.Text_IO.New_Line;
	Ada.Float_Text_IO.Put (S, 5490.0);
	Ada.Debug.Put (S);
	pragma Assert (S = " 5.49000E+03");
	declare
		package Integer_Wide_Text_IO is new Ada.Wide_Text_IO.Integer_IO (Integer);
		package Unsigned_Wide_Text_IO is new Ada.Wide_Text_IO.Modular_IO (M);
		package Float_Wide_Text_IO is new Ada.Wide_Text_IO.Float_IO (F);
		package Fixed_Wide_Text_IO is new Ada.Wide_Text_IO.Fixed_IO (O);
		package Decimal_Wide_Text_IO is new Ada.Wide_Text_IO.Decimal_IO (D1);
	begin
		null;
	end;
	declare
		package Integer_Wide_Wide_Text_IO is new Ada.Wide_Wide_Text_IO.Integer_IO (Integer);
		package Unsigned_Wide_Wide_Text_IO is new Ada.Wide_Wide_Text_IO.Modular_IO (M);
		package Float_Wide_Wide_Text_IO is new Ada.Wide_Wide_Text_IO.Float_IO (F);
		package Fixed_Wide_Wide_Text_IO is new Ada.Wide_Wide_Text_IO.Fixed_IO (O);
		package Decimal_Wide_Wide_Text_IO is new Ada.Wide_Wide_Text_IO.Decimal_IO (D1);
	begin
		null;
	end;
	pragma Debug (Ada.Debug.Put ("OK"));
end textionum;
