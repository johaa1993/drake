pragma License (Unrestricted);
--  extended unit
with Ada.Iterator_Interfaces;
with Ada.References.Strings;
private with Ada.Finalization;
package Ada.Text_IO.Iterators is
   --  Iterators for Ada.Text_IO.File_Type.

   --  per line

   type Lines_Type is tagged limited private
      with
         Constant_Indexing => Constant_Reference,
         Default_Iterator => Iterate,
         Iterator_Element => String;

   function Lines (
      File : File_Type) -- Input_File_Type
      return Lines_Type;

   type Line_Cursor is private;
   pragma Preelaborable_Initialization (Line_Cursor);

   function Has_Element (Position : Line_Cursor) return Boolean;

   function Element (Container : Lines_Type'Class; Position : Line_Cursor)
      return String;

   function Constant_Reference (
      Container : aliased Lines_Type;
      Position : Line_Cursor)
      return References.Strings.Constant_Reference_Type;

   package Lines_Iterator_Interfaces is
      new Iterator_Interfaces (Line_Cursor, Has_Element);

   function Iterate (Container : Lines_Type'Class)
      return Lines_Iterator_Interfaces.Forward_Iterator'Class;

private

   type Lines_Type is limited new Finalization.Limited_Controlled with record
      File : File_Access;
      Item : String_Access;
      Count : Natural;
   end record;

   overriding procedure Finalize (Object : in out Lines_Type);

   type Lines_Access is access all Lines_Type;
   for Lines_Access'Storage_Size use 0;

   type Line_Cursor is new Natural;

   type Line_Iterator is
      new Lines_Iterator_Interfaces.Forward_Iterator with
   record
      Lines : Lines_Access;
   end record;

   overriding function First (Object : Line_Iterator) return Line_Cursor;
   overriding function Next (Object : Line_Iterator; Position : Line_Cursor)
      return Line_Cursor;

end Ada.Text_IO.Iterators;
