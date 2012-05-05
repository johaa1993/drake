pragma License (Unrestricted);
--  Ada 2005
with Ada.Iterator_Interfaces;
private with Ada.Containers.Inside.Copy_On_Write;
private with Ada.Containers.Inside.Hash_Tables;
private with Ada.Finalization;
private with Ada.Streams;
generic
   type Key_Type is private;
   type Element_Type is private;
   with function Hash (Key : Key_Type) return Hash_Type;
   with function Equivalent_Keys (Left, Right : Key_Type) return Boolean;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
package Ada.Containers.Hashed_Maps is
   pragma Preelaborate;
   pragma Remote_Types;

   type Map is tagged private
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
      new Ada.Iterator_Interfaces (Cursor, Has_Element);

   function "=" (Left, Right : Map) return Boolean;

   function Capacity (Container : Map) return Count_Type;

   procedure Reserve_Capacity (Container : in out Map; Capacity : Count_Type);

   function Length (Container : Map) return Count_Type;

   function Is_Empty (Container : Map) return Boolean;

   procedure Clear (Container : in out Map);

   function Key (Position : Cursor) return Key_Type;
--  diff
--  diff
--  diff

   function Element (Position : Cursor) return Element_Type;

   procedure Replace_Element (
      Container : in out Map;
      Position : Cursor;
      New_Item : Element_Type);

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

   function Constant_Reference (
      Container : aliased Map;
      Position : Cursor)
      return Constant_Reference_Type;

   function Reference (
      Container : aliased in out Map;
      Position : Cursor)
      return Reference_Type;

   function Constant_Reference (
      Container : aliased Map;
      Key : Key_Type)
      return Constant_Reference_Type;

   function Reference (
      Container : aliased in out Map;
      Key : Key_Type)
      return Reference_Type;

   procedure Assign (Target : in out Map; Source : Map);

   function Copy (Source : Map; Capacity : Count_Type := 0) return Map;

   procedure Move (Target : in out Map; Source : in out Map);

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type;
      Position : out Cursor;
      Inserted : out Boolean);

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      Position : out Cursor;
      Inserted : out Boolean);

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type);

   procedure Include (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type);

   procedure Replace (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type);

   procedure Exclude (Container : in out Map; Key : Key_Type);

   procedure Delete (Container : in out Map; Key : Key_Type);

   procedure Delete (Container : in out Map; Position : in out Cursor);

   function First (Container : Map) return Cursor;

   function Next (Position : Cursor) return Cursor;

   procedure Next (Position : in out Cursor);

   function Find (Container : Map; Key : Key_Type) return Cursor;

   --  modified
   function Element (
      Container : Map'Class; -- not primitive
      Key : Key_Type) return Element_Type;

   function Contains (Container : Map; Key : Key_Type) return Boolean;

   function Equivalent_Keys (Left, Right : Cursor) return Boolean;

   function Equivalent_Keys (Left : Cursor; Right : Key_Type) return Boolean;

--  function Equivalent_Keys (Left : Key_Type; Right : Cursor) return Boolean;

   --  modified
   procedure Iterate (
      Container : Map'Class; -- not primitive
      Process : not null access procedure (Position : Cursor));

   function Iterate (Container : Map)
      return Map_Iterator_Interfaces.Forward_Iterator'Class;

--  diff (Equivalent)
--
--
--
--

private

   package Hash_Tables renames Containers.Inside.Hash_Tables;
   package Copy_On_Write renames Containers.Inside.Copy_On_Write;

--  diff
--  diff

   type Node is limited record
      Super : aliased Hash_Tables.Node;
      Key : aliased Key_Type;
      Element : aliased Element_Type;
   end record;

   --  place Super at first whether Element_Type is controlled-type
   for Node use record
      Super at 0 range 0 .. Hash_Tables.Node_Size - 1;
   end record;

   type Data is limited record
      Super : aliased Copy_On_Write.Data;
      Table : Hash_Tables.Table_Access := null;
      Length : Count_Type := 0;
   end record;

   type Data_Access is access Data;

   type Map is new Finalization.Controlled with record
      Super : aliased Copy_On_Write.Container;
--  diff
   end record;

   overriding procedure Adjust (Object : in out Map);
   overriding procedure Finalize (Object : in out Map)
      renames Clear;

   package No_Primitives is
      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Map);
      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Map);
   end No_Primitives;

   for Map'Read use No_Primitives.Read;
   for Map'Write use No_Primitives.Write;

   type Cursor is access Node;

--  diff (Key_Reference_Type)
--  diff

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is null record;

   type Reference_Type (
      Element : not null access Element_Type) is null record;

   type Map_Access is access constant Map;
   for Map_Access'Storage_Size use 0;

   type Iterator is new Map_Iterator_Interfaces.Forward_Iterator with record
      Container : not null Map_Access;
   end record;

   overriding function First (Object : Iterator) return Cursor;
   overriding function Next (Object : Iterator; Position : Cursor)
      return Cursor;

   --  dummy 'Read and 'Write

   procedure Read (
      Stream : access Streams.Root_Stream_Type'Class;
      Item : out Cursor);
   procedure Write (
      Stream : access Streams.Root_Stream_Type'Class;
      Item : Cursor);

   for Cursor'Read use Read;
   for Cursor'Write use Write;

--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff

   procedure Read (
      Stream : access Streams.Root_Stream_Type'Class;
      Item : out Constant_Reference_Type);
   procedure Write (
      Stream : access Streams.Root_Stream_Type'Class;
      Item : Constant_Reference_Type);

   for Constant_Reference_Type'Read use Read;
   for Constant_Reference_Type'Write use Write;

   procedure Read (
      Stream : access Streams.Root_Stream_Type'Class;
      Item : out Reference_Type);
   procedure Write (
      Stream : access Streams.Root_Stream_Type'Class;
      Item : Reference_Type);

   for Reference_Type'Read use Read;
   for Reference_Type'Write use Write;

   pragma Import (Ada, Read, "__drake_program_error");
   pragma Import (Ada, Write, "__drake_program_error");

   No_Element : constant Cursor := null;

end Ada.Containers.Hashed_Maps;
