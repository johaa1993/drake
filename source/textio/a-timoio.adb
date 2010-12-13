with Ada.Formatting.Inside;
with Ada.Text_IO.Inside.Formatting;
with System.Formatting;
with System.Val_LLU;
with System.Val_Uns;
package body Ada.Text_IO.Modular_IO is
   pragma Suppress (All_Checks);
   use type System.Formatting.Longest_Unsigned;
   use type System.Formatting.Unsigned;

   procedure Put_To_Field (
      To : out String;
      Last : out Natural;
      Item : Num;
      Base : Number_Base);
   procedure Put_To_Field (
      To : out String;
      Last : out Natural;
      Item : Num;
      Base : Number_Base) is
   begin
      if Num'Size > System.Formatting.Unsigned'Size then
         Formatting.Inside.Modular_Image (
            To,
            Last,
            System.Formatting.Longest_Unsigned (Item),
            Base => Base,
            Zero_Sign => Formatting.None,
            Plus_Sign => Formatting.None);
      else
         Formatting.Inside.Modular_Image (
            To,
            Last,
            System.Formatting.Unsigned (Item),
            Base => Base,
            Zero_Sign => Formatting.None,
            Plus_Sign => Formatting.None);
      end if;
   end Put_To_Field;

   procedure Get_From_Field (
      From : String;
      Item : out Num;
      Last : out Positive);
   procedure Get_From_Field (
      From : String;
      Item : out Num;
      Last : out Positive) is
   begin
      if Num'Size > System.Formatting.Unsigned'Size then
         declare
            Result : System.Formatting.Longest_Unsigned;
         begin
            System.Val_LLU.Get_Longest_Unsigned_Literal (
               From,
               Last,
               Result);
            if Result > System.Formatting.Longest_Unsigned (Num'Last) then
               raise Data_Error;
            end if;
            Item := Num (Result);
         end;
      else
         declare
            Result : System.Formatting.Unsigned;
         begin
            System.Val_Uns.Get_Unsigned_Literal (
               From,
               Last,
               Result);
            if Result > System.Formatting.Unsigned (Num'Last) then
               raise Data_Error;
            end if;
            Item := Num (Result);
         end;
      end if;
   exception
      when Constraint_Error =>
         raise Data_Error;
   end Get_From_Field;

   procedure Get (
      File : File_Type;
      Item : out Num;
      Width : Field := 0) is
   begin
      if Width /= 0 then
         declare
            S : String (1 .. Width);
            Last_1 : Natural;
            Last_2 : Natural;
         begin
            Inside.Formatting.Get_Field (File, S, Last_1);
            Get_From_Field (S (1 .. Last_1), Item, Last_2);
            if Last_2 /= Last_1 then
               raise Data_Error;
            end if;
         end;
      else
         declare
            S : constant String :=
               Inside.Formatting.Get_Numeric_Literal (File, Real => False);
            Last : Natural;
         begin
            Get_From_Field (S, Item, Last);
            if Last /= S'Last then
               raise Data_Error;
            end if;
         end;
      end if;
   end Get;

   procedure Get (
      Item : out Num;
      Width : Field := 0) is
   begin
      Get (Current_Input.all, Item, Width);
   end Get;

   procedure Put (
      File : File_Type;
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base)
   is
      S : String (1 .. Formatting.Inside.Modular_Width);
      Last : Natural;
   begin
      Put_To_Field (S, Last, Item, Base);
      Inside.Formatting.Tail (File, S (1 .. Last), Width);
   end Put;

   procedure Put (
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base) is
   begin
      Put (Current_Output.all, Item, Width, Base);
   end Put;

   procedure Get (
      From : String;
      Item : out Num;
      Last : out Positive) is
   begin
      Inside.Formatting.Get_Tail (From, First => Last);
      Get_From_Field (From (Last .. From'Last), Item, Last);
   end Get;

   procedure Put (
      To : out String;
      Item : Num;
      Base : Number_Base := Default_Base)
   is
      S : String (1 .. Formatting.Inside.Modular_Width);
      Last : Natural;
   begin
      Put_To_Field (S, Last, Item, Base);
      Inside.Formatting.Tail (To, S (1 .. Last));
   end Put;

end Ada.Text_IO.Modular_IO;
