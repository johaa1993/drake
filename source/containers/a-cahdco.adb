with Ada.Unchecked_Conversion;
package body Ada.Containers.Access_Holders_Derivational_Conversions is

   procedure Assign (
      Target : in out Base_Holders.Holder;
      Source : Derived_Holders.Holder)
   is
      type Base_Holder_Access is access all Base_Holders.Holder;
      for Base_Holder_Access'Storage_Size use 0;
      type Derived_Holder_Access is access constant Derived_Holders.Holder;
      for Derived_Holder_Access'Storage_Size use 0;
      function Cast is
         new Unchecked_Conversion (Derived_Holder_Access, Base_Holder_Access);
   begin
      Base_Holders.Assign (Target, Cast (Source'Access).all);
   end Assign;

   procedure Move (
      Target : in out Base_Holders.Holder;
      Source : in out Derived_Holders.Holder)
   is
      type Base_Holder_Access is access all Base_Holders.Holder;
      for Base_Holder_Access'Storage_Size use 0;
      type Derived_Holder_Access is access all Derived_Holders.Holder;
      for Derived_Holder_Access'Storage_Size use 0;
      function Cast is
         new Unchecked_Conversion (Derived_Holder_Access, Base_Holder_Access);
   begin
      Base_Holders.Move (Target, Cast (Source'Access).all);
   end Move;

end Ada.Containers.Access_Holders_Derivational_Conversions;
