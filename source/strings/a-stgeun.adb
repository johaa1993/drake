with Ada.Unchecked_Conversion;
with System.Address_To_Named_Access_Conversions;
with System.Native_Allocators.Allocated_Size;
with System.Standard_Allocators;
with System.Storage_Elements;
package body Ada.Strings.Generic_Unbounded is
   use type Streams.Stream_Element_Offset;
   use type System.Address;
   use type System.Storage_Elements.Storage_Offset;

   package Data_Cast is
      new System.Address_To_Named_Access_Conversions (Data, Data_Access);

   subtype Not_Null_Data_Access is not null Data_Access;

   function Upcast is
      new Unchecked_Conversion (
         Not_Null_Data_Access,
         System.Reference_Counting.Container);
   function Downcast is
      new Unchecked_Conversion (
         System.Reference_Counting.Container,
         Not_Null_Data_Access);

   type Data_Access_Access is access all Not_Null_Data_Access;
   type Container_Access is access all System.Reference_Counting.Container;

   function Upcast is
      new Unchecked_Conversion (Data_Access_Access, Container_Access);

   function Allocation_Size (
      Capacity : System.Reference_Counting.Length_Type)
      return System.Storage_Elements.Storage_Count;
   function Allocation_Size (
      Capacity : System.Reference_Counting.Length_Type)
      return System.Storage_Elements.Storage_Count
   is
      Header_Size : constant System.Storage_Elements.Storage_Count :=
         Data'Size / Standard'Storage_Unit;
      Item_Size : System.Storage_Elements.Storage_Count;
   begin
      if String_Type'Component_Size rem Standard'Storage_Unit = 0 then
         --  optimized for packed
         Item_Size :=
            Capacity * (String_Type'Component_Size / Standard'Storage_Unit);
      else
         --  unpacked
         Item_Size :=
            (Capacity * String_Type'Component_Size
               + (Standard'Storage_Unit - 1))
            / Standard'Storage_Unit;
      end if;
      return Header_Size + Item_Size;
   end Allocation_Size;

   procedure Adjust_Allocated (Data : not null Data_Access);
   procedure Adjust_Allocated (Data : not null Data_Access) is
      pragma Suppress (Access_Check);
      pragma Suppress (Alignment_Check);
      package Fixed_String_Access_Conv is
         new System.Address_To_Named_Access_Conversions (
            Fixed_String,
            Fixed_String_Access);
      Header_Size : constant System.Storage_Elements.Storage_Count :=
         Generic_Unbounded.Data'Size / Standard'Storage_Unit;
      M : constant System.Address := Data_Cast.To_Address (Data);
      Usable_Size : constant
         System.Storage_Elements.Storage_Count :=
         System.Native_Allocators.Allocated_Size (M)
         - Header_Size;
   begin
      if String_Type'Component_Size
         rem Standard'Storage_Unit = 0
      then -- optimized for packed
         Data.Capacity := Integer (
            Usable_Size
            / (String_Type'Component_Size
               / Standard'Storage_Unit));
      else -- unpacked
         Data.Capacity := Integer (
            Usable_Size
            * Standard'Storage_Unit
            / String_Type'Component_Size);
      end if;
      Data.Items := Fixed_String_Access_Conv.To_Pointer (M + Header_Size);
   end Adjust_Allocated;

   function Allocate_Data (
      Max_Length : System.Reference_Counting.Length_Type;
      Capacity : System.Reference_Counting.Length_Type)
      return not null Data_Access;
   function Allocate_Data (
      Max_Length : System.Reference_Counting.Length_Type;
      Capacity : System.Reference_Counting.Length_Type)
      return not null Data_Access is
   begin
      if Capacity = 0 then
         return Empty_Data'Unrestricted_Access;
      else
         declare
            M : constant System.Address :=
               System.Standard_Allocators.Allocate (
                  Allocation_Size (Capacity));
         begin
            return Result : constant not null Data_Access :=
               Data_Cast.To_Pointer (M)
            do
               Result.Reference_Count := 1;
               Result.Max_Length := Max_Length;
               Adjust_Allocated (Result);
            end return;
         end;
      end if;
   end Allocate_Data;

   procedure Free_Data (Data : in out System.Reference_Counting.Data_Access);
   procedure Free_Data (Data : in out System.Reference_Counting.Data_Access) is
   begin
      System.Standard_Allocators.Free (Data_Cast.To_Address (Downcast (Data)));
      Data := null;
   end Free_Data;

   procedure Reallocate_Data (
      Data : aliased in out not null System.Reference_Counting.Data_Access;
      Length : System.Reference_Counting.Length_Type;
      Max_Length : System.Reference_Counting.Length_Type;
      Capacity : System.Reference_Counting.Length_Type);
   procedure Reallocate_Data (
      Data : aliased in out not null System.Reference_Counting.Data_Access;
      Length : System.Reference_Counting.Length_Type;
      Max_Length : System.Reference_Counting.Length_Type;
      Capacity : System.Reference_Counting.Length_Type)
   is
      pragma Unreferenced (Length);
      M : constant System.Address :=
         System.Standard_Allocators.Reallocate (
            Data_Cast.To_Address (Downcast (Data)),
            Allocation_Size (Capacity));
   begin
      Data := Upcast (Data_Cast.To_Pointer (M));
      Downcast (Data).Max_Length := Max_Length;
      Adjust_Allocated (Downcast (Data));
   end Reallocate_Data;

   procedure Copy_Data (
      Target : out not null System.Reference_Counting.Data_Access;
      Source : not null System.Reference_Counting.Data_Access;
      Length : System.Reference_Counting.Length_Type;
      Max_Length : System.Reference_Counting.Length_Type;
      Capacity : System.Reference_Counting.Length_Type);
   procedure Copy_Data (
      Target : out not null System.Reference_Counting.Data_Access;
      Source : not null System.Reference_Counting.Data_Access;
      Length : System.Reference_Counting.Length_Type;
      Max_Length : System.Reference_Counting.Length_Type;
      Capacity : System.Reference_Counting.Length_Type)
   is
      pragma Suppress (Access_Check);
      Data : constant not null Data_Access :=
         Allocate_Data (Max_Length, Capacity);
      subtype R is Integer range 1 .. Integer (Length);
   begin
      Data.Items (R) := Downcast (Source).Items (R);
      Target := Upcast (Data);
   end Copy_Data;

   procedure Unique (Item : in out Unbounded_String);
   procedure Unique (Item : in out Unbounded_String) is
   begin
      Reserve_Capacity (Item, Capacity (Item));
   end Unique;

   function Create (Data : not null Data_Access; Length : Natural)
      return Unbounded_String;
   function Create (Data : not null Data_Access; Length : Natural)
      return Unbounded_String is
   begin
      return (Finalization.Controlled with Data => Data, Length => Length);
   end Create;

   procedure Assign (
      Target : in out Unbounded_String;
      Source : Unbounded_String);
   procedure Assign (
      Target : in out Unbounded_String;
      Source : Unbounded_String) is
   begin
      System.Reference_Counting.Assign (
         Upcast (Target.Data'Unchecked_Access),
         Upcast (Source.Data'Unrestricted_Access),
         Free => Free_Data'Access);
      Target.Length := Source.Length;
   end Assign;

   --  implementation

   function Null_Unbounded_String return Unbounded_String is
   begin
      return Create (Data => Empty_Data'Unrestricted_Access, Length => 0);
   end Null_Unbounded_String;

   function Is_Null (Source : Unbounded_String) return Boolean is
   begin
      return Source.Length = 0;
   end Is_Null;

   function Length (Source : Unbounded_String) return Natural is
   begin
      return Source.Length;
   end Length;

   procedure Set_Length (Source : in out Unbounded_String; Length : Natural) is
   begin
      System.Reference_Counting.Set_Length (
         Target => Upcast (Source.Data'Unchecked_Access),
         Target_Length => System.Reference_Counting.Length_Type (
            Source.Length),
         Target_Max_Length => Source.Data.Max_Length,
         Target_Capacity => System.Reference_Counting.Length_Type (
            Capacity (Source)),
         New_Length => System.Reference_Counting.Length_Type (Length),
         Sentinel => Upcast (Empty_Data'Unrestricted_Access),
         Reallocate => Reallocate_Data'Access,
         Copy => Copy_Data'Access,
         Free => Free_Data'Access);
      Source.Length := Length;
   end Set_Length;

   function Capacity (Source : Unbounded_String'Class) return Natural is
   begin
      return Source.Data.Capacity;
   end Capacity;

   procedure Reserve_Capacity (
      Item : in out Unbounded_String;
      Capacity : Natural)
   is
      New_Capacity : constant Natural := Integer'Max (Capacity, Item.Length);
   begin
      System.Reference_Counting.Unique (
         Target => Upcast (Item.Data'Unchecked_Access),
         Target_Length => System.Reference_Counting.Length_Type (Item.Length),
         Target_Capacity => System.Reference_Counting.Length_Type (
            Generic_Unbounded.Capacity (Item)),
         Max_Length => System.Reference_Counting.Length_Type (Item.Length),
         Capacity => System.Reference_Counting.Length_Type (New_Capacity),
         Sentinel => Upcast (Empty_Data'Unrestricted_Access),
         Reallocate => Reallocate_Data'Access,
         Copy => Copy_Data'Access,
         Free => Free_Data'Access);
   end Reserve_Capacity;

   function To_Unbounded_String (Source : String_Type)
      return Unbounded_String
   is
      pragma Suppress (Access_Check);
      Length : constant Natural := Source'Length;
      New_Data : constant not null Data_Access :=
         Allocate_Data (
            System.Reference_Counting.Length_Type (Length),
            System.Reference_Counting.Length_Type (Length));
   begin
      New_Data.Items (1 .. Length) := Source;
      return Create (Data => New_Data, Length => Length);
   end To_Unbounded_String;

   function To_Unbounded_String (Length : Natural)
      return Unbounded_String
   is
      New_Data : constant not null Data_Access :=
         Allocate_Data (
            System.Reference_Counting.Length_Type (Length),
            System.Reference_Counting.Length_Type (Length));
   begin
      return Create (Data => New_Data, Length => Length);
   end To_Unbounded_String;

   function To_String (Source : Unbounded_String) return String_Type is
      pragma Suppress (Access_Check);
   begin
      return Source.Data.Items (1 .. Source.Length);
   end To_String;

   procedure Set_Unbounded_String (
      Target : out Unbounded_String;
      Source : String_Type)
   is
      pragma Suppress (Access_Check);
      Length : constant Natural := Source'Length;
   begin
      Target.Length := 0;
      Set_Length (Target, Length);
      Target.Data.Items (1 .. Length) := Source;
   end Set_Unbounded_String;

   procedure Append (
      Source : in out Unbounded_String;
      New_Item : Unbounded_String)
   is
      pragma Suppress (Access_Check);
   begin
      if Source.Length = 0 then
         Assign (Source, New_Item);
      elsif Source.Data = New_Item.Data then
         declare
            Last : constant Natural := Source.Length;
            Total_Length : constant Natural := Last * 2;
         begin
            Set_Length (Source, Total_Length);
            Source.Data.Items (Last + 1 .. Total_Length) :=
               Source.Data.Items (1 .. Last);
         end;
      else
         Append (Source, New_Item.Data.Items (1 .. New_Item.Length));
      end if;
   end Append;

   procedure Append (
      Source : in out Unbounded_String;
      New_Item : String_Type)
   is
      Last : constant Natural := Source.Length;
      Total_Length : constant Natural := Last + New_Item'Length;
   begin
      Set_Length (Source, Total_Length);
      Source.Data.Items (Last + 1 .. Total_Length) := New_Item;
   end Append;

   procedure Append (
      Source : in out Unbounded_String;
      New_Item : Character_Type)
   is
      Last : constant Natural := Source.Length;
      Total_Length : constant Natural := Last + 1;
   begin
      Set_Length (Source, Total_Length);
      Source.Data.Items (Total_Length) := New_Item;
   end Append;

   function "&" (Left, Right : Unbounded_String) return Unbounded_String is
   begin
      return Result : Unbounded_String := Left do
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left : Unbounded_String; Right : String_Type)
      return Unbounded_String is
   begin
      return Result : Unbounded_String := Left do
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left : String_Type; Right : Unbounded_String)
      return Unbounded_String is
   begin
      return Result : Unbounded_String do
         Reserve_Capacity (Result, Left'Length + Right.Length);
         Append (Result, Left);
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left : Unbounded_String; Right : Character_Type)
      return Unbounded_String is
   begin
      return Result : Unbounded_String := Left do
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left : Character_Type; Right : Unbounded_String)
      return Unbounded_String is
   begin
      return Result : Unbounded_String do
         Reserve_Capacity (Result, 1 + Right.Length);
         Append (Result, Left);
         Append (Result, Right);
      end return;
   end "&";

   function Element (Source : Unbounded_String; Index : Positive)
      return Character_Type is
   begin
      return Source.Data.Items (Index);
   end Element;

   procedure Replace_Element (
      Source : in out Unbounded_String;
      Index : Positive;
      By : Character_Type) is
   begin
      Unique (Source);
      Source.Data.Items (Index) := By;
   end Replace_Element;

   function Slice (
      Source : Unbounded_String;
      Low : Positive;
      High : Natural)
      return String_Type
   is
      pragma Suppress (Access_Check);
   begin
      return Source.Data.Items (Low .. High);
   end Slice;

   function Unbounded_Slice (
      Source : Unbounded_String;
      Low : Positive;
      High : Natural)
      return Unbounded_String is
   begin
      return Result : Unbounded_String do
         Unbounded_Slice (Source, Result, Low, High);
      end return;
   end Unbounded_Slice;

   procedure Unbounded_Slice (
      Source : Unbounded_String;
      Target : out Unbounded_String;
      Low : Positive;
      High : Natural)
   is
      pragma Suppress (Access_Check);
   begin
      if Low = 1 then
         Assign (Target, Source);
         Set_Length (Target, High);
      else
         Set_Unbounded_String (Target, Source.Data.Items (Low .. High));
      end if;
   end Unbounded_Slice;

   overriding function "=" (Left, Right : Unbounded_String) return Boolean is
      pragma Suppress (Access_Check);
   begin
      return Left.Data.Items (1 .. Left.Length) =
         Right.Data.Items (1 .. Right.Length);
   end "=";

   function "=" (Left : Unbounded_String; Right : String_Type)
      return Boolean
   is
      pragma Suppress (Access_Check);
   begin
      return Left.Data.Items (1 .. Left.Length) = Right;
   end "=";

   function "=" (Left : String_Type; Right : Unbounded_String)
      return Boolean
   is
      pragma Suppress (Access_Check);
   begin
      return Left = Right.Data.Items (1 .. Right.Length);
   end "=";

   function "<" (Left, Right : Unbounded_String) return Boolean is
      pragma Suppress (Access_Check);
   begin
      return Left.Data.Items (1 .. Left.Length) <
         Right.Data.Items (1 .. Right.Length);
   end "<";

   function "<" (Left : Unbounded_String; Right : String_Type)
      return Boolean
   is
      pragma Suppress (Access_Check);
   begin
      return Left.Data.Items (1 .. Left.Length) < Right;
   end "<";

   function "<" (Left : String_Type; Right : Unbounded_String)
      return Boolean
   is
      pragma Suppress (Access_Check);
   begin
      return Left < Right.Data.Items (1 .. Right.Length);
   end "<";

   function "<=" (Left, Right : Unbounded_String) return Boolean is
   begin
      return not (Right < Left);
   end "<=";

   function "<=" (Left : Unbounded_String; Right : String_Type)
      return Boolean is
   begin
      return not (Right < Left);
   end "<=";

   function "<=" (Left : String_Type; Right : Unbounded_String)
      return Boolean is
   begin
      return not (Right < Left);
   end "<=";

   function ">" (Left, Right : Unbounded_String) return Boolean is
   begin
      return Right < Left;
   end ">";

   function ">" (Left : Unbounded_String; Right : String_Type)
      return Boolean is
   begin
      return Right < Left;
   end ">";

   function ">" (Left : String_Type; Right : Unbounded_String)
      return Boolean is
   begin
      return Right < Left;
   end ">";

   function ">=" (Left, Right : Unbounded_String) return Boolean is
   begin
      return not (Left < Right);
   end ">=";

   function ">=" (Left : Unbounded_String; Right : String_Type)
      return Boolean is
   begin
      return not (Left < Right);
   end ">=";

   function ">=" (Left : String_Type; Right : Unbounded_String)
      return Boolean is
   begin
      return not (Left < Right);
   end ">=";

   function Constant_Reference (
      Source : aliased Unbounded_String)
      return Slicing.Constant_Reference_Type is
   begin
      return Constant_Reference (Source, 1, Source.Length);
   end Constant_Reference;

   function Constant_Reference (
      Source : aliased Unbounded_String;
      First_Index : Positive;
      Last_Index : Natural)
      return Slicing.Constant_Reference_Type
   is
      pragma Suppress (Access_Check);
   begin
      return Slicing.Constant_Slice (
         String_Access'(Source.Data.Items.all'Unrestricted_Access).all,
         First_Index,
         Last_Index);
   end Constant_Reference;

   function Reference (
      Source : aliased in out Unbounded_String)
      return Slicing.Reference_Type is
   begin
      return Reference (Source, 1, Source.Length);
   end Reference;

   function Reference (
      Source : aliased in out Unbounded_String;
      First_Index : Positive;
      Last_Index : Natural)
      return Slicing.Reference_Type
   is
      pragma Suppress (Access_Check);
   begin
      Unique (Source);
      return Slicing.Slice (
         String_Access'(Source.Data.Items.all'Unrestricted_Access).all,
         First_Index,
         Last_Index);
   end Reference;

   overriding procedure Adjust (Object : in out Unbounded_String) is
   begin
      System.Reference_Counting.Adjust (Upcast (Object.Data'Unchecked_Access));
   end Adjust;

   overriding procedure Finalize (Object : in out Unbounded_String) is
   begin
      System.Reference_Counting.Clear (
         Upcast (Object.Data'Unchecked_Access),
         Free => Free_Data'Access);
      Object.Data := Empty_Data'Unrestricted_Access;
      Object.Length := 0;
   end Finalize;

   package body Generic_Functions is

      function Index (
         Source : Unbounded_String;
         Pattern : String_Type;
         From : Positive;
         Going : Direction := Forward)
         return Natural
      is
         pragma Suppress (Access_Check);
      begin
         return Fixed_Index_From (
            Source.Data.Items (1 .. Source.Length),
            Pattern,
            From,
            Going);
      end Index;

      function Index (
         Source : Unbounded_String;
         Pattern : String_Type;
         Going : Direction := Forward)
         return Natural
      is
         pragma Suppress (Access_Check);
      begin
         return Fixed_Index (
            Source.Data.Items (1 .. Source.Length),
            Pattern,
            Going);
      end Index;

      function Index_Non_Blank (
         Source : Unbounded_String;
         From : Positive;
         Going : Direction := Forward)
         return Natural
      is
         pragma Suppress (Access_Check);
      begin
         return Fixed_Index_Non_Blank_From (
            Source.Data.Items (1 .. Source.Length),
            From,
            Going);
      end Index_Non_Blank;

      function Index_Non_Blank (
         Source : Unbounded_String;
         Going : Direction := Forward)
         return Natural
      is
         pragma Suppress (Access_Check);
      begin
         return Fixed_Index_Non_Blank (
            Source.Data.Items (1 .. Source.Length),
            Going);
      end Index_Non_Blank;

      function Count (
         Source : Unbounded_String;
         Pattern : String_Type)
         return Natural
      is
         pragma Suppress (Access_Check);
      begin
         return Fixed_Count (
            Source.Data.Items (1 .. Source.Length),
            Pattern);
      end Count;

      function Replace_Slice (
         Source : Unbounded_String;
         Low : Positive;
         High : Natural;
         By : String_Type)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return To_Unbounded_String (
            Fixed_Replace_Slice (
               Source.Data.Items (1 .. Source.Length),
               Low,
               High,
               By));
      end Replace_Slice;

      procedure Replace_Slice (
         Source : in out Unbounded_String;
         Low : Positive;
         High : Natural;
         By : String_Type)
      is
         pragma Suppress (Access_Check);
      begin
         Set_Unbounded_String (
            Source,
            Fixed_Replace_Slice (
               Source.Data.Items (1 .. Source.Length),
               Low,
               High,
               By));
      end Replace_Slice;

      function Insert (
         Source : Unbounded_String;
         Before : Positive;
         New_Item : String_Type)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return To_Unbounded_String (
            Fixed_Insert (
               Source.Data.Items (1 .. Source.Length),
               Before,
               New_Item));
      end Insert;

      procedure Insert (
         Source : in out Unbounded_String;
         Before : Positive;
         New_Item : String_Type)
      is
         pragma Suppress (Access_Check);
      begin
         Set_Unbounded_String (
            Source,
            Fixed_Insert (
               Source.Data.Items (1 .. Source.Length),
               Before,
               New_Item));
      end Insert;

      function Overwrite (
         Source : Unbounded_String;
         Position : Positive;
         New_Item : String_Type)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return To_Unbounded_String (
            Fixed_Overwrite (
               Source.Data.Items (1 .. Source.Length),
               Position,
               New_Item));
      end Overwrite;

      procedure Overwrite (
         Source : in out Unbounded_String;
         Position : Positive;
         New_Item : String_Type)
      is
         pragma Suppress (Access_Check);
      begin
         Set_Unbounded_String (
            Source,
            Fixed_Overwrite (
               Source.Data.Items (1 .. Source.Length),
               Position,
               New_Item));
      end Overwrite;

      function Delete (
         Source : Unbounded_String;
         From : Positive;
         Through : Natural)
         return Unbounded_String is
      begin
         return Result : Unbounded_String := Source do
            Delete (Result, From, Through);
         end return;
      end Delete;

      procedure Delete (
         Source : in out Unbounded_String;
         From : Positive;
         Through : Natural)
      is
         pragma Suppress (Access_Check);
      begin
         if From <= Through then
            declare
               Old_Length : constant Natural := Source.Length;
               New_Length : Natural;
            begin
               if Through >= Old_Length then
                  New_Length := From - 1;
               else
                  New_Length := Old_Length;
                  Unique (Source); -- for overwriting
                  Fixed_Delete (
                     Source.Data.Items (1 .. Old_Length),
                     New_Length,
                     From,
                     Through);
               end if;
               Set_Length (Source, New_Length);
            end;
         end if;
      end Delete;

      function Trim (
         Source : Unbounded_String;
         Side : Trim_End;
         Blank : Character_Type := Space)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
         First : Positive;
         Last : Natural;
      begin
         Fixed_Trim (
            Source.Data.Items (1 .. Source.Length),
            Side,
            Blank,
            First,
            Last);
         return Unbounded_Slice (Source, First, Last);
      end Trim;

      procedure Trim (
         Source : in out Unbounded_String;
         Side : Trim_End;
         Blank : Character_Type := Space)
      is
         pragma Suppress (Access_Check);
         First : Positive;
         Last : Natural;
      begin
         Fixed_Trim (
            Source.Data.Items (1 .. Source.Length),
            Side,
            Blank,
            First,
            Last);
         Unbounded_Slice (Source, Source, First, Last);
      end Trim;

      function Head (
         Source : Unbounded_String;
         Count : Natural;
         Pad : Character_Type := Space)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return To_Unbounded_String (
            Fixed_Head (
               Source.Data.Items (1 .. Source.Length),
               Count,
               Pad));
      end Head;

      procedure Head (
         Source : in out Unbounded_String;
         Count : Natural;
         Pad : Character_Type := Space)
      is
         pragma Suppress (Access_Check);
      begin
         Set_Unbounded_String (
            Source,
            Fixed_Head (
               Source.Data.Items (1 .. Source.Length),
               Count,
               Pad));
      end Head;

      function Tail (
         Source : Unbounded_String;
         Count : Natural;
         Pad : Character_Type := Space)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return To_Unbounded_String (
            Fixed_Tail (
               Source.Data.Items (1 .. Source.Length),
               Count,
               Pad));
      end Tail;

      procedure Tail (
         Source : in out Unbounded_String;
         Count : Natural;
         Pad : Character_Type := Space)
      is
         pragma Suppress (Access_Check);
      begin
         Set_Unbounded_String (
            Source,
            Fixed_Tail (
               Source.Data.Items (1 .. Source.Length),
               Count,
               Pad));
      end Tail;

      function "*" (Left : Natural; Right : Character_Type)
         return Unbounded_String is
      begin
         return Result : constant Unbounded_String :=
            To_Unbounded_String (Left)
         do
            for I in 1 .. Left loop
               Result.Data.Items (I) := Right;
            end loop;
         end return;
      end "*";

      function "*" (Left : Natural; Right : String_Type)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return Result : constant Unbounded_String :=
            To_Unbounded_String (Left * Right'Length)
         do
            declare
               First : Positive := 1;
            begin
               for I in 1 .. Left loop
                  Result.Data.Items (First .. First + Right'Length - 1) :=
                     Right;
                  First := First + Right'Length;
               end loop;
            end;
         end return;
      end "*";

      function "*" (Left : Natural; Right : Unbounded_String)
         return Unbounded_String
      is
         pragma Suppress (Access_Check);
      begin
         return Left * Right.Data.Items (1 .. Right.Length);
      end "*";

      package body Generic_Maps is

         function Index (
            Source : Unbounded_String;
            Pattern : String_Type;
            From : Positive;
            Going : Direction := Forward;
            Mapping : Character_Mapping)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Mapping_From (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               From,
               Going,
               Mapping);
         end Index;

         function Index (
            Source : Unbounded_String;
            Pattern : String_Type;
            Going : Direction := Forward;
            Mapping : Character_Mapping)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Mapping (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               Going,
               Mapping);
         end Index;

         function Index (
            Source : Unbounded_String;
            Pattern : String_Type;
            From : Positive;
            Going : Direction := Forward;
            Mapping : not null access function (From : Wide_Wide_Character)
               return Wide_Wide_Character)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Mapping_Function_From (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               From,
               Going,
               Mapping);
         end Index;

         function Index (
            Source : Unbounded_String;
            Pattern : String_Type;
            Going : Direction := Forward;
            Mapping : not null access function (From : Wide_Wide_Character)
               return Wide_Wide_Character)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Mapping_Function (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               Going,
               Mapping);
         end Index;

         function Index_Per_Element (
            Source : Unbounded_String;
            Pattern : String_Type;
            From : Positive;
            Going : Direction := Forward;
            Mapping : not null access function (From : Character_Type)
               return Character_Type)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Mapping_Function_Per_Element_From (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               From,
               Going,
               Mapping);
         end Index_Per_Element;

         function Index_Per_Element (
            Source : Unbounded_String;
            Pattern : String_Type;
            Going : Direction := Forward;
            Mapping : not null access function (From : Character_Type)
               return Character_Type)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Mapping_Function_Per_Element (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               Going,
               Mapping);
         end Index_Per_Element;

         function Index (
            Source : Unbounded_String;
            Set : Character_Set;
            From : Positive;
            Test : Membership := Inside;
            Going : Direction := Forward)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Set_From (
               Source.Data.Items (1 .. Source.Length),
               Set,
               From,
               Test,
               Going);
         end Index;

         function Index (
            Source : Unbounded_String;
            Set : Character_Set;
            Test : Membership := Inside;
            Going : Direction := Forward)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Index_Set (
               Source.Data.Items (1 .. Source.Length),
               Set,
               Test,
               Going);
         end Index;

         function Count (
            Source : Unbounded_String;
            Pattern : String_Type;
            Mapping : Character_Mapping)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Count_Mapping (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               Mapping);
         end Count;

         function Count (
            Source : Unbounded_String;
            Pattern : String_Type;
            Mapping : not null access function (From : Wide_Wide_Character)
               return Wide_Wide_Character)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Count_Mapping_Function (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               Mapping);
         end Count;

         function Count_Per_Element (
            Source : Unbounded_String;
            Pattern : String_Type;
            Mapping : not null access function (From : Character_Type)
               return Character_Type)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Count_Mapping_Function_Per_Element (
               Source.Data.Items (1 .. Source.Length),
               Pattern,
               Mapping);
         end Count_Per_Element;

         function Count (Source : Unbounded_String; Set : Character_Set)
            return Natural
         is
            pragma Suppress (Access_Check);
         begin
            return Fixed_Count_Set (
               Source.Data.Items (1 .. Source.Length),
               Set);
         end Count;

         procedure Find_Token (
            Source : Unbounded_String;
            Set : Character_Set;
            From : Positive;
            Test : Membership;
            First : out Positive;
            Last : out Natural)
         is
            pragma Suppress (Access_Check);
         begin
            Fixed_Find_Token_From (
               Source.Data.Items (1 .. Source.Length),
               Set,
               From,
               Test,
               First,
               Last);
         end Find_Token;

         procedure Find_Token (
            Source : Unbounded_String;
            Set : Character_Set;
            Test : Membership;
            First : out Positive;
            Last : out Natural)
         is
            pragma Suppress (Access_Check);
         begin
            Fixed_Find_Token (
               Source.Data.Items (1 .. Source.Length),
               Set,
               Test,
               First,
               Last);
         end Find_Token;

         function Translate (
            Source : Unbounded_String;
            Mapping : Character_Mapping)
            return Unbounded_String
         is
            pragma Suppress (Access_Check);
         begin
            return To_Unbounded_String (
               Fixed_Translate_Mapping (
                  Source.Data.Items (1 .. Source.Length),
                  Mapping));
         end Translate;

         procedure Translate (
            Source : in out Unbounded_String;
            Mapping : Character_Mapping)
         is
            pragma Suppress (Access_Check);
         begin
            Set_Unbounded_String (
               Source,
               Fixed_Translate_Mapping (
                  Source.Data.Items (1 .. Source.Length),
                  Mapping));
         end Translate;

         function Translate (
            Source : Unbounded_String;
            Mapping : not null access function (From : Wide_Wide_Character)
               return Wide_Wide_Character)
            return Unbounded_String
         is
            pragma Suppress (Access_Check);
         begin
            return To_Unbounded_String (
               Fixed_Translate_Mapping_Function (
                  Source.Data.Items (1 .. Source.Length),
                  Mapping));
         end Translate;

         procedure Translate (
            Source : in out Unbounded_String;
            Mapping : not null access function (From : Wide_Wide_Character)
               return Wide_Wide_Character)
         is
            pragma Suppress (Access_Check);
         begin
            Set_Unbounded_String (
               Source,
               Fixed_Translate_Mapping_Function (
                  Source.Data.Items (1 .. Source.Length),
                  Mapping));
         end Translate;

         function Translate_Per_Element (
            Source : Unbounded_String;
            Mapping : not null access function (From : Character_Type)
               return Character_Type)
            return Unbounded_String
         is
            pragma Suppress (Access_Check);
         begin
            return To_Unbounded_String (
               Fixed_Translate_Mapping_Function_Per_Element (
                  Source.Data.Items (1 .. Source.Length),
                  Mapping));
         end Translate_Per_Element;

         procedure Translate_Per_Element (
            Source : in out Unbounded_String;
            Mapping : not null access function (From : Character_Type)
               return Character_Type)
         is
            pragma Suppress (Access_Check);
         begin
            Set_Unbounded_String (
               Source,
               Fixed_Translate_Mapping_Function_Per_Element (
                  Source.Data.Items (1 .. Source.Length),
                  Mapping));
         end Translate_Per_Element;

         function Trim (
            Source : Unbounded_String;
            Left : Character_Set;
            Right : Character_Set)
            return Unbounded_String
         is
            pragma Suppress (Access_Check);
            First : Positive;
            Last : Natural;
         begin
            Fixed_Trim_Set (
               Source.Data.Items (1 .. Source.Length),
               Left,
               Right,
               First,
               Last);
            return Unbounded_Slice (Source, First, Last);
         end Trim;

         procedure Trim (
            Source : in out Unbounded_String;
            Left : Character_Set;
            Right : Character_Set)
         is
            pragma Suppress (Access_Check);
            First : Positive;
            Last : Natural;
         begin
            Fixed_Trim_Set (
               Source.Data.Items (1 .. Source.Length),
               Left,
               Right,
               First,
               Last);
            Unbounded_Slice (Source, Source, First, Last);
         end Trim;

      end Generic_Maps;

   end Generic_Functions;

   package body Generic_Constant is

      S_Data : aliased constant Data := (
         Reference_Count => System.Reference_Counting.Static,
         Capacity => Integer'Last,
         Max_Length => System.Reference_Counting.Length_Type (Integer'Last),
         Items => S.all'Unrestricted_Access);

      function Value return Unbounded_String is
      begin
         return Create (
            Data => S_Data'Unrestricted_Access,
            Length => S'Length);
      end Value;

   end Generic_Constant;

   package body Streaming is

      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Item : out Unbounded_String)
      is
         pragma Suppress (Access_Check);
         First : Integer;
         Last : Integer;
      begin
         Integer'Read (Stream, First);
         Integer'Read (Stream, Last);
         declare
            Length : constant Integer := Last - First + 1;
         begin
            Item.Length := 0;
            Set_Length (Item, Length);
            Read (Stream, Item.Data.Items (1 .. Length));
         end;
      end Read;

      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Item : Unbounded_String)
      is
         pragma Suppress (Access_Check);
      begin
         Integer'Write (Stream, 1);
         Integer'Write (Stream, Item.Length);
         Write (Stream, Item.Data.Items (1 .. Item.Length));
      end Write;

   end Streaming;

end Ada.Strings.Generic_Unbounded;
