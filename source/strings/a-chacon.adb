package body Ada.Characters.Conversions is
   use type System.UTF_Conversions.From_Status_Type;
   use type System.UTF_Conversions.To_Status_Type;

   function Is_Wide_Character (Item : Character) return Boolean is
   begin
      return Character'Pos (Item) <= 16#7f#;
   end Is_Wide_Character;

   function Is_Wide_String (Item : String) return Boolean is
      Last : Natural := Item'First - 1;
   begin
      while Last /= Item'Last loop
         declare
            Code : System.UTF_Conversions.UCS_4;
            From_State : System.UTF_Conversions.From_Status_Type;
         begin
            System.UTF_Conversions.From_UTF_8 (
               Item,
               Last,
               Code,
               From_State);
            --  a check for detecting illegal sequence are omitted
            if System.UTF_Conversions.UCS_4'Pos (Code) > 16#10ffff# then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Wide_String;

   function Is_Character (Item : Wide_Character) return Boolean is
   begin
      return Wide_Character'Pos (Item) <= 16#7f#;
   end Is_Character;

   function Is_String (Item : Wide_String) return Boolean is
      pragma Unreferenced (Item);
   begin
      --  a check for detecting illegal sequence are omitted
      return True;
   end Is_String;

   function Is_Wide_Wide_Character (Item : Wide_Character) return Boolean is
   begin
      return Wide_Character'Pos (Item) not in 16#d800# .. 16#dfff#;
   end Is_Wide_Wide_Character;

   function Is_Character (Item : Wide_Wide_Character) return Boolean is
   begin
      return Wide_Wide_Character'Pos (Item) <= 16#7f#;
   end Is_Character;

   function Is_String (Item : Wide_Wide_String) return Boolean is
      pragma Unreferenced (Item);
   begin
      --  a check for detecting illegal sequence are omitted
      return True;
   end Is_String;

   function Is_Wide_Character (Item : Wide_Wide_Character) return Boolean is
   begin
      --  a check for detecting illegal sequence are omitted
      return Wide_Wide_Character'Pos (Item) <= 16#ffff#;
   end Is_Wide_Character;

   function Is_Wide_String (Item : Wide_Wide_String) return Boolean is
   begin
      for I in Item'Range loop
         --  a check for detecting illegal sequence are omitted
         if Wide_Wide_Character'Pos (Item (I)) > 16#10ffff# then
            return False;
         end if;
      end loop;
      return True;
   end Is_Wide_String;

   function To_Wide_Character (
      Item : Character;
      Substitute : Wide_Character := ' ')
      return Wide_Character is
   begin
      if Is_Wide_Character (Item) then
         return Wide_Character'Val (Character'Pos (Item));
      else
         return Substitute;
      end if;
   end To_Wide_Character;

   function To_Wide_Wide_Character (
      Item : Character;
      Substitute : Wide_Wide_Character := ' ')
      return Wide_Wide_Character is
   begin
      if Is_Wide_Wide_Character (Item) then
         return Wide_Wide_Character'Val (Character'Pos (Item));
      else
         return Substitute;
      end if;
   end To_Wide_Wide_Character;

   function To_Wide_Wide_Character (
      Item : Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
      return Wide_Wide_Character is
   begin
      if Is_Wide_Wide_Character (Item) then
         return Wide_Wide_Character'Val (Wide_Character'Pos (Item));
      else
         return Substitute;
      end if;
   end To_Wide_Wide_Character;

   function To_Character (
      Item : Wide_Character;
      Substitute : Character := ' ')
      return Character is
   begin
      if Is_Character (Item) then
         return Character'Val (Wide_Character'Pos (Item));
      else
         return Substitute;
      end if;
   end To_Character;

   function To_String (
      Item : Wide_String;
      Substitute : Character := ' ')
      return String is
   begin
      return To_String (Item, Substitute => (1 => Substitute));
   end To_String;

   function To_Character (
      Item : Wide_Wide_Character;
      Substitute : Character := ' ')
      return Character is
   begin
      if Is_Character (Item) then
         return Character'Val (Wide_Wide_Character'Pos (Item));
      else
         return Substitute;
      end if;
   end To_Character;

   function To_String (
      Item : Wide_Wide_String;
      Substitute : Character := ' ')
      return String is
   begin
      return To_String (Item, Substitute => (1 => Substitute));
   end To_String;

   function To_Wide_Character (
      Item : Wide_Wide_Character;
      Substitute : Wide_Character := ' ')
      return Wide_Character is
   begin
      if Is_Wide_Character (Item) then
         return Wide_Character'Val (Wide_Wide_Character'Pos (Item));
      else
         return Substitute;
      end if;
   end To_Wide_Character;

   function To_Wide_String (
      Item : Wide_Wide_String;
      Substitute : Wide_Character := ' ')
      return Wide_String is
   begin
      return To_Wide_String (Item, Substitute => (1 => Substitute));
   end To_Wide_String;

   procedure Get (
      Item : String;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_8 (
         Item,
         Last,
         Code,
         From_Status);
      if From_Status /= System.UTF_Conversions.Success then
         Value := Substitute;
      else
         Value := Wide_Wide_Character'Val (Code);
      end if;
   end Get;

   procedure Get (
      Item : String;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean)
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_8 (
         Item,
         Last,
         Code,
         From_Status);
      Value := Wide_Wide_Character'Val (Code);
      Is_Illegal_Sequence := From_Status /= System.UTF_Conversions.Success;
   end Get;

   procedure Get_Reverse (
      Item : String;
      First : out Positive;
      Value : out Wide_Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_8_Reverse (
         Item,
         First,
         Code,
         From_Status);
      if From_Status /= System.UTF_Conversions.Success then
         Value := Substitute;
      else
         Value := Wide_Wide_Character'Val (Code);
      end if;
   end Get_Reverse;

   procedure Get_Reverse (
      Item : String;
      First : out Positive;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean)
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_8_Reverse (
         Item,
         First,
         Code,
         From_Status);
      Value := Wide_Wide_Character'Val (Code);
      Is_Illegal_Sequence := From_Status /= System.UTF_Conversions.Success;
   end Get_Reverse;

   procedure Get (
      Item : Wide_String;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_16 (
         Item,
         Last,
         Code,
         From_Status);
      if From_Status /= System.UTF_Conversions.Success then
         Value := Substitute;
      else
         Value := Wide_Wide_Character'Val (Code);
      end if;
   end Get;

   procedure Get (
      Item : Wide_String;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean)
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_16 (
         Item,
         Last,
         Code,
         From_Status);
      Value := Wide_Wide_Character'Val (Code);
      Is_Illegal_Sequence := From_Status /= System.UTF_Conversions.Success;
   end Get;

   procedure Get_Reverse (
      Item : Wide_String;
      First : out Positive;
      Value : out Wide_Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_16_Reverse (
         Item,
         First,
         Code,
         From_Status);
      if From_Status /= System.UTF_Conversions.Success then
         Value := Substitute;
      else
         Value := Wide_Wide_Character'Val (Code);
      end if;
   end Get_Reverse;

   procedure Get_Reverse (
      Item : Wide_String;
      First : out Positive;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean)
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_16_Reverse (
         Item,
         First,
         Code,
         From_Status);
      Value := Wide_Wide_Character'Val (Code);
      Is_Illegal_Sequence := From_Status /= System.UTF_Conversions.Success;
   end Get_Reverse;

   procedure Get (
      Item : Wide_Wide_String;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_32 (
         Item,
         Last,
         Code,
         From_Status);
      if From_Status /= System.UTF_Conversions.Success then
         Value := Substitute;
      else
         Value := Wide_Wide_Character'Val (Code);
      end if;
   end Get;

   procedure Get (
      Item : Wide_Wide_String;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean)
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_32 (
         Item,
         Last,
         Code,
         From_Status);
      Value := Wide_Wide_Character'Val (Code);
      Is_Illegal_Sequence := From_Status /= System.UTF_Conversions.Success;
   end Get;

   procedure Get_Reverse (
      Item : Wide_Wide_String;
      First : out Positive;
      Value : out Wide_Wide_Character;
      Substitute : Wide_Wide_Character := ' ')
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_32_Reverse (
         Item,
         First,
         Code,
         From_Status);
      if From_Status /= System.UTF_Conversions.Success then
         Value := Substitute;
      else
         Value := Wide_Wide_Character'Val (Code);
      end if;
   end Get_Reverse;

   procedure Get_Reverse (
      Item : Wide_Wide_String;
      First : out Positive;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean)
   is
      Code : System.UTF_Conversions.UCS_4;
      From_Status : System.UTF_Conversions.From_Status_Type;
   begin
      System.UTF_Conversions.From_UTF_32_Reverse (
         Item,
         First,
         Code,
         From_Status);
      Value := Wide_Wide_Character'Val (Code);
      Is_Illegal_Sequence := From_Status /= System.UTF_Conversions.Success;
   end Get_Reverse;

   procedure Put (
      Value : Wide_Wide_Character;
      Item : out String;
      Last : out Natural)
   is
      To_Status : System.UTF_Conversions.To_Status_Type;
   begin
      System.UTF_Conversions.To_UTF_8 (
         Wide_Wide_Character'Pos (Value),
         Item,
         Last,
         To_Status);
      if To_Status /= System.UTF_Conversions.Success then
         raise Constraint_Error; -- Strings.Length_Error ???
      end if;
   end Put;

   procedure Put (
      Value : Wide_Wide_Character;
      Item : out Wide_String;
      Last : out Natural)
   is
      To_Status : System.UTF_Conversions.To_Status_Type;
   begin
      System.UTF_Conversions.To_UTF_16 (
         Wide_Wide_Character'Pos (Value),
         Item,
         Last,
         To_Status);
      if To_Status /= System.UTF_Conversions.Success then
         raise Constraint_Error;
      end if;
   end Put;

   procedure Put (
      Value : Wide_Wide_Character;
      Item : out Wide_Wide_String;
      Last : out Natural)
   is
      To_Status : System.UTF_Conversions.To_Status_Type;
   begin
      System.UTF_Conversions.To_UTF_32 (
         Wide_Wide_Character'Pos (Value),
         Item,
         Last,
         To_Status);
      if To_Status /= System.UTF_Conversions.Success then
         raise Constraint_Error;
      end if;
   end Put;

end Ada.Characters.Conversions;
