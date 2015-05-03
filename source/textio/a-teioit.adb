with Ada.Exception_Identification.From_Here;
package body Ada.Text_IO.Iterators is
   use Exception_Identification.From_Here;

   --  implementation

   function Lines (File : File_Type) return Lines_Type is
   begin
      return (Finalization.Limited_Controlled with
         File => File'Unrestricted_Access,
         Item => null,
         Count => 0);
   end Lines;

   function Has_Element (Position : Line_Cursor) return Boolean is
   begin
      return Position > 0;
   end Has_Element;

   function Element (Container : Lines_Type'Class; Position : Line_Cursor)
      return String is
   begin
      return Constant_Reference (Container, Position).Element.all;
   end Element;

   function Constant_Reference (
      Container : aliased Lines_Type;
      Position : Line_Cursor)
      return References.Strings.Constant_Reference_Type is
   begin
      if Integer (Position) /= Container.Count then
         Raise_Exception (Status_Error'Identity);
      end if;
      return (Element => Container.Item);
   end Constant_Reference;

   function Iterate (Container : Lines_Type'Class)
      return Lines_Iterator_Interfaces.Forward_Iterator'Class is
   begin
      return Line_Iterator'(Lines => Container'Unrestricted_Access);
   end Iterate;

   overriding procedure Finalize (Object : in out Lines_Type) is
   begin
      Free (Object.Item);
   end Finalize;

   overriding function First (Object : Line_Iterator) return Line_Cursor is
   begin
      if End_Of_File (Object.Lines.File.all) then
         return 0; -- No_Element
      else
         Free (Object.Lines.Item);
         Object.Lines.Count := Object.Lines.Count + 1;
         Overloaded_Get_Line (
            Object.Lines.File.all,
            Object.Lines.Item); -- allocation
         return Line_Cursor (Object.Lines.Count);
      end if;
   end First;

   overriding function Next (Object : Line_Iterator; Position : Line_Cursor)
      return Line_Cursor is
   begin
      if Integer (Position) /= Object.Lines.Count then
         Raise_Exception (Status_Error'Identity);
      end if;
      return First (Object);
   end Next;

end Ada.Text_IO.Iterators;
