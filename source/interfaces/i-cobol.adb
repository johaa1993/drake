with Ada.Exception_Identification.From_Here;
with System.C_Encoding;
with System.Formatting;
with System.Long_Long_Integer_Divisions;
with C;
package body Interfaces.COBOL is
   pragma Suppress (All_Checks);
   use Ada.Exception_Identification.From_Here;
   use type System.Formatting.Unsigned;
   use type C.size_t;

   function add_overflow (
      a, b : Long_Long_Integer;
      res : not null access Long_Long_Integer)
      return Boolean
      with Import,
         Convention => Intrinsic,
         External_Name => "__builtin_saddll_overflow";

   function mul_overflow (
      a, b : Long_Long_Integer;
      res : not null access Long_Long_Integer)
      return Boolean
      with Import,
         Convention => Intrinsic,
         External_Name => "__builtin_smulll_overflow";

   procedure unreachable
      with Import,
         Convention => Intrinsic, External_Name => "__builtin_unreachable";

   pragma No_Return (unreachable);

   --  display formats

   function Valid_Unsigned (Item : Numeric) return Boolean;
   function Valid_Leading_Separate (Item : Numeric) return Boolean;
   function Valid_Trailing_Separate (Item : Numeric) return Boolean;
   function Valid_Leading_Nonseparate (Item : Numeric) return Boolean;
   function Valid_Trailing_Nonseparate (Item : Numeric) return Boolean;

   function Valid_Unsigned (Item : Numeric) return Boolean is
   begin
      if Item'First <= Item'Last then
         for I in Item'Range loop
            if Item (I) not in '0' .. '9' then
               return False;
            end if;
         end loop;
         return True;
      else
         return False;
      end if;
   end Valid_Unsigned;

   function Valid_Leading_Separate (Item : Numeric) return Boolean is
   begin
      return Item'First <= Item'Last
         and then (Item (Item'First) = '+' or else Item (Item'First) = '-')
         and then Valid_Unsigned (Item (Item'First + 1 .. Item'Last));
   end Valid_Leading_Separate;

   function Valid_Trailing_Separate (Item : Numeric) return Boolean is
   begin
      return Item'First <= Item'Last
         and then (Item (Item'Last) = '+' or else Item (Item'Last) = '-')
         and then Valid_Unsigned (Item (Item'First .. Item'Last - 1));
   end Valid_Trailing_Separate;

   function Valid_Leading_Nonseparate (Item : Numeric) return Boolean is
   begin
      return Item'First <= Item'Last
         and then (
            Item (Item'First) in '0' .. '9'
            or else Item (Item'First) in 'p' .. 'y')
         and then (
            Item'First = Item'Last
            or else Valid_Unsigned (Item (Item'First + 1 .. Item'Last)));
   end Valid_Leading_Nonseparate;

   function Valid_Trailing_Nonseparate (Item : Numeric) return Boolean is
   begin
      return Item'First <= Item'Last
         and then (
            Item (Item'Last) in '0' .. '9'
            or else Item (Item'Last) in 'p' .. 'y')
         and then (
            Item'First = Item'Last
            or else Valid_Unsigned (Item (Item'First .. Item'Last - 1)));
   end Valid_Trailing_Nonseparate;

   function Unchecked_Unsigned_To_Decimal (Item : Numeric)
      return Long_Long_Integer;
   function Unsigned_To_Decimal (Item : Numeric) return Long_Long_Integer;
   function Leading_Separate_To_Decimal (Item : Numeric)
      return Long_Long_Integer;
   function Trailing_Separate_To_Decimal (Item : Numeric)
      return Long_Long_Integer;
   function Leading_Nonseparate_To_Decimal (Item : Numeric)
      return Long_Long_Integer;
   function Trailing_Nonseparate_To_Decimal (Item : Numeric)
      return Long_Long_Integer;

   function Unchecked_Unsigned_To_Decimal (Item : Numeric)
      return Long_Long_Integer
   is
      Result : aliased Long_Long_Integer := 0;
   begin
      for I in Item'Range loop
         declare
            E : constant COBOL_Character := Item (I);
            X : Long_Long_Integer;
         begin
            case E is
               when '0' .. '9' =>
                  X := COBOL_Character'Pos (E) - COBOL_Character'Pos ('0');
               when 'p' .. 'y' =>
                  X := COBOL_Character'Pos (E) - COBOL_Character'Pos ('p');
               when others =>
                  unreachable;
            end case;
            if mul_overflow (Result, 10, Result'Access) then
               Raise_Exception (Conversion_Error'Identity);
            end if;
            if add_overflow (Result, X, Result'Access) then
               Raise_Exception (Conversion_Error'Identity);
            end if;
         end;
      end loop;
      return Result;
   end Unchecked_Unsigned_To_Decimal;

   function Unsigned_To_Decimal (Item : Numeric) return Long_Long_Integer is
   begin
      if Valid_Unsigned (Item) then
         return Unchecked_Unsigned_To_Decimal (Item);
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Unsigned_To_Decimal;

   function Leading_Separate_To_Decimal (Item : Numeric)
      return Long_Long_Integer is
   begin
      if Valid_Leading_Separate (Item) then
         declare
            Minus : constant Boolean := Item (Item'First) = '-';
            Result : Long_Long_Integer;
         begin
            Result := Unchecked_Unsigned_To_Decimal (
               Item (Item'First + 1 .. Item'Last));
            if Minus then
               Result := -Result;
            end if;
            return Result;
         end;
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Leading_Separate_To_Decimal;

   function Trailing_Separate_To_Decimal (Item : Numeric)
      return Long_Long_Integer is
   begin
      if Valid_Trailing_Separate (Item) then
         declare
            Minus : constant Boolean := Item (Item'Last) = '-';
            Result : Long_Long_Integer;
         begin
            Result := Unchecked_Unsigned_To_Decimal (
               Item (Item'First .. Item'Last - 1));
            if Minus then
               Result := -Result;
            end if;
            return Result;
         end;
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Trailing_Separate_To_Decimal;

   function Leading_Nonseparate_To_Decimal (Item : Numeric)
      return Long_Long_Integer is
   begin
      if Valid_Leading_Nonseparate (Item) then
         declare
            Minus : constant Boolean := Item (Item'First) in 'p' .. 'y';
            Result : Long_Long_Integer;
         begin
            Result := Unchecked_Unsigned_To_Decimal (Item);
            if Minus then
               Result := -Result;
            end if;
            return Result;
         end;
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Leading_Nonseparate_To_Decimal;

   function Trailing_Nonseparate_To_Decimal (Item : Numeric)
      return Long_Long_Integer is
   begin
      if Valid_Trailing_Nonseparate (Item) then
         declare
            Minus : constant Boolean := Item (Item'Last) in 'p' .. 'y';
            Result : Long_Long_Integer;
         begin
            Result := Unchecked_Unsigned_To_Decimal (Item);
            if Minus then
               Result := -Result;
            end if;
            return Result;
         end;
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Trailing_Nonseparate_To_Decimal;

   function Length_To_Display_Unsigned (Item : Long_Long_Integer)
      return Natural;
   procedure To_Display_Unsigned (
      Item : Long_Long_Integer;
      Result : out Numeric);
   function To_Display_Unsigned (Item : Long_Long_Integer) return Numeric;
   function To_Display_Leading_Separate (Item : Long_Long_Integer)
      return Numeric;
   function To_Display_Trailing_Separate (Item : Long_Long_Integer)
      return Numeric;
   function To_Display_Leading_Nonseparate (Item : Long_Long_Integer)
      return Numeric;
   function To_Display_Trailing_Nonseparate (Item : Long_Long_Integer)
      return Numeric;

   function Length_To_Display_Unsigned (Item : Long_Long_Integer)
      return Natural is
   begin
      return System.Formatting.Width (
         System.Formatting.Longest_Unsigned (Item));
   end Length_To_Display_Unsigned;

   procedure To_Display_Unsigned (
      Item : Long_Long_Integer;
      Result : out Numeric)
   is
      pragma Compile_Time_Error (
         Numeric'Component_Size /= String'Component_Size,
         "size mismatch");
      Result_As_Ada : String (1 .. Result'Length);
      for Result_As_Ada'Address use Result'Address;
      Last : Natural;
      Error : Boolean; -- ignored
   begin
      System.Formatting.Image (
         System.Formatting.Longest_Unsigned (Item),
         Result_As_Ada,
         Last,
         Width => Result'Length,
         Error => Error);
   end To_Display_Unsigned;

   function To_Display_Unsigned (Item : Long_Long_Integer) return Numeric is
   begin
      if Item < 0 then
         Raise_Exception (Conversion_Error'Identity);
      end if;
      return Result : Numeric (1 .. Length_To_Display_Unsigned (Item)) do
         To_Display_Unsigned (Item, Result);
      end return;
   end To_Display_Unsigned;

   function To_Display_Leading_Separate (Item : Long_Long_Integer)
      return Numeric
   is
      Abs_Item : constant Long_Long_Integer := abs Item;
   begin
      return Result : Numeric (
         1 ..
         Length_To_Display_Unsigned (Abs_Item) + 1)
      do
         if Item < 0 then
            Result (Result'First) := '-';
         else
            Result (Result'First) := '+';
         end if;
         To_Display_Unsigned (
            Abs_Item,
            Result (Result'First + 1 .. Result'Last));
      end return;
   end To_Display_Leading_Separate;

   function To_Display_Trailing_Separate (Item : Long_Long_Integer)
      return Numeric
   is
      Abs_Item : constant Long_Long_Integer := abs Item;
   begin
      return Result : Numeric (
         1 ..
         Length_To_Display_Unsigned (Abs_Item) + 1)
      do
         if Item < 0 then
            Result (Result'Last) := '-';
         else
            Result (Result'Last) := '+';
         end if;
         To_Display_Unsigned (
            Abs_Item,
            Result (Result'First .. Result'Last - 1));
      end return;
   end To_Display_Trailing_Separate;

   function To_Display_Leading_Nonseparate (Item : Long_Long_Integer)
      return Numeric is
   begin
      return Result : Numeric := To_Display_Unsigned (abs Item) do
         if Item < 0 then
            Result (Result'First) := COBOL_Character'Val (
               COBOL_Character'Pos (Result (Result'First))
               + (COBOL_Character'Pos ('p') - COBOL_Character'Pos ('0')));
         end if;
      end return;
   end To_Display_Leading_Nonseparate;

   function To_Display_Trailing_Nonseparate (Item : Long_Long_Integer)
      return Numeric is
   begin
      return Result : Numeric := To_Display_Unsigned (abs Item) do
         if Item < 0 then
            Result (Result'Last) := COBOL_Character'Val (
               COBOL_Character'Pos (Result (Result'Last))
               + (COBOL_Character'Pos ('p') - COBOL_Character'Pos ('0')));
         end if;
      end return;
   end To_Display_Trailing_Nonseparate;

   --  packed formats

   function Valid_Unsigned (Item : Packed_Decimal) return Boolean;
   function Valid_Signed (Item : Packed_Decimal) return Boolean;

   function Valid_Unsigned (Item : Packed_Decimal) return Boolean is
   begin
      return Valid_Signed (Item)
         and then Item (Item'Last) /= 16#B#
         and then Item (Item'Last) /= 16#D#;
   end Valid_Unsigned;

   function Valid_Signed (Item : Packed_Decimal) return Boolean is
      Length : constant Natural := Item'Length;
   begin
      if Length = 0
         or else Length rem 2 /= 0
         or else Item (Item'Last) < 16#A#
      then
         return False;
      else
         for I in Item'First .. Item'Last - 1 loop
            if Item (I) >= 16#A# then
               return False;
            end if;
         end loop;
         return True;
      end if;
   end Valid_Signed;

   function Unchecked_Unsigned_To_Decimal (Item : Packed_Decimal)
      return Long_Long_Integer;
   function Unsigned_To_Decimal (Item : Packed_Decimal)
      return Long_Long_Integer;
   function Signed_To_Decimal (Item : Packed_Decimal)
      return Long_Long_Integer;

   function Unchecked_Unsigned_To_Decimal (Item : Packed_Decimal)
      return Long_Long_Integer
   is
      Result : aliased Long_Long_Integer := 0;
   begin
      for I in Item'First .. Item'Last - 1 loop
         if mul_overflow (Result, 10, Result'Access) then
            Raise_Exception (Conversion_Error'Identity);
         end if;
         if add_overflow (
            Result,
            Long_Long_Integer (Item (I)),
            Result'Access)
         then
            Raise_Exception (Conversion_Error'Identity);
         end if;
      end loop;
      return Result;
   end Unchecked_Unsigned_To_Decimal;

   function Unsigned_To_Decimal (Item : Packed_Decimal)
      return Long_Long_Integer is
   begin
      if Valid_Unsigned (Item) then
         return Unchecked_Unsigned_To_Decimal (Item);
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Unsigned_To_Decimal;

   function Signed_To_Decimal (Item : Packed_Decimal)
      return Long_Long_Integer is
   begin
      if Valid_Signed (Item) then
         declare
            Result : Long_Long_Integer := Unchecked_Unsigned_To_Decimal (Item);
         begin
            if Item (Item'Last) = 16#B# or Item (Item'Last) = 16#D# then
               Result := -Result;
            end if;
            return Result;
         end;
      else
         Raise_Exception (Conversion_Error'Identity);
      end if;
   end Signed_To_Decimal;

   function Length_To_Packed (Item : Long_Long_Integer) return Natural;
   function To_Packed_Unsigned (Item : Long_Long_Integer)
      return Packed_Decimal;
   function To_Packed_Signed (Item : Long_Long_Integer)
      return Packed_Decimal;

   function Length_To_Packed (Item : Long_Long_Integer) return Natural is
   begin
      return 2
         + Natural (
            System.Formatting.Unsigned (
               System.Formatting.Width (
                  System.Formatting.Longest_Unsigned (Item)))
            and not 1);
   end Length_To_Packed;

   function To_Packed_Unsigned (Item : Long_Long_Integer)
      return Packed_Decimal is
   begin
      if Item < 0 then
         Raise_Exception (Conversion_Error'Identity);
      end if;
      return Result : Packed_Decimal (1 .. Length_To_Packed (Item)) do
         declare
            X : System.Long_Long_Integer_Divisions.Longest_Unsigned :=
               System.Long_Long_Integer_Divisions.Longest_Unsigned (Item);
         begin
            for I in reverse Result'First .. Result'Last - 1 loop
               System.Long_Long_Integer_Divisions.Divide (X, 10,
                  Quotient => X,
                  Remainder =>
                     System.Long_Long_Integer_Divisions.Longest_Unsigned (
                        Result (I)));
            end loop;
         end;
         Result (Result'Last) := 16#F#;
      end return;
   end To_Packed_Unsigned;

   function To_Packed_Signed (Item : Long_Long_Integer)
      return Packed_Decimal is
   begin
      return Result : Packed_Decimal := To_Packed_Unsigned (abs Item) do
         if Item < 0 then
            Result (Result'Last) := 16#D#;
         else
            Result (Result'Last) := 16#C#;
         end if;
      end return;
   end To_Packed_Signed;

   --  implementation

   function Ada_To_COBOL (
      Item : Character;
      Substitute : COBOL_Character := '?')
      return COBOL_Character is
   begin
      return COBOL_Character (
         System.C_Encoding.To_char (
            Item,
            Substitute => C.char (Substitute)));
   end Ada_To_COBOL;

   function COBOL_To_Ada (
      Item : COBOL_Character;
      Substitute : Character := '?')
      return Character is
   begin
      return System.C_Encoding.To_Character (
         C.char (Item),
         Substitute => Substitute);
   end COBOL_To_Ada;

   function To_COBOL (
      Item : String;
      Substitute : Alphanumeric := "?")
      return Alphanumeric
   is
      Result : Alphanumeric (
         1 ..
         System.C_Encoding.Expanding_To_char * Item'Length);
      Last : Natural;
   begin
      To_COBOL (Item, Result, Last, Substitute => Substitute);
      return Result (1 .. Last);
   end To_COBOL;

   function To_Ada (
      Item : Alphanumeric;
      Substitute : String := "?")
      return String
   is
      Result : String (
         1 ..
         System.C_Encoding.Expanding_To_Character * Item'Length);
      Last : Natural;
   begin
      To_Ada (Item, Result, Last, Substitute => Substitute);
      return Result (1 .. Last);
   end To_Ada;

   procedure To_COBOL (
      Item : String;
      Target : out Alphanumeric;
      Last : out Natural;
      Substitute : Alphanumeric := "?")
   is
      Target_As_C : C.char_array (0 .. Target'Length - 1);
      for Target_As_C'Address use Target'Address;
      Substitute_As_C : C.char_array (0 .. Substitute'Length - 1);
      for Substitute_As_C'Address use Substitute'Address;
      Count : C.size_t;
   begin
      System.C_Encoding.To_Non_Nul_Terminated (
         Item,
         Target_As_C,
         Count,
         Substitute => Substitute_As_C);
      Last := Target'First + Natural (Count) - 1;
   end To_COBOL;

   procedure To_Ada (
      Item : Alphanumeric;
      Target : out String;
      Last : out Natural;
      Substitute : String := "?")
   is
      Item_As_C : C.char_array (0 .. Item'Length - 1);
      for Item_As_C'Address use Item'Address;
      Count : Natural;
   begin
      System.C_Encoding.From_Non_Nul_Terminated (
         Item_As_C,
         Target,
         Count,
         Substitute => Substitute);
      Last := Target'First + Count - 1;
   end To_Ada;

   package body Decimal_Conversions is

      function Valid (Item : Numeric; Format : Display_Format)
         return Boolean is
      begin
         case Format is
            when U => -- Unsigned
               return Valid_Unsigned (Item);
            when LS => -- Leading_Separate
               return Valid_Leading_Separate (Item);
            when TS => -- Trailing_Separate
               return Valid_Trailing_Separate (Item);
            when LN => -- Leading_Nonseparate
               return Valid_Leading_Nonseparate (Item);
            when TN => -- Trailing_Nonseparate
               return Valid_Trailing_Nonseparate (Item);
         end case;
      end Valid;

      function Length (Format : Display_Format) return Natural is
      begin
         case Format is
            when U | LN | TN => -- Unsigned or Nonseparate
               return Num'Digits;
            when LS | TS => -- Separate
               return Num'Digits + 1;
         end case;
      end Length;

      function To_Decimal (Item : Numeric; Format : Display_Format)
         return Num
      is
         Result : Num'Base;
      begin
         case Format is
            when U => -- Unsigned
               Result := Num'Base'Fixed_Value (Unsigned_To_Decimal (Item));
            when LS => -- Leading_Separate
               Result := Num'Base'Fixed_Value (
                  Leading_Separate_To_Decimal (Item));
            when TS => -- Trailing_Separate
               Result := Num'Base'Fixed_Value (
                  Trailing_Separate_To_Decimal (Item));
            when LN => -- Leading_Nonseparate
               Result := Num'Base'Fixed_Value (
                  Leading_Nonseparate_To_Decimal (Item));
            when TN => -- Trailing_Nonseparate
               Result := Num'Base'Fixed_Value (
                  Trailing_Nonseparate_To_Decimal (Item));
         end case;
         if Result not in Num then
            raise Conversion_Error;
         end if;
         return Result;
      end To_Decimal;

      function To_Display (Item : Num; Format : Display_Format)
         return Numeric is
      begin
         case Format is
            when U => -- Unsigned
               return To_Display_Unsigned (
                  Long_Long_Integer'Integer_Value (Item));
            when LS => -- Leading_Separate
               return To_Display_Leading_Separate (
                  Long_Long_Integer'Integer_Value (Item));
            when TS => -- Trailing_Separate
               return To_Display_Trailing_Separate (
                  Long_Long_Integer'Integer_Value (Item));
            when LN => -- Leading_Nonseparate
               return To_Display_Leading_Nonseparate (
                  Long_Long_Integer'Integer_Value (Item));
            when TN => -- Trailing_Nonseparate
               return To_Display_Trailing_Nonseparate (
                  Long_Long_Integer'Integer_Value (Item));
         end case;
      end To_Display;

      function Valid (Item : Packed_Decimal; Format : Packed_Format)
         return Boolean is
      begin
         case Format is
            when U => -- Packed_Unsigned
               return Valid_Unsigned (Item);
            when S => -- Packed_Signed
               return Valid_Signed (Item);
         end case;
      end Valid;

      function Length (Format : Packed_Format) return Natural is
         pragma Unreferenced (Format);
      begin
         return 2
            + Natural (System.Formatting.Unsigned'(Num'Digits) and not 1);
      end Length;

      function To_Decimal (Item : Packed_Decimal; Format : Packed_Format)
         return Num
      is
         Result : Num'Base;
      begin
         case Format is
            when U => -- Packed_Unsigned
               Result := Num'Base'Fixed_Value (Unsigned_To_Decimal (Item));
            when S => -- Packed_Signed
               Result := Num'Base'Fixed_Value (Signed_To_Decimal (Item));
         end case;
         if Result not in Num then
            raise Conversion_Error;
         end if;
         return Result;
      end To_Decimal;

      function To_Packed (Item : Num; Format : Packed_Format)
         return Packed_Decimal is
      begin
         case Format is
            when U => -- Packed_Unsigned
               return To_Packed_Unsigned (
                  Long_Long_Integer'Integer_Value (Item));
            when S => -- Packed_Signed
               return To_Packed_Signed (
                  Long_Long_Integer'Integer_Value (Item));
         end case;
      end To_Packed;

   end Decimal_Conversions;

end Interfaces.COBOL;