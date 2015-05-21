pragma License (Unrestricted);
--  implementation unit specialized for Linux
with Ada.Streams;
with C.sys.statvfs;
package System.File_Systems is
   --  File system information.
   pragma Preelaborate;

   subtype File_Size is Ada.Streams.Stream_Element_Count;

   type Non_Controlled_File_System is record
      Info : aliased C.sys.statvfs.struct_statvfs64;
   end record;
   pragma Suppress_Initialization (Non_Controlled_File_System);

   procedure Get (
      Name : String;
      FS : aliased out Non_Controlled_File_System);

   function Size (FS : Non_Controlled_File_System) return File_Size;
   function Free_Space (FS : Non_Controlled_File_System) return File_Size;

   function Case_Preserving (FS : Non_Controlled_File_System) return Boolean;
   function Case_Sensitive (FS : Non_Controlled_File_System) return Boolean;

   pragma Inline (Case_Preserving);
   pragma Inline (Case_Sensitive);

   function Is_HFS (FS : Non_Controlled_File_System) return Boolean;

   pragma Inline (Is_HFS);

   --  unimplemented
   function Owner (FS : Non_Controlled_File_System) return String;
   function Format_Name (FS : Non_Controlled_File_System) return String;
   function Directory (FS : Non_Controlled_File_System) return String;
   function Device (FS : Non_Controlled_File_System) return String;
   pragma Import (Ada, Owner, "__drake_program_error");
   pragma Import (Ada, Format_Name, "__drake_program_error");
   pragma Import (Ada, Directory, "__drake_program_error");
   pragma Import (Ada, Device, "__drake_program_error");

   type File_System is record
      Data : aliased Non_Controlled_File_System;
   end record;
   pragma Suppress_Initialization (File_System);

   function Reference (Item : File_System)
      return not null access Non_Controlled_File_System;

end System.File_Systems;
