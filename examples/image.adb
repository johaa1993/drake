with Ada;
procedure image is
	type Ordinal_Fixed is delta 0.1 range -99.9 .. 99.9;
	type Short_Fixed is delta 0.1 digits 2;
	type Long_Fixed is delta 0.1 digits 10;
	type Enum8 is (AAA, BBB, CCC);
	type Enum16 is (AAA, BBB, CCC);
	for Enum16 use (AAA => 0, BBB => 1, CCC => 16#ffff#);
	type Enum32 is (AAA, BBB, CCC);
	for Enum32 use (AAA => 0, BBB => 1, CCC => 16#ffffffff#);
	type Short_Short_Unsigned is mod 2 ** 8;
	type Long_Long_Unsigned is mod 2 ** Long_Long_Integer'Size;
	function Image (X : Boolean) return String renames Boolean'Image;
	function Image (X : Enum8) return String renames Enum8'Image;
	function Image (X : Enum16) return String renames Enum16'Image;
	function Image (X : Enum32) return String renames Enum32'Image;
begin
	pragma Assert (Boolean'Image (Boolean'First) = "FALSE");
	pragma Assert (Image (Boolean'Last) = "TRUE");
	pragma Assert (Enum8'Image (Enum8'First) = "AAA");
	pragma Assert (Image (Enum8'Last) = "CCC");
	pragma Assert (Enum16'Image (Enum16'First) = "AAA");
	pragma Assert (Image (Enum16'Last) = "CCC");
	pragma Assert (Enum32'Image (Enum32'First) = "AAA");
	pragma Assert (Image (Enum32'Last) = "CCC");
	pragma Assert (Character'Image (Character'First) = "NUL");
	pragma Assert (Character'Image (Character'Val (16#ad#)) = "Hex_AD");
	pragma Assert (Character'Image (Character'Last) = "Hex_FF");
	pragma Assert (Wide_Character'Image (Wide_Character'First) = "NUL");
	pragma Assert (Wide_Character'Image (Wide_Character'Val (16#ad#)) = "SOFT_HYPHEN");
	pragma Assert (Wide_Character'Image (Wide_Character'Last) = "Hex_FFFF");
	-- when using Wide_Wide_Character'Image, gcc-4.4.*/4.5.* are very slow...???
--	pragma Assert (Wide_Wide_Character'Image (Wide_Wide_Character'First) = "NUL");
--	pragma Assert (Wide_Wide_Character'Image (Wide_Wide_Character'Val (16#ad#)) = "SOFT_HYPHEN");
--	pragma Assert (Wide_Wide_Character'Image (Wide_Wide_Character'Last) = "Hex_7FFFFFFF");
	Ada.Debug.Put (Integer'Image (Integer'First));
	Ada.Debug.Put (Integer'Image (Integer'Last));
	Ada.Debug.Put (Long_Long_Integer'Image (Long_Long_Integer'First));
	Ada.Debug.Put (Long_Long_Integer'Image (Long_Long_Integer'Last));
	pragma Assert (Short_Short_Unsigned'Image (Short_Short_Unsigned'First) = " 0");
	pragma Assert (Short_Short_Unsigned'Image (Short_Short_Unsigned'Last) = " 255");
	Ada.Debug.Put (Long_Long_Unsigned'Image (Long_Long_Unsigned'First));
	Ada.Debug.Put (Long_Long_Unsigned'Image (Long_Long_Unsigned'Last));
	Ada.Debug.Put (Float'Image (Float'First));
	Ada.Debug.Put (Float'Image (Float'Last));
	Ada.Debug.Put (Long_Float'Image (Long_Float'First));
	Ada.Debug.Put (Long_Float'Image (Long_Float'Last));
	Ada.Debug.Put (Long_Long_Float'Image (Long_Long_Float'First));
	Ada.Debug.Put (Long_Long_Float'Image (Long_Long_Float'Last));
	pragma Assert (Ordinal_Fixed'Image (Ordinal_Fixed'First) = "-99.9");
	pragma Assert (Ordinal_Fixed'Image (Ordinal_Fixed'Last) = " 99.9");
	pragma Assert (Short_Fixed'Image (Short_Fixed'First) = "-9.9");
	pragma Assert (Short_Fixed'Image (Short_Fixed'Last) = " 9.9");
	pragma Assert (Long_Fixed'Image (Long_Fixed'First) = "-999999999.9");
	pragma Assert (Long_Fixed'Image (Long_Fixed'Last) = " 999999999.9");
	pragma Debug (Ada.Debug.Put ("OK"));
end image;
