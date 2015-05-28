pragma License (Unrestricted);
with Ada.IO_Modes;
with Ada.Streams.Stream_IO;
with Ada.Text_IO.Text_Streams;
package Ada.Wide_Text_IO.Text_Streams is

--  type Stream_Access is access all Streams.Root_Stream_Type'Class;
   subtype Stream_Access is Streams.Stream_IO.Stream_Access;

   --  extended
   procedure Open (
      File : in out File_Type;
      Mode : File_Mode;
      Stream : Stream_Access;
      Name : String := "";
      Form : String) -- removed default
      renames Text_IO.Text_Streams.Open;
   procedure Open (
      File : in out File_Type;
      Mode : File_Mode;
      Stream : Stream_Access;
      Name : String := "";
      Shared : IO_Modes.File_Shared_Spec := IO_Modes.By_Mode;
      Wait : Boolean := False;
      Overwrite : Boolean := True;
      External : IO_Modes.File_External_Spec := IO_Modes.By_Target;
      New_Line : IO_Modes.File_New_Line_Spec := IO_Modes.By_Target)
      renames Text_IO.Text_Streams.Open;

   function Stream (
      File : File_Type) -- Open_File_Type
      return Stream_Access
      renames Text_IO.Text_Streams.Stream;

end Ada.Wide_Text_IO.Text_Streams;
