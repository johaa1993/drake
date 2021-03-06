pragma License (Unrestricted);
--  generalized unit of Ada.Strings.Hash_Case_Insensitive
with Ada.Containers;
generic
   type Character_Type is (<>);
   type String_Type is array (Positive range <>) of Character_Type;
   with procedure Get (
      Item : String_Type;
      Last : out Natural;
      Value : out Wide_Wide_Character;
      Is_Illegal_Sequence : out Boolean);
function Ada.Strings.Generic_Hash_Case_Insensitive (Key : String_Type)
   return Containers.Hash_Type;
--  pragma Pure (Ada.Strings.Generic_Hash_Case_Insensitive);
pragma Preelaborate (Ada.Strings.Generic_Hash_Case_Insensitive); -- use maps
