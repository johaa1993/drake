pragma License (Unrestricted);
with Ada.Characters.Conversions;
with Ada.Strings.Generic_Hash;
function Ada.Strings.Wide_Wide_Hash is
   new Generic_Hash (
      Wide_Wide_Character,
      Wide_Wide_String,
      Characters.Conversions.Get);
pragma Pure (Ada.Strings.Wide_Wide_Hash);
