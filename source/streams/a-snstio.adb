with Ada.Exception_Identification.From_Here;
with Ada.Exceptions.Finally;
with Ada.Unchecked_Deallocation;
with System.Form_Parameters;
with System.Standard_Allocators;
with System.Storage_Elements;
package body Ada.Streams.Naked_Stream_IO is
   use Exception_Identification.From_Here;
   use type IO_Modes.File_Mode;
   use type IO_Modes.File_Shared_Spec;
   use type Tags.Tag;
--  use type System.Address;
--  use type System.Native_IO.Handle_Type;
   use type System.Native_IO.Name_Pointer;
   use type System.Storage_Elements.Storage_Offset;

   procedure unreachable
      with Import,
         Convention => Intrinsic, External_Name => "__builtin_unreachable";
   pragma No_Return (unreachable);

   function To_Pointer (Value : System.Address)
      return access Root_Stream_Type'Class
      with Import, Convention => Intrinsic;

   --  the parameter Form

   procedure Set (
      Form : in out System.Native_IO.Packed_Form;
      Keyword : String;
      Item : String) is
   begin
      if Keyword = "shared" then
         if Item'Length > 0
            and then (
               Item (Item'First) = 'a' -- allow
               or else Item (Item'First) = 'y') -- yes, compatibility
         then
            Form.Shared := IO_Modes.Allow;
         elsif Item'Length > 0 and then Item (Item'First) = 'r' then -- read
            Form.Shared := IO_Modes.Read_Only;
         elsif Item'Length > 0 and then Item (Item'First) = 'd' then -- deny
            Form.Shared := IO_Modes.Deny;
         elsif Item'Length > 0 and then Item (Item'First) = 'n' then -- no
            Form.Shared := IO_Modes.By_Mode;
         end if;
      elsif Keyword = "wait" then
         if Item'Length > 0 and then Item (Item'First) = 'f' then -- false
            Form.Wait := False;
         elsif Item'Length > 0 and then Item (Item'First) = 't' then -- true
            Form.Wait := True;
         end if;
      elsif Keyword = "overwrite" then
         if Item'Length > 0 and then Item (Item'First) = 'f' then -- false
            Form.Overwrite := False;
         elsif Item'Length > 0 and then Item (Item'First) = 't' then -- true
            Form.Overwrite := True;
         end if;
      end if;
   end Set;

   function Pack (Form : String) return System.Native_IO.Packed_Form is
      Keyword_First : Positive;
      Keyword_Last : Natural;
      Item_First : Positive;
      Item_Last : Natural;
      Last : Natural;
   begin
      return Result : System.Native_IO.Packed_Form := Default_Form do
         Last := Form'First - 1;
         while Last < Form'Last loop
            System.Form_Parameters.Get (
               Form (Last + 1 .. Form'Last),
               Keyword_First,
               Keyword_Last,
               Item_First,
               Item_Last,
               Last);
            Set (
               Result,
               Form (Keyword_First .. Keyword_Last),
               Form (Item_First .. Item_Last));
         end loop;
      end return;
   end Pack;

   procedure Unpack (
      Form : System.Native_IO.Packed_Form;
      Result : out Form_String;
      Last : out Natural)
   is
      New_Last : Natural;
   begin
      Last := Form_String'First - 1;
      if Form.Shared /= IO_Modes.By_Mode then
         case IO_Modes.File_Shared (Form.Shared) is
            when IO_Modes.Allow =>
               New_Last := Last + 10;
               Result (Last + 1 .. New_Last) := "shared=yes";
               Last := New_Last;
            when IO_Modes.Read_Only =>
               New_Last := Last + 11;
               Result (Last + 1 .. New_Last) := "shared=read";
               Last := New_Last;
            when IO_Modes.Deny =>
               New_Last := Last + 12;
               Result (Last + 1 .. New_Last) := "shared=write";
               Last := New_Last;
         end case;
      end if;
      if Form.Wait then
         if Last /= Form_String'First - 1 then
            New_Last := Last + 1;
            Result (New_Last) := ',';
            Last := New_Last;
         end if;
         New_Last := Last + 9;
         Result (Last + 1 .. New_Last) := "wait=true";
         Last := New_Last;
      end if;
      if Form.Overwrite then
         if Last /= Form_String'First - 1 then
            New_Last := Last + 1;
            Result (New_Last) := ',';
            Last := New_Last;
         end if;
         New_Last := Last + 14;
         Result (Last + 1 .. New_Last) := "overwrite=true";
         Last := New_Last;
      end if;
   end Unpack;

   --  non-controlled

   function Allocate (
      Handle : System.Native_IO.Handle_Type;
      Mode : IO_Modes.File_Mode;
      Kind : Stream_Kind;
      Name : System.Native_IO.Name_Pointer;
      Name_Length : System.Native_IO.Name_Length;
      Form : System.Native_IO.Packed_Form;
      Closer : Close_Handler)
      return Non_Controlled_File_Type;
   function Allocate (
      Handle : System.Native_IO.Handle_Type;
      Mode : IO_Modes.File_Mode;
      Kind : Stream_Kind;
      Name : System.Native_IO.Name_Pointer;
      Name_Length : System.Native_IO.Name_Length;
      Form : System.Native_IO.Packed_Form;
      Closer : Close_Handler)
      return Non_Controlled_File_Type is
   begin
      return new Stream_Type'(
         Handle => Handle,
         Mode => Mode,
         Kind => Kind,
         Buffer_Inline => <>,
         Name => Name,
         Name_Length => Name_Length,
         Form => Form,
         Buffer => System.Null_Address,
         Buffer_Length => Uninitialized_Buffer,
         Buffer_Index => 0,
         Reading_Index => 0,
         Writing_Index => 0,
         Closer => Closer,
         Dispatcher => (Tag => Tags.No_Tag, File => null));
   end Allocate;

   procedure Free (File : in out Non_Controlled_File_Type);
   procedure Free (File : in out Non_Controlled_File_Type) is
      use type System.Address;
      procedure Raw_Free is
         new Unchecked_Deallocation (Stream_Type, Non_Controlled_File_Type);
   begin
      if File.Buffer /= File.Buffer_Inline'Address then
         System.Standard_Allocators.Free (File.Buffer);
      end if;
      System.Native_IO.Free (File.Name);
      Raw_Free (File);
   end Free;

   type Scoped_Handle_And_File_And_Name is record
      --  to cleanup
      Handle : aliased System.Native_IO.Handle_Type;
      File : aliased Non_Controlled_File_Type;
      --  for Handle, and to cleanup when File = null
      Name : aliased System.Native_IO.Name_Pointer;
      --  for Handle
      Closer : Close_Handler;
   end record;
   pragma Suppress_Initialization (Scoped_Handle_And_File_And_Name);

   procedure Finally (X : in out Scoped_Handle_And_File_And_Name);
   procedure Finally (X : in out Scoped_Handle_And_File_And_Name) is
      use type System.Native_IO.Handle_Type;
   begin
      if X.Handle /= System.Native_IO.Invalid_Handle then
         --  External_No_Close is not set to Scoped_Handle_And_File_And_Name
         X.Closer (X.Handle, X.Name, Raise_On_Error => False);
      end if;
      if X.File /= null then
         Free (X.File);
      elsif X.Name /= null then
         System.Native_IO.Free (X.Name);
      end if;
   end Finally;

   procedure Set_Buffer_Index (
      File : not null Non_Controlled_File_Type;
      Buffer_Index : Stream_Element_Offset);
   procedure Set_Buffer_Index (
      File : not null Non_Controlled_File_Type;
      Buffer_Index : Stream_Element_Offset) is
   begin
      if File.Buffer_Length = Uninitialized_Buffer then
         File.Buffer_Index := Buffer_Index;
      elsif File.Buffer_Length = 0 then
         File.Buffer_Index := 0;
      else
         File.Buffer_Index := Buffer_Index
            rem Stream_Element_Positive_Count'(File.Buffer_Length);
      end if;
      File.Reading_Index := File.Buffer_Index;
      File.Writing_Index := File.Buffer_Index;
   end Set_Buffer_Index;

   procedure Set_Index_To_Append (File : not null Non_Controlled_File_Type);
   procedure Set_Index_To_Append (File : not null Non_Controlled_File_Type) is
      New_Index : Stream_Element_Offset;
   begin
      System.Native_IO.Set_Relative_Index (
         File.Handle,
         0,
         System.Native_IO.From_End,
         New_Index);
      Set_Buffer_Index (File, New_Index);
   end Set_Index_To_Append;

   procedure Allocate_And_Open (
      Method : System.Native_IO.Open_Method;
      File : out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode;
      Name : String;
      Form : System.Native_IO.Packed_Form);
   procedure Allocate_And_Open (
      Method : System.Native_IO.Open_Method;
      File : out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode;
      Name : String;
      Form : System.Native_IO.Packed_Form)
   is
      package Holder is
         new Exceptions.Finally.Scoped_Holder (
            Scoped_Handle_And_File_And_Name,
            Finally);
      Scoped : aliased Scoped_Handle_And_File_And_Name :=
         (System.Native_IO.Invalid_Handle, null, null, null);
      Kind : Stream_Kind;
   begin
      Holder.Assign (Scoped);
      if Name /= "" then
         Kind := Ordinary;
      else
         Kind := Temporary;
      end if;
      declare
         Full_Name_Length : System.Native_IO.Name_Length;
      begin
         if Kind = Ordinary then
            Scoped.Closer := System.Native_IO.Close_Ordinary'Access;
            System.Native_IO.New_Full_Name (
               Name,
               Scoped.Name,
               Full_Name_Length);
            System.Native_IO.Open_Ordinary (
               Method => Method,
               Handle => Scoped.Handle,
               Mode => Mode,
               Name => Scoped.Name,
               Form => Form);
         else
            Scoped.Closer := System.Native_IO.Close_Temporary'Access;
            System.Native_IO.Open_Temporary (
               Scoped.Handle,
               Scoped.Name,
               Full_Name_Length);
         end if;
         Scoped.File := Allocate (
            Handle => Scoped.Handle,
            Mode => Mode,
            Kind => Kind,
            Name => Scoped.Name,
            Name_Length => Full_Name_Length,
            Form => Form,
            Closer => Scoped.Closer);
      end;
      if Kind = Ordinary and then Mode = IO_Modes.Append_File then
         Set_Index_To_Append (Scoped.File); -- sets index to the last
      end if;
      File := Scoped.File;
      --  complete
      Holder.Clear;
   end Allocate_And_Open;

   procedure Get_Buffer (File : not null Non_Controlled_File_Type);
   procedure Get_Buffer (File : not null Non_Controlled_File_Type) is
   begin
      if File.Buffer_Length = Uninitialized_Buffer then
         File.Buffer_Length := System.Native_IO.Block_Size (File.Handle);
         if File.Buffer_Length = 0 then
            File.Buffer := File.Buffer_Inline'Address;
            File.Buffer_Index := 0;
         else
            File.Buffer := System.Standard_Allocators.Allocate (
               System.Storage_Elements.Storage_Offset (File.Buffer_Length));
            File.Buffer_Index := File.Buffer_Index
               rem Stream_Element_Positive_Count'(File.Buffer_Length);
         end if;
         File.Reading_Index := File.Buffer_Index;
         File.Writing_Index := File.Buffer_Index;
      end if;
   end Get_Buffer;

   procedure Ready_Reading_Buffer (
      File : not null Non_Controlled_File_Type;
      Error : out Boolean);
   procedure Ready_Reading_Buffer (
      File : not null Non_Controlled_File_Type;
      Error : out Boolean)
   is
      Buffer_Length : constant Stream_Element_Positive_Count :=
         Stream_Element_Offset'Max (1, File.Buffer_Length);
   begin
      --  reading buffer is from File.Reading_Index until File.Buffer_Index
      File.Buffer_Index := File.Buffer_Index rem Buffer_Length;
      File.Reading_Index := File.Buffer_Index;
      declare
         Read_Length : Stream_Element_Offset;
      begin
         System.Native_IO.Read (
            File.Handle,
            File.Buffer
               + System.Storage_Elements.Storage_Offset (File.Buffer_Index),
            Buffer_Length - File.Buffer_Index,
            Read_Length);
         Error := Read_Length < 0;
         if not Error then
            File.Buffer_Index := File.Buffer_Index + Read_Length;
         end if;
      end;
      File.Writing_Index := File.Buffer_Index;
   end Ready_Reading_Buffer;

   procedure Reset_Reading_Buffer (File : not null Non_Controlled_File_Type);
   procedure Reset_Reading_Buffer (File : not null Non_Controlled_File_Type) is
      New_Index : Stream_Element_Offset;
      pragma Unreferenced (New_Index);
   begin
      System.Native_IO.Set_Relative_Index (
         File.Handle,
         File.Reading_Index - File.Buffer_Index,
         System.Native_IO.From_Current,
         New_Index);
      File.Buffer_Index := File.Reading_Index;
      File.Writing_Index := File.Buffer_Index;
   end Reset_Reading_Buffer;

   procedure Ready_Writing_Buffer (File : not null Non_Controlled_File_Type);
   procedure Ready_Writing_Buffer (File : not null Non_Controlled_File_Type) is
   begin
      --  writing buffer is from File.Buffer_Index until File.Writing_Index
      File.Buffer_Index := File.Buffer_Index
         rem Stream_Element_Positive_Count'(File.Buffer_Length);
      File.Writing_Index := File.Buffer_Index;
      File.Reading_Index := File.Buffer_Index;
   end Ready_Writing_Buffer;

   procedure Flush_Writing_Buffer (
      File : not null Non_Controlled_File_Type;
      Raise_On_Error : Boolean := True);
   procedure Flush_Writing_Buffer (
      File : not null Non_Controlled_File_Type;
      Raise_On_Error : Boolean := True) is
   begin
      if File.Writing_Index > File.Buffer_Index then
         declare
            Error : Boolean := False;
            Written_Length : Stream_Element_Offset;
         begin
            System.Native_IO.Write (
               File.Handle,
               File.Buffer
                  + System.Storage_Elements.Storage_Offset (File.Buffer_Index),
               File.Writing_Index - File.Buffer_Index,
               Written_Length);
            if Written_Length < 0 then
               if Raise_On_Error then
                  Raise_Exception (Device_Error'Identity);
               end if;
               Error := True;
            end if;
            if not Error then
               File.Buffer_Index := File.Writing_Index
                  rem Stream_Element_Positive_Count'(File.Buffer_Length);
               File.Writing_Index := File.Buffer_Index;
               File.Reading_Index := File.Buffer_Index;
            end if;
         end;
      end if;
   end Flush_Writing_Buffer;

   function Offset_Of_Buffer (File : not null Non_Controlled_File_Type)
      return Stream_Element_Offset;
   function Offset_Of_Buffer (File : not null Non_Controlled_File_Type)
      return Stream_Element_Offset is
   begin
      return (File.Writing_Index - File.Buffer_Index)
         - (File.Buffer_Index - File.Reading_Index);
   end Offset_Of_Buffer;

   procedure Read_From_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset);
   procedure Read_From_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset)
   is
      Taking_Length : constant Stream_Element_Offset :=
         Stream_Element_Offset'Min (
            Item'Last - Item'First + 1,
            File.Buffer_Index - File.Reading_Index);
      Buffer : Stream_Element_Array (Stream_Element_Count);
      for Buffer'Address use File.Buffer;
   begin
      Last := Item'First + (Taking_Length - 1);
      Item (Item'First .. Last) :=
         Buffer (File.Reading_Index .. File.Reading_Index + Taking_Length - 1);
      File.Reading_Index := File.Reading_Index + Taking_Length;
   end Read_From_Buffer;

   procedure Write_To_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : Stream_Element_Array;
      Last : out Stream_Element_Offset);
   procedure Write_To_Buffer (
      File : not null Non_Controlled_File_Type;
      Item : Stream_Element_Array;
      Last : out Stream_Element_Offset)
   is
      Taking_Length : constant Stream_Element_Offset :=
         Stream_Element_Offset'Min (
            Item'Last - Item'First + 1,
            File.Buffer_Length - File.Writing_Index);
      Buffer : Stream_Element_Array (Stream_Element_Count);
      for Buffer'Address use File.Buffer;
   begin
      Last := Item'First + (Taking_Length - 1);
      Buffer (File.Writing_Index .. File.Writing_Index + Taking_Length - 1) :=
         Item (Item'First .. Last);
      File.Writing_Index := File.Writing_Index + Taking_Length;
   end Write_To_Buffer;

   function End_Of_Ordinary_File (File : not null Non_Controlled_File_Type)
      return Boolean;
   function End_Of_Ordinary_File (File : not null Non_Controlled_File_Type)
      return Boolean
   is
      Size : constant Stream_Element_Count :=
         System.Native_IO.Size (File.Handle);
      Index : constant Stream_Element_Offset :=
         System.Native_IO.Index (File.Handle) + Offset_Of_Buffer (File);
   begin
      return Index > Size;
      --  The writing buffer can be expanded over the file size.
   end End_Of_Ordinary_File;

   procedure Close_And_Deallocate (
      File : aliased in out Non_Controlled_File_Type;
      Raise_On_Error : Boolean);
   procedure Close_And_Deallocate (
      File : aliased in out Non_Controlled_File_Type;
      Raise_On_Error : Boolean)
   is
      use type System.Native_IO.Handle_Type;
      package Holder is
         new Exceptions.Finally.Scoped_Holder (
            Scoped_Handle_And_File_And_Name,
            Finally);
      Scoped : aliased Scoped_Handle_And_File_And_Name :=
         (System.Native_IO.Invalid_Handle, null, null, File.Closer);
      Freeing_File : constant Non_Controlled_File_Type := File;
      Kind : constant Stream_Kind := File.all.Kind;
   begin
      Holder.Assign (Scoped);
      case Kind is
         when Ordinary | Temporary | External | External_No_Close =>
            Scoped.File := Freeing_File;
         when Standard_Handle =>
            null; -- statically allocated
      end case;
      File := null;
      case Kind is
         when Ordinary | Temporary | External =>
            Scoped.Handle := Freeing_File.Handle;
            Scoped.Name := Freeing_File.Name;
         when External_No_Close | Standard_Handle =>
            null;
      end case;
      if Kind /= Temporary then
         Flush_Writing_Buffer (
            Freeing_File,
            Raise_On_Error => Raise_On_Error);
      end if;
      if Scoped.Handle /= System.Native_IO.Invalid_Handle then
         --  close explicitly in below
         Scoped.Handle := System.Native_IO.Invalid_Handle;
         Freeing_File.Closer (
            Freeing_File.Handle,
            Freeing_File.Name,
            Raise_On_Error => Raise_On_Error);
      end if;
   end Close_And_Deallocate;

   --  implementation of non-controlled

   procedure Create (
      File : in out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode := IO_Modes.Out_File;
      Name : String := "";
      Form : System.Native_IO.Packed_Form := Default_Form)
   is
      pragma Check (Pre,
         Check => not Is_Open (File) or else raise Status_Error);
   begin
      Allocate_And_Open (
         Method => System.Native_IO.Create,
         File => File,
         Mode => Mode,
         Name => Name,
         Form => Form);
   end Create;

   procedure Open (
      File : in out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode;
      Name : String;
      Form : System.Native_IO.Packed_Form := Default_Form)
   is
      pragma Check (Pre,
         Check => not Is_Open (File) or else raise Status_Error);
   begin
      Allocate_And_Open (
         Method => System.Native_IO.Open,
         File => File,
         Mode => Mode,
         Name => Name,
         Form => Form);
   end Open;

   procedure Close (
      File : aliased in out Non_Controlled_File_Type;
      Raise_On_Error : Boolean := True)
   is
      pragma Check (Pre,
         Check => Is_Open (File) or else raise Status_Error);
   begin
      Close_And_Deallocate (File, Raise_On_Error => Raise_On_Error);
   end Close;

   procedure Delete (File : aliased in out Non_Controlled_File_Type) is
      pragma Check (Pre,
         Check => Is_Open (File) or else raise Status_Error);
   begin
      case File.Kind is
         when Ordinary =>
            File.Closer := System.Native_IO.Delete_Ordinary'Access;
            Close_And_Deallocate (File, Raise_On_Error => True);
         when Temporary =>
            Close_And_Deallocate (File, Raise_On_Error => True);
         when External | External_No_Close | Standard_Handle =>
            pragma Check (Pre, Boolean'(raise Status_Error));
            unreachable;
      end case;
   end Delete;

   procedure Reset (
      File : aliased in out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode)
   is
      pragma Check (Pre,
         Check => Is_Open (File) or else raise Status_Error);
      package Holder is
         new Exceptions.Finally.Scoped_Holder (
            Scoped_Handle_And_File_And_Name,
            Finally);
      Scoped : aliased Scoped_Handle_And_File_And_Name :=
         (System.Native_IO.Invalid_Handle, null, null, File.Closer);
   begin
      Holder.Assign (Scoped);
      case File.all.Kind is
         when Ordinary =>
            Scoped.Handle := File.Handle;
            Scoped.File := File;
            Scoped.Name := File.Name;
            File := null;
            Flush_Writing_Buffer (Scoped.File);
            --  close explicitly in below
            Scoped.Handle := System.Native_IO.Invalid_Handle;
            System.Native_IO.Close_Ordinary (
               Scoped.File.Handle,
               Scoped.File.Name,
               Raise_On_Error => True);
            Scoped.File.Buffer_Index := 0;
            Scoped.File.Reading_Index := Scoped.File.Buffer_Index;
            Scoped.File.Writing_Index := Scoped.File.Buffer_Index;
            System.Native_IO.Open_Ordinary (
               Method => System.Native_IO.Reset,
               Handle => Scoped.Handle,
               Mode => Mode,
               Name => Scoped.File.Name,
               Form => Scoped.File.Form);
            Scoped.File.Handle := Scoped.Handle;
            Scoped.File.Mode := Mode;
            if Mode = IO_Modes.Append_File then
               Set_Index_To_Append (Scoped.File);
            end if;
         when Temporary =>
            Scoped.Handle := File.Handle;
            Scoped.File := File;
            Scoped.Name := File.Name;
            File := null;
            Scoped.File.Mode := Mode;
            if Mode = IO_Modes.Append_File then
               Flush_Writing_Buffer (Scoped.File);
               Set_Index_To_Append (Scoped.File);
            else
               Set_Index (Scoped.File, 1);
            end if;
         when External | External_No_Close | Standard_Handle =>
            pragma Check (Pre, Boolean'(raise Status_Error));
            unreachable;
      end case;
      File := Scoped.File;
      --  complete
      Holder.Clear;
   end Reset;

   function Mode (File : not null Non_Controlled_File_Type)
      return IO_Modes.File_Mode is
   begin
      return File.Mode;
   end Mode;

   function Name (File : not null Non_Controlled_File_Type) return String is
   begin
      return System.Native_IO.Value (
         File.Name,
         File.Name_Length);
   end Name;

   function Form (File : Non_Controlled_File_Type)
      return System.Native_IO.Packed_Form is
   begin
      return File.Form;
   end Form;

   function Is_Open (File : Non_Controlled_File_Type) return Boolean is
   begin
      return File /= null;
   end Is_Open;

   function End_Of_File (File : not null Non_Controlled_File_Type)
      return Boolean is
   begin
      Get_Buffer (File);
      if File.Buffer_Length = 0 then -- not ordinary file
         if File.Reading_Index = File.Buffer_Index then
            declare
               Error : Boolean;
            begin
               Ready_Reading_Buffer (File, Error);
               if Error then
                  Raise_Exception (Use_Error'Identity);
               end if;
            end;
         end if;
         return File.Reading_Index = File.Buffer_Index;
      else
         return End_Of_Ordinary_File (File);
      end if;
   end End_Of_File;

   function Stream (File : not null Non_Controlled_File_Type)
      return not null access Root_Stream_Type'Class is
   begin
      if File.Dispatcher.Tag = Tags.No_Tag then
         if not System.Native_IO.Is_Seekable (File.Handle) then
            File.Dispatcher.Tag := Dispatchers.Root_Dispatcher'Tag;
         else
            File.Dispatcher.Tag := Dispatchers.Seekable_Dispatcher'Tag;
         end if;
         File.Dispatcher.File := File;
      end if;
      return To_Pointer (File.Dispatcher'Address);
   end Stream;

   procedure Read (
      File : not null Non_Controlled_File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset)
   is
      Index : Stream_Element_Offset := Item'First;
   begin
      if File.Reading_Index < File.Buffer_Index then
         declare
            Temp_Last : Stream_Element_Offset;
         begin
            Read_From_Buffer (File, Item, Temp_Last);
            if Temp_Last = Item'Last then
               Last := Temp_Last;
               return;
            end if;
            Index := Temp_Last + 1;
         end;
      else
         if File.Writing_Index > File.Buffer_Index then
            Flush_Writing_Buffer (File);
         end if;
         if Index > Item'Last then
            Last := Index - 1;
            return;
         end if;
      end if;
      Get_Buffer (File);
      declare
         Error : Boolean := False;
         Buffer_Length : constant Stream_Element_Count := File.Buffer_Length;
      begin
         declare
            Taking_Length : Stream_Element_Count;
         begin
            Taking_Length := Item'Last - Index + 1;
            if Buffer_Length > 0 then
               declare
                  Misaligned : constant Stream_Element_Count :=
                     (Buffer_Length - File.Buffer_Index) rem Buffer_Length;
               begin
                  if Taking_Length < Misaligned then
                     Taking_Length := 0; -- to use reading buffer
                  else
                     Taking_Length := Taking_Length - Misaligned;
                     Taking_Length := Taking_Length
                        - Taking_Length rem Buffer_Length;
                     Taking_Length := Taking_Length + Misaligned;
                  end if;
               end;
            end if;
            if Taking_Length > 0 then
               declare
                  Read_Size : Stream_Element_Offset;
               begin
                  System.Native_IO.Read (
                     File.Handle,
                     Item (Index)'Address,
                     Taking_Length,
                     Read_Size);
                  Error := Read_Size < 0;
                  if not Error then
                     Index := Index + Read_Size;
                     --  update indexes
                     if Buffer_Length > 0 then
                        File.Buffer_Index :=
                           (File.Buffer_Index + Read_Size) rem Buffer_Length;
                     else
                        File.Buffer_Index := 0;
                     end if;
                     File.Reading_Index := File.Buffer_Index;
                     File.Writing_Index := File.Buffer_Index;
                  end if;
               end;
            end if;
         end;
         if not Error
            and then Index <= Item'Last
            and then File.Buffer_Length > 0
         then
            Ready_Reading_Buffer (File, Error); -- reading buffer is empty
            if not Error and then File.Reading_Index < File.Buffer_Index then
               declare
                  Temp_Last : Stream_Element_Offset;
               begin
                  Read_From_Buffer (
                     File,
                     Item (Index .. Item'Last),
                     Temp_Last);
                  Index := Temp_Last + 1;
               end;
            end if;
         end if;
         if Index <= Item'First then
            --  RM 13.13.1(8/2), Item'First - 1 is returned in Last for EOF.
            if Error then
               Raise_Exception (End_Error'Identity); -- ???
            elsif Index = Stream_Element_Offset'First then
               raise Constraint_Error; -- AARM 13.13.1(11/2)
            end if;
         end if;
      end;
      Last := Index - 1;
   end Read;

   procedure Write (
      File : not null Non_Controlled_File_Type;
      Item : Stream_Element_Array)
   is
      First : Stream_Element_Offset := Item'First;
   begin
      if File.Writing_Index > File.Buffer_Index then
         --  append to writing buffer
         declare
            Temp_Last : Stream_Element_Offset;
         begin
            Write_To_Buffer (File, Item, Temp_Last);
            if File.Writing_Index = File.Buffer_Length then
               Flush_Writing_Buffer (File);
            end if;
            if Temp_Last >= Item'Last then
               return;
            end if;
            First := Temp_Last + 1;
         end;
      else
         if File.Reading_Index < File.Buffer_Index then
            --  reset reading buffer
            Reset_Reading_Buffer (File);
         end if;
         if First > Item'Last then
            return;
         end if;
      end if;
      Get_Buffer (File);
      declare
         Buffer_Length : constant Stream_Element_Count := File.Buffer_Length;
      begin
         declare
            Taking_Length : Stream_Element_Count;
         begin
            Taking_Length := Item'Last - First + 1;
            if Buffer_Length > 0 then
               declare
                  Misaligned : constant Stream_Element_Count :=
                     (Buffer_Length - File.Buffer_Index) rem Buffer_Length;
               begin
                  if Taking_Length < Misaligned then
                     Taking_Length := 0; -- to use writing buffer
                  else
                     Taking_Length := Taking_Length - Misaligned;
                     Taking_Length := Taking_Length
                        - Taking_Length rem Buffer_Length;
                     Taking_Length := Taking_Length + Misaligned;
                  end if;
               end;
            end if;
            if Taking_Length > 0 then
               declare
                  Written_Length : Stream_Element_Offset;
               begin
                  System.Native_IO.Write (
                     File.Handle,
                     Item (First)'Address,
                     Taking_Length,
                     Written_Length);
                  if Written_Length < 0 then
                     Raise_Exception (Device_Error'Identity);
                  end if;
               end;
               First := First + Taking_Length;
               --  update indexes
               if Buffer_Length > 0 then
                  File.Buffer_Index :=
                     (File.Buffer_Index + Taking_Length) rem Buffer_Length;
                  File.Reading_Index := File.Buffer_Index;
                  File.Writing_Index := File.Buffer_Index;
               end if;
            end if;
         end;
         if First <= Item'Last and then Buffer_Length > 0 then
            Ready_Writing_Buffer (File);
            declare
               Temp_Last : Stream_Element_Offset;
            begin
               Write_To_Buffer (File, Item (First .. Item'Last), Temp_Last);
            end;
         end if;
      end;
   end Write;

   procedure Set_Index (
      File : not null Non_Controlled_File_Type;
      To : Stream_Element_Positive_Count)
   is
      New_Index : Stream_Element_Offset;
      pragma Unreferenced (New_Index);
      Z_Index : constant Stream_Element_Offset := To - 1; -- zero based
   begin
      Flush_Writing_Buffer (File);
      System.Native_IO.Set_Relative_Index (
         File.Handle,
         Z_Index,
         System.Native_IO.From_Begin,
         New_Index);
      Set_Buffer_Index (File, Z_Index);
   end Set_Index;

   function Index (File : not null Non_Controlled_File_Type)
      return Stream_Element_Positive_Count is
   begin
      return System.Native_IO.Index (File.Handle) + Offset_Of_Buffer (File);
   end Index;

   function Size (File : not null Non_Controlled_File_Type)
      return Stream_Element_Count is
   begin
      Flush_Writing_Buffer (File);
      return System.Native_IO.Size (File.Handle);
   end Size;

   procedure Set_Mode (
      File : aliased in out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode)
   is
      pragma Check (Pre,
         Check => Is_Open (File) or else raise Status_Error);
      package Holder is
         new Exceptions.Finally.Scoped_Holder (
            Scoped_Handle_And_File_And_Name,
            Finally);
      Scoped : aliased Scoped_Handle_And_File_And_Name :=
         (System.Native_IO.Invalid_Handle, null, null, File.Closer);
      Current : Stream_Element_Positive_Count;
   begin
      Holder.Assign (Scoped);
      case File.all.Kind is
         when Ordinary =>
            Scoped.Handle := File.Handle;
            Scoped.File := File;
            Scoped.Name := File.Name;
            File := null;
            Current := Index (Scoped.File);
            Flush_Writing_Buffer (Scoped.File);
            --  close explicitly in below
            Scoped.Handle := System.Native_IO.Invalid_Handle;
            System.Native_IO.Close_Ordinary (
               Scoped.File.Handle,
               Scoped.File.Name,
               Raise_On_Error => True);
            System.Native_IO.Open_Ordinary (
               Method => System.Native_IO.Reset,
               Handle => Scoped.Handle,
               Mode => Mode,
               Name => Scoped.File.Name,
               Form => Scoped.File.Form);
            Scoped.File.Handle := Scoped.Handle;
            Scoped.File.Mode := Mode;
         when Temporary =>
            Scoped.Handle := File.Handle;
            Scoped.File := File;
            Scoped.Name := File.Name;
            File := null;
            Current := Index (Scoped.File);
            Flush_Writing_Buffer (Scoped.File);
            Scoped.File.Mode := Mode;
         when External | External_No_Close | Standard_Handle =>
            pragma Check (Pre, Boolean'(raise Status_Error));
            unreachable;
      end case;
      if Mode = IO_Modes.Append_File then
         Set_Index_To_Append (Scoped.File);
      else
         Set_Index (Scoped.File, Current);
      end if;
      File := Scoped.File;
      --  complete
      Holder.Clear;
   end Set_Mode;

   procedure Flush (File : not null Non_Controlled_File_Type) is
   begin
      Flush_Writing_Buffer (File);
      System.Native_IO.Flush (File.Handle);
   end Flush;

   --  implementation of handle for non-controlled

   procedure Open (
      File : in out Non_Controlled_File_Type;
      Mode : IO_Modes.File_Mode;
      Handle : System.Native_IO.Handle_Type;
      Name : String := "";
      Form : System.Native_IO.Packed_Form := Default_Form;
      To_Close : Boolean := False)
   is
      pragma Check (Pre,
         Check => not Is_Open (File) or else raise Status_Error);
      package Name_Holder is
         new Exceptions.Finally.Scoped_Holder (
            System.Native_IO.Name_Pointer,
            System.Native_IO.Free);
      Kind : Stream_Kind;
      Closer : Close_Handler;
      Full_Name : aliased System.Native_IO.Name_Pointer;
      Full_Name_Length : System.Native_IO.Name_Length;
   begin
      if To_Close then
         Kind := External;
         Closer := System.Native_IO.Close_Ordinary'Access;
      else
         Kind := External_No_Close;
         Closer := null;
      end if;
      Name_Holder.Assign (Full_Name);
      System.Native_IO.New_External_Name (
         Name,
         Full_Name, -- '*' & Name & NUL
         Full_Name_Length);
      File := Allocate (
         Handle => Handle,
         Mode => Mode,
         Kind => Kind,
         Name => Full_Name,
         Name_Length => Full_Name_Length,
         Form => Form,
         Closer => Closer);
      --  complete
      Name_Holder.Clear;
   end Open;

   function Handle (File : not null Non_Controlled_File_Type)
      return System.Native_IO.Handle_Type is
   begin
      return File.Handle;
   end Handle;

   function Is_Standard (File : not null Non_Controlled_File_Type)
      return Boolean is
   begin
      return File.Kind = Standard_Handle;
   end Is_Standard;

   package body Dispatchers is

      overriding procedure Read (
         Stream : in out Root_Dispatcher;
         Item : out Stream_Element_Array;
         Last : out Stream_Element_Offset)
      is
         pragma Check (Pre,
            Check =>
               Mode (Stream.File) /= IO_Modes.Out_File
               or else raise Mode_Error);
      begin
         Read (Stream.File, Item, Last);
      end Read;

      overriding procedure Write (
         Stream : in out Root_Dispatcher;
         Item : Stream_Element_Array)
      is
         pragma Check (Pre,
            Check =>
               Mode (Stream.File) /= IO_Modes.In_File
               or else raise Mode_Error);
      begin
         Write (Stream.File, Item);
      end Write;

      overriding procedure Read (
         Stream : in out Seekable_Dispatcher;
         Item : out Stream_Element_Array;
         Last : out Stream_Element_Offset)
      is
         pragma Check (Pre,
            Check =>
               Mode (Stream.File) /= IO_Modes.Out_File
               or else raise Mode_Error);
      begin
         Read (Stream.File, Item, Last);
      end Read;

      overriding procedure Write (
         Stream : in out Seekable_Dispatcher;
         Item : Stream_Element_Array)
      is
         pragma Check (Pre,
            Check =>
               Mode (Stream.File) /= IO_Modes.In_File
               or else raise Mode_Error);
      begin
         Write (Stream.File, Item);
      end Write;

      overriding procedure Set_Index (
         Stream : in out Seekable_Dispatcher;
         To : Stream_Element_Positive_Count) is
      begin
         Set_Index (Stream.File, To);
      end Set_Index;

      overriding function Index (Stream : Seekable_Dispatcher)
         return Stream_Element_Positive_Count is
      begin
         return Index (Stream.File);
      end Index;

      overriding function Size (Stream : Seekable_Dispatcher)
         return Stream_Element_Count is
      begin
         return Size (Stream.File);
      end Size;

   end Dispatchers;

end Ada.Streams.Naked_Stream_IO;
