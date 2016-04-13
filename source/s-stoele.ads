pragma License (Unrestricted);
package System.Storage_Elements is
   pragma Pure;

   type Storage_Offset is range
      -(2 ** (Standard'Address_Size - 1)) ..
      2 ** (Standard'Address_Size - 1) - 1; -- implementation-defined

   subtype Storage_Count is Storage_Offset range 0 .. Storage_Offset'Last;

   type Storage_Element is mod 2 ** Storage_Unit; -- implementation-defined
   for Storage_Element'Size use Storage_Unit;
   type Storage_Array is
      array (Storage_Offset range <>) of aliased Storage_Element;
   for Storage_Array'Component_Size use Storage_Unit;

   --  Address Arithmetic:

   function "+" (Left : Address; Right : Storage_Offset) return Address
      with Convention => Intrinsic;
   function "+" (Left : Storage_Offset; Right : Address) return Address
      with Convention => Intrinsic;
   function "-" (Left : Address; Right : Storage_Offset) return Address
      with Convention => Intrinsic;
   function "-" (Left, Right : Address) return Storage_Offset
      with Convention => Intrinsic;

   pragma Pure_Function ("+");
   pragma Pure_Function ("-");
   pragma Inline_Always ("+");
   pragma Inline_Always ("-");

   function "mod" (Left : Address; Right : Storage_Offset)
      return Storage_Offset
      with Convention => Intrinsic;

   pragma Pure_Function ("mod");
   pragma Inline_Always ("mod");

   --  Conversion to/from integers:

   type Integer_Address is mod Memory_Size; -- implementation-defined
   function To_Address (Value : Integer_Address) return Address
      with Convention => Intrinsic;
   function To_Integer (Value : Address) return Integer_Address
      with Convention => Intrinsic;

   pragma Pure_Function (To_Address);
   pragma Pure_Function (To_Integer);
   pragma Inline_Always (To_Address);
   pragma Inline_Always (To_Integer);

   --  ...and so on for all language-defined subprograms declared in this
   --  package.

   --  extended
   function Shift_Left (Value : Storage_Element; Amount : Natural)
      return Storage_Element
      with Import, Convention => Intrinsic;
   function Shift_Left (Value : Integer_Address; Amount : Natural)
      return Integer_Address
      with Import, Convention => Intrinsic;
   function Shift_Right (Value : Storage_Element; Amount : Natural)
      return Storage_Element
      with Import, Convention => Intrinsic;
   function Shift_Right (Value : Integer_Address; Amount : Natural)
      return Integer_Address
      with Import, Convention => Intrinsic;

end System.Storage_Elements;
