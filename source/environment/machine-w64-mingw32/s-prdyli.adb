with Ada.Exception_Identification.From_Here;
with Ada.Unchecked_Conversion;
with System.Zero_Terminated_WStrings;
with C.winbase;
with C.winnt;
package body System.Program.Dynamic_Linking is
   use Ada.Exception_Identification.From_Here;
   use type C.size_t;
   use type C.windef.FARPROC;
   use type C.windef.HMODULE;
   use type C.windef.WINBOOL;

   procedure Open (Handle : out C.windef.HMODULE; Name : String);
   procedure Open (Handle : out C.windef.HMODULE; Name : String) is
      W_Name : aliased C.winnt.WCHAR_array (
         0 ..
         Name'Length * Zero_Terminated_WStrings.Expanding);
      Result : C.windef.HMODULE;
   begin
      Zero_Terminated_WStrings.To_C (Name, W_Name (0)'Access);
      Result := C.winbase.LoadLibrary (W_Name (0)'Access);
      if Result = null then
         Raise_Exception (Name_Error'Identity);
      else
         Handle := Result;
      end if;
   end Open;

   procedure Close (Handle : C.windef.HMODULE; Raise_On_Error : Boolean);
   procedure Close (Handle : C.windef.HMODULE; Raise_On_Error : Boolean) is
      R : C.windef.WINBOOL;
   begin
      if Handle /= null then
         R := C.winbase.FreeLibrary (Handle);
         if R = 0 and then Raise_On_Error then
            Raise_Exception (Use_Error'Identity);
         end if;
      end if;
   end Close;

   --  implementation

   function Is_Open (Lib : Library) return Boolean is
   begin
      return Reference (Lib).all /= null;
   end Is_Open;

   procedure Open (Lib : in out Library; Name : String) is
      pragma Check (Pre,
         Check => not Is_Open (Lib) or else raise Status_Error);
      Handle : constant not null access C.windef.HMODULE := Reference (Lib);
   begin
      Open (Handle.all, Name);
   end Open;

   function Open (Name : String) return Library is
   begin
      return Result : Library do
         Open (Reference (Result).all, Name);
      end return;
   end Open;

   procedure Close (Lib : in out Library) is
      pragma Check (Pre,
         Check => Is_Open (Lib) or else raise Status_Error);
      Handle : constant not null access C.windef.HMODULE := Reference (Lib);
   begin
      Close (Handle.all, Raise_On_Error => True);
      Handle.all := null;
   end Close;

   function Import (
      Lib : Library;
      Symbol : String)
      return Address
   is
      pragma Check (Pre,
         Check => Is_Open (Lib) or else raise Status_Error);
      function Cast is
         new Ada.Unchecked_Conversion (C.windef.FARPROC, Address);
      Handle : constant C.windef.HMODULE := Reference (Lib).all;
      Z_Symbol : String := Symbol & Character'Val (0);
      C_Symbol : C.char_array (C.size_t);
      for C_Symbol'Address use Z_Symbol'Address;
      Result : C.windef.FARPROC;
   begin
      Result := C.winbase.GetProcAddress (Handle, C_Symbol (0)'Access);
      if Result = null then
         Raise_Exception (Data_Error'Identity);
      else
         return Cast (Result);
      end if;
   end Import;

   package body Controlled is

      function Reference (Lib : Library)
         return not null access C.windef.HMODULE is
      begin
         return Lib.Handle'Unrestricted_Access;
      end Reference;

      overriding procedure Finalize (Object : in out Library) is
      begin
         Close (Object.Handle, Raise_On_Error => False);
      end Finalize;

   end Controlled;

end System.Program.Dynamic_Linking;
