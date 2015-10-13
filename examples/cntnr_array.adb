with Ada.Containers.Generic_Arrays;
with Ada.Unchecked_Deallocation;
with Ada.Text_IO;
procedure cntnr_Array is
	type String_Access is access String;
	procedure Free is new Ada.Unchecked_Deallocation (String, String_Access);
	package Arrays is new Ada.Containers.Generic_Arrays (
		Positive, Character, String, String_Access);
	package Arrays_Operators is new Arrays.Operators;
	use Arrays_Operators;
begin
	Test_01 : declare
		package Sorting is new Arrays.Generic_Sorting;
		Data : String_Access := new String'("asdfghjkl");
		Data_2 : String_Access := new String'("zxcvbnm");
	begin
		Sorting.Sort (Data);
		pragma Assert (Sorting.Is_Sorted (Data));
		Sorting.Sort (Data_2);
		Sorting.Merge (Data, Data_2);
		pragma Assert (Data_2 = null);
		pragma Assert (Data.all = "abcdfghjklmnsvxz");
		Free (Data);
	end Test_01;
	Test_02 : declare
		use type Ada.Containers.Count_Type;
		X : String_Access := new String'("ABC");
		Y : String_Access;
	begin
		pragma Assert (Arrays.Length (X) = 3);
		Arrays.Assign (Y, X & 'D');
		pragma Assert (Arrays.Length (Y) = 4);
		pragma Assert (Y.all = "ABCD");
		Arrays.Assign (Y, X & 'D' & 'E');
		pragma Assert (Y.all = "ABCDE");
		Arrays.Assign (Y, X & 'D' & 'E' & 'F');
		pragma Assert (Y.all = "ABCDEF");
		Free (X);
		Free (Y);
	end Test_02;
	Test_03: declare
		use type Ada.Containers.Count_Type;
		X : aliased String_Access := new String'("ABCD");
	begin
		Arrays.Delete (X, 2, 2);
		pragma Assert (X.all = "AD");
		Arrays.Insert (X, 2, 'Z');
		pragma Assert (X.all = "AZD");
		Arrays.Append (X, 'a');
		pragma Assert (X.all = "AZDa");
		Arrays.Prepend (X, 'p');
		pragma Assert (X.all = "pAZDa");
		Arrays.Delete_First (X);
		Arrays.Delete_Last (X);
		pragma Assert (X.all = "AZD");
		Free (X);
	end Test_03;
	Test_04 : declare
		X : aliased String_Access;
	begin
		X := new String'(10 .. 9 => <>);
		pragma Assert (X'Length = 0);
		Arrays.Append (X, 'A');
		pragma Assert (X.all = "A");
		pragma Assert (X'First = 10);
		Arrays.Append (X, 'C');
		pragma Assert (X.all = "AC");
		pragma Assert (X'First = 10);
		Arrays.Insert (X, 11, 'B');
		pragma Assert (X.all = "ABC");
		pragma Assert (X'First = 10);
		Arrays.Prepend (X, 'q');
		pragma Assert (X.all = "qABC");
		pragma Assert (X'First = 10);
		Arrays.Delete (X, 10, 1);
		pragma Assert (X.all = "ABC");
		pragma Assert (X'First = 10);
		Free (X);
		X := new String'(10 .. 9 => <>);
		Arrays.Set_Length (X, 1);
		pragma Assert (X'First = 10 and then X'Last = 10);
		X (10) := 'I';
		Arrays.Set_Length (X, 2);
		pragma Assert (X'First = 10 and then X'Last = 11);
		X (11) := 'J';
		pragma Assert (X.all = "IJ");
		Free (X);
	end Test_04;
	pragma Debug (Ada.Debug.Put ("OK"));
end cntnr_Array;
