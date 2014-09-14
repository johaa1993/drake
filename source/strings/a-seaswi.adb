with Ada.UCD.East_Asian_Width;
package body Ada.Strings.East_Asian_Width is
   use type UCD.UCS_4;

   pragma Compile_Time_Error (
      UCD.East_Asian_Width_Type'Pos (UCD.N) /=
         Width_Kind'Pos (Neutral)
      or else UCD.East_Asian_Width_Type'Pos (UCD.Na) /=
         Width_Kind'Pos (Narrow)
      or else UCD.East_Asian_Width_Type'Pos (UCD.H) /=
         Width_Kind'Pos (Half_Width)
      or else UCD.East_Asian_Width_Type'Pos (UCD.A) /=
         Width_Kind'Pos (Ambiguous)
      or else UCD.East_Asian_Width_Type'Pos (UCD.W) /=
         Width_Kind'Pos (Wide)
      or else UCD.East_Asian_Width_Type'Pos (UCD.F) /=
         Width_Kind'Pos (Full_Width),
      "bad order");

   function Search (
      Table : UCD.East_Asian_Width.Table_16_Type;
      Code : UCD.UCS_4)
      return UCD.East_Asian_Width_Type;
   function Search (
      Table : UCD.East_Asian_Width.Table_16_Type;
      Code : UCD.UCS_4)
      return UCD.East_Asian_Width_Type
   is
      L : Positive := Table'First;
      H : Natural := Table'Last;
   begin
      loop
         declare
            M : constant Positive := (L + H) / 2;
         begin
            if Code < Table (M).Start then
               H := M - 1;
            elsif Code >=
               Table (M).Start + UCD.UCS_4 (Table (M).Length)
            then
               L := M + 1;
            else
               return Table (M).Width;
            end if;
         end;
         if L > H then
            return UCD.N;
         end if;
      end loop;
   end Search;

   function Search (
      Table : UCD.East_Asian_Width.Table_32_Type;
      Code : UCD.UCS_4)
      return UCD.East_Asian_Width_Type;
   function Search (
      Table : UCD.East_Asian_Width.Table_32_Type;
      Code : UCD.UCS_4)
      return UCD.East_Asian_Width_Type
   is
      L : Positive := Table'First;
      H : Natural := Table'Last;
   begin
      loop
         declare
            M : constant Positive := (L + H) / 2;
         begin
            if Code < Table (M).Start then
               H := M - 1;
            elsif Code >=
               Table (M).Start + UCD.UCS_4 (Table (M).Length)
            then
               L := M + 1;
            else
               return Table (M).Width;
            end if;
         end;
         if L > H then
            return UCD.N;
         end if;
      end loop;
   end Search;

   --  implementation

   function Kind (C : Wide_Wide_Character) return Width_Kind is
      Code : constant UCD.UCS_4 := Wide_Wide_Character'Pos (C);
   begin
      case Code is
         when 0 .. 16#FFFF# =>
            return Width_Kind'Val (UCD.East_Asian_Width_Type'Pos (
               Search (UCD.East_Asian_Width.Table_XXXX, Code)));
         when 16#10000# .. 16#1FFFF# =>
            return Width_Kind'Val (UCD.East_Asian_Width_Type'Pos (
               Search (UCD.East_Asian_Width.Table_1XXXX, Code - 16#10000#)));
         when 16#20000# .. 16#7FFFFFFF# =>
            return Width_Kind'Val (UCD.East_Asian_Width_Type'Pos (
               Search (UCD.East_Asian_Width.Table_XXXXXXXX, Code)));
      end case;
   end Kind;

   function Is_Full_Width (W : Width_Kind; East_Asian : Boolean)
      return Boolean is
   begin
      return Width_Kind'Pos (W) >
         Width_Kind'Pos (Ambiguous) - Boolean'Pos (East_Asian);
   end Is_Full_Width;

end Ada.Strings.East_Asian_Width;
