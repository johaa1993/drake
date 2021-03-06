pragma License (Unrestricted);
--  extended unit
with Ada.Iterator_Interfaces;
private with Ada.Containers.Binary_Trees;
private with Ada.Containers.Binary_Trees.Arne_Andersson;
--  diff (Copy_On_Write)
private with Ada.Finalization;
private with Ada.Streams;
generic
   type Key_Type (<>) is limited private;
   type Element_Type (<>) is limited private;
   with function "<" (Left, Right : Key_Type) return Boolean is <>;
--  diff ("=")
package Ada.Containers.Limited_Ordered_Maps is
   pragma Preelaborate;
   pragma Remote_Types;

   function Equivalent_Keys (Left, Right : Key_Type) return Boolean;

   type Map is tagged limited private
      with
         Constant_Indexing => Constant_Reference,
         Variable_Indexing => Reference,
         Default_Iterator => Iterate,
         Iterator_Element => Element_Type;
   pragma Preelaborable_Initialization (Map);

   type Cursor is private;
   pragma Preelaborable_Initialization (Cursor);

   --  modified
--  Empty_Map : constant Map;
   function Empty_Map return Map;

   No_Element : constant Cursor;

   function Has_Element (Position : Cursor) return Boolean;

   package Map_Iterator_Interfaces is
      new Iterator_Interfaces (Cursor, Has_Element);

--  diff ("=")

   function Length (Container : Map) return Count_Type;

   function Is_Empty (Container : Map) return Boolean;

   procedure Clear (Container : in out Map);

   type Key_Reference_Type (
      Element : not null access constant Key_Type) is private
      with Implicit_Dereference => Element;
   function Key (Position : Cursor) return Key_Reference_Type;

--  diff (Element)

--  diff (Replace_Element)
--
--
--

   procedure Query_Element (
      Position : Cursor;
      Process : not null access procedure (
         Key : Key_Type;
         Element : Element_Type));

   --  modified
   procedure Update_Element (
      Container : in out Map'Class; -- not primitive
      Position : Cursor;
      Process : not null access procedure (
         Key : Key_Type;
         Element : in out Element_Type));

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is private
      with Implicit_Dereference => Element;

   type Reference_Type (
      Element : not null access Element_Type) is private
      with Implicit_Dereference => Element;

   function Constant_Reference (Container : aliased Map; Position : Cursor)
      return Constant_Reference_Type;

   function Reference (Container : aliased in out Map; Position : Cursor)
      return Reference_Type;

   function Constant_Reference (Container : aliased Map; Key : Key_Type)
      return Constant_Reference_Type;

   function Reference (Container : aliased in out Map; Key : Key_Type)
      return Reference_Type;

--  diff (Assign)

--  diff (Copy)

   procedure Move (Target : in out Map; Source : in out Map);

   procedure Insert (
      Container : in out Map;
      New_Key : not null access function return Key_Type;
      New_Item : not null access function return Element_Type;
      Position : out Cursor;
      Inserted : out Boolean);

--  diff (Insert)
--
--
--
--

   procedure Insert (
      Container : in out Map;
      Key : not null access function return Key_Type;
      New_Item : not null access function return Element_Type);

--  diff (Include)
--
--
--

--  diff (Replace)
--
--
--

   procedure Exclude (Container : in out Map; Key : Key_Type);

   procedure Delete (Container : in out Map; Key : Key_Type);

   procedure Delete (Container : in out Map; Position : in out Cursor);

   --  modified
   procedure Delete_First (Container : in out Map'Class); -- not primitive

   --  modified
   procedure Delete_Last (Container : in out Map'Class); -- not primitive

   function First (Container : Map) return Cursor;

--  diff (First_Element)
--
--

--  diff (First_Key)
--
--

   function Last (Container : Map) return Cursor;

--  diff (Last_Element)
--
--

--  diff (Last_Key)
--
--

   function Next (Position : Cursor) return Cursor;

   procedure Next (Position : in out Cursor);

   function Previous (Position : Cursor) return Cursor;

   procedure Previous (Position : in out Cursor);

   function Find (Container : Map; Key : Key_Type) return Cursor;

--  diff (Element)
--
--
--
--

   function Floor (Container : Map; Key : Key_Type) return Cursor;

   function Ceiling (Container : Map; Key : Key_Type) return Cursor;

   function Contains (Container : Map; Key : Key_Type) return Boolean;

   function "<" (Left, Right : Cursor) return Boolean;

   function ">" (Left, Right : Cursor) return Boolean;

   function "<" (Left : Cursor; Right : Key_Type) return Boolean;

   function ">" (Left : Cursor; Right : Key_Type) return Boolean;

   function "<" (Left : Key_Type; Right : Cursor) return Boolean;

   function ">" (Left : Key_Type; Right : Cursor) return Boolean;

   --  modified
   procedure Iterate (
      Container : Map'Class; -- not primitive
      Process : not null access procedure (Position : Cursor));

   --  modified
   procedure Reverse_Iterate (
      Container : Map'Class; -- not primitive
      Process : not null access procedure (Position : Cursor));

   --  modified
   function Iterate (Container : Map'Class) -- not primitive
      return Map_Iterator_Interfaces.Reversible_Iterator'Class;

   --  extended
   function Iterate (Container : Map'Class; First, Last : Cursor)
      return Map_Iterator_Interfaces.Reversible_Iterator'Class;

   --  extended
   generic
      with function "=" (Left, Right : Element_Type) return Boolean is <>;
   package Equivalents is
      function "=" (Left, Right : Map) return Boolean;
   end Equivalents;

private

   package Base renames Binary_Trees.Arne_Andersson;

   type Key_Access is access Key_Type;
   type Element_Access is access Element_Type;

   type Node is limited record
      Super : aliased Base.Node;
      Key : Key_Access;
      Element : Element_Access;
   end record;

   --  place Super at first whether Element_Type is controlled-type
   for Node use record
      Super at 0 range 0 .. Base.Node_Size - 1;
   end record;

--  diff (Data)
--
--
--
--

--  diff (Data_Access)

   type Map is limited new Finalization.Limited_Controlled with record
      Root : Binary_Trees.Node_Access := null;
      Length : Count_Type := 0;
   end record;

--  diff
   overriding procedure Finalize (Object : in out Map)
      renames Clear;

   type Cursor is access Node;

   type Key_Reference_Type (
      Element : not null access constant Key_Type) is null record;

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is null record;

   type Reference_Type (
      Element : not null access Element_Type) is null record;

   type Map_Access is access constant Map;
   for Map_Access'Storage_Size use 0;

   type Map_Iterator is
      new Map_Iterator_Interfaces.Reversible_Iterator with
   record
      First : Cursor;
      Last : Cursor;
   end record;

   overriding function First (Object : Map_Iterator) return Cursor;
   overriding function Next (Object : Map_Iterator; Position : Cursor)
      return Cursor;
   overriding function Last (Object : Map_Iterator) return Cursor;
   overriding function Previous (Object : Map_Iterator; Position : Cursor)
      return Cursor;

   package Streaming is

--  diff (Read)
--
--
--  diff (Write)
--
--

      procedure Missing_Read (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : out Cursor)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";
      procedure Missing_Write (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : Cursor)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";

      procedure Missing_Read (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : out Key_Reference_Type)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";
      procedure Missing_Write (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : Key_Reference_Type)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";

      procedure Missing_Read (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : out Constant_Reference_Type)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";
      procedure Missing_Write (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : Constant_Reference_Type)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";

      procedure Missing_Read (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : out Reference_Type)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";
      procedure Missing_Write (
         Stream : access Streams.Root_Stream_Type'Class;
         Item : Reference_Type)
         with Import,
            Convention => Ada, External_Name => "__drake_program_error";

   end Streaming;

--  diff ('Read)
--  diff ('Write)

   for Cursor'Read use Streaming.Missing_Read;
   for Cursor'Write use Streaming.Missing_Write;

   for Key_Reference_Type'Read use Streaming.Missing_Read;
   for Key_Reference_Type'Write use Streaming.Missing_Write;

   for Constant_Reference_Type'Read use Streaming.Missing_Read;
   for Constant_Reference_Type'Write use Streaming.Missing_Write;

   for Reference_Type'Read use Streaming.Missing_Read;
   for Reference_Type'Write use Streaming.Missing_Write;

   No_Element : constant Cursor := null;

end Ada.Containers.Limited_Ordered_Maps;
