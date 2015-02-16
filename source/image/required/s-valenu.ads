pragma License (Unrestricted);
--  implementation unit required by compiler
package System.Val_Enum is
   pragma Pure;

   --  required for Enum'Value by compiler (s-valenu.ads)
   function Value_Enumeration_8 (
      Names : String;
      Indexes : Address;
      Num : Natural;
      Str : String)
      return Natural;
   pragma Pure_Function (Value_Enumeration_8);

   function Value_Enumeration_16 (
      Names : String;
      Indexes : Address;
      Num : Natural;
      Str : String)
      return Natural;
   pragma Pure_Function (Value_Enumeration_16);

   function Value_Enumeration_32 (
      Names : String;
      Indexes : Address;
      Num : Natural;
      Str : String)
      return Natural;
   pragma Pure_Function (Value_Enumeration_32);

   --  helper
   procedure Trim (S : String; First : out Positive; Last : out Natural);
   procedure To_Upper (S : in out String);

end System.Val_Enum;
