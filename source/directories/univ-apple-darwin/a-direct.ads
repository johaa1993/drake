pragma License (Unrestricted);
with Ada.IO_Exceptions;
with Ada.Calendar;
with Ada.Streams;
private with Ada.Finalization;
private with C.dirent;
private with C.sys.dirent;
private with C.sys.stat;
package Ada.Directories is

   --  Directory and file operations:

   function Current_Directory return String;

   procedure Set_Directory (Directory : String);

   procedure Create_Directory (
      New_Directory : String;
      Form : String := "");

   procedure Delete_Directory (Directory : String);

   procedure Create_Path (
      New_Directory : String;
      Form : String := "");

   procedure Delete_Tree (Directory : String);

   procedure Delete_File (Name : String);

   --  modified
   procedure Rename (
      Old_Name : String;
      New_Name : String;
      Overwrite : Boolean := True); -- additional

   --  modified
   procedure Copy_File (
      Source_Name : String;
      Target_Name : String;
      Form : String := "";
      Overwrite : Boolean := True); -- additional

   --  extended
   --  Create a symbolic link.
   procedure Symbolic_Link (
      Source_Name : String;
      Target_Name : String;
      Overwrite : Boolean := True);

   --  File and directory name operations:

   function Full_Name (Name : String) return String;

   function Simple_Name (Name : String) return String;

   function Containing_Directory (Name : String) return String;

   function Extension (Name : String) return String;

   function Base_Name (Name : String) return String;

   function Compose (
      Containing_Directory : String := "";
      Name : String;
      Extension : String := "")
      return String;

   --  extended
   --  There are procedure version.
   procedure Simple_Name (
      Name : String;
      First : out Positive;
      Last : out Natural);
   procedure Containing_Directory (
      Name : String;
      First : out Positive;
      Last : out Natural);
   procedure Extension (
      Name : String;
      First : out Positive;
      Last : out Natural);
   procedure Base_Name (
      Name : String;
      First : out Positive;
      Last : out Natural);

   --  File and directory queries:

   type File_Kind is (Directory, Ordinary_File, Special_File);

   --  modified
--  type File_Size is range 0 .. implementation-defined;
   subtype File_Size is Streams.Stream_Element_Count;

   function Exists (Name : String) return Boolean;

   function Kind (Name : String) return File_Kind;

   function Size (Name : String) return File_Size;

   function Modification_Time (Name : String) return Calendar.Time;

   --  extended
   --  Set modification time of a file.
   procedure Set_Modification_Time (Name : String; Time : Calendar.Time);

   --  Directory searching:

   type Directory_Entry_Type is limited private;

   type Filter_Type is array (File_Kind) of Boolean;

   type Search_Type is limited private;

   --  modified
   procedure Start_Search (
      Search : in out Search_Type;
      Directory : String;
      Pattern : String := "*"; -- additional default
      Filter : Filter_Type := (others => True));

   --  extended
   function Start_Search (
      Directory : String;
      Pattern : String := "*";
      Filter : Filter_Type := (others => True))
      return Search_Type;

   procedure End_Search (Search : in out Search_Type);

   function More_Entries (Search : Search_Type) return Boolean;

   procedure Get_Next_Entry (
      Search : in out Search_Type;
      Directory_Entry : out Directory_Entry_Type);

   --  modified
   procedure Search (
      Directory : String;
      Pattern : String := "*"; -- additional default
      Filter : Filter_Type := (others => True);
      Process : not null access procedure (
         Directory_Entry : Directory_Entry_Type));

   --  extended
   --  There is an iterator for AI12-0009-1 (?)
   type Iterator is limited private;
   type Cursor is private;
   pragma Preelaborable_Initialization (Cursor);
   function Has_Element (Position : Cursor) return Boolean;
   function Iterate (Container : Search_Type) return Iterator;
   function First (Object : Iterator) return Cursor;
   function Next (Object : Iterator; Position : Cursor) return Cursor;
   type Constant_Reference_Type (
      Element : not null access constant Directory_Entry_Type) is null record;
   function Constant_Reference (Container : Search_Type; Position : Cursor)
      return Constant_Reference_Type;

   --  Operations on Directory Entries:

   function Simple_Name (Directory_Entry : Directory_Entry_Type)
      return String;

   function Full_Name (Directory_Entry : Directory_Entry_Type)
      return String;

   function Kind (Directory_Entry : Directory_Entry_Type)
      return File_Kind;

   function Size (Directory_Entry : Directory_Entry_Type)
      return File_Size;

   function Modification_Time (Directory_Entry : Directory_Entry_Type)
      return Calendar.Time;

   Status_Error : exception
      renames IO_Exceptions.Status_Error;
   Name_Error : exception
      renames IO_Exceptions.Name_Error;
   Use_Error : exception
      renames IO_Exceptions.Use_Error;
   Device_Error : exception
      renames IO_Exceptions.Device_Error;

private

   type String_Access is access String;

   type Directory_Entry_Type is record -- not limited in full view
      Path : String_Access := null;
      Entry_Data : aliased C.sys.dirent.struct_dirent;
      State_Data : aliased C.sys.stat.struct_stat;
   end record;

   type Search_Type is new Finalization.Limited_Controlled with record
      Handle : C.dirent.DIR_ptr := null;
      Path : String_Access;
      Pattern : C.char_ptr;
      Filter : Filter_Type;
      Count : Natural;
      Has_Next : Boolean;
      Data : aliased C.sys.dirent.struct_dirent;
   end record;

   overriding procedure Finalize (Search : in out Search_Type);
   procedure End_Search (Search : in out Search_Type) renames Finalize;

   type Iterator is access Search_Type;

   type Cursor is record
      Search : Iterator := null;
      Directory_Entry : aliased Directory_Entry_Type;
      Index : Positive;
   end record;

   --  for Information
   procedure Check_Assigned (Directory_Entry : Directory_Entry_Type);
   procedure Get_Attributes (
      Name : String;
      Attributes : out C.sys.stat.struct_stat);

   --  for Temporary
   procedure Include_Trailing_Path_Delimiter (
      S : in out String;
      Last : in out Natural);

   --  for Hierarchical_File_Names
   procedure Exclude_Trailing_Path_Delimiter (
      S : String;
      Last : in out Natural);

end Ada.Directories;