with Ada.Unchecked_Deallocation;
with System.Formatting;
with System.Native_Allocators.Allocated_Size;
with System.Storage_Elements;
procedure heap is
	type Integer_Access is access all Integer;
	procedure Free is new Ada.Unchecked_Deallocation (Integer, Integer_Access);
	x, y : Integer_Access;
	procedure Put (X : System.Storage_Elements.Integer_Address) is
		S : String (1 .. Standard'Address_Size / 4);
		Last : Natural;
		Error : Boolean;
	begin
		System.Formatting.Image (
			System.Formatting.Longest_Unsigned (X),
			S,
			Last,
			16,
			Width => S'Length,
			Error => Error);
		Ada.Debug.Put (S);
	end Put;
	procedure Put (X : System.Storage_Elements.Storage_Count) is
		S : String (1 .. Standard'Address_Size / 4);
		Last : Natural;
		Error : Boolean;
	begin
		System.Formatting.Image (
			System.Formatting.Longest_Unsigned (X),
			S,
			Last,
			Padding => ' ',
			Width => S'Length,
			Error => Error);
		Ada.Debug.Put (S);
	end Put;
begin
	x := new Integer;
	y := new Integer;
	Put (System.Storage_Elements.To_Integer (x'Pool_Address));
	Put (System.Native_Allocators.Allocated_Size (x'Pool_Address));
	Put (System.Storage_Elements.To_Integer (y'Pool_Address));
	Put (System.Native_Allocators.Allocated_Size (y'Pool_Address));
	Free (x);
	Free (y);
end heap;
