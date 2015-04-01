with Ada.Exception_Identification.From_Here;
with Ada.Streams.Naked_Stream_IO;
with Ada.Streams.Stream_IO.Naked;
with System.Native_IO;
with System.Zero_Terminated_WStrings;
with C.windef;
with C.winerror;
package body Ada.Processes is
   use Exception_Identification.From_Here;
   use type Command_Line.Exit_Status;
   use type C.size_t;
   use type C.windef.DWORD;
   use type C.windef.WINBOOL;
   use type C.winnt.HANDLE; -- C.void_ptr

   --  implementation

   procedure Create (
      Child : in out Process;
      Command_Line : String;
      Directory : String := "";
      Search_Path : Boolean := False;
      Input : Streams.Stream_IO.File_Type :=
         Streams.Stream_IO.Standard_Files.Standard_Input.all;
      Output : Streams.Stream_IO.File_Type :=
         Streams.Stream_IO.Standard_Files.Standard_Output.all;
      Error : Streams.Stream_IO.File_Type :=
         Streams.Stream_IO.Standard_Files.Standard_Error.all)
   is
      pragma Unreferenced (Search_Path);
      W_Command_Line : aliased C.winnt.WCHAR_array (
         0 ..
         Command_Line'Length * System.Zero_Terminated_WStrings.Expanding);
      W_Directory : aliased C.winnt.WCHAR_array (0 .. Directory'Length);
      Directory_Ref : access constant C.winnt.WCHAR;
      Startup_Info : aliased C.winbase.STARTUPINFO;
      Process_Info : aliased C.winbase.PROCESS_INFORMATION;
      Current_Process : constant C.winnt.HANDLE := C.winbase.GetCurrentProcess;
      subtype Handle_Index is Integer range 0 .. 2;
      Source_Files : array (Handle_Index) of
         access Streams.Naked_Stream_IO.Non_Controlled_File_Type;
      Target_Handles : array (Handle_Index) of C.winnt.HANDLE;
      Duplicated_Handles : array (Handle_Index) of aliased C.winnt.HANDLE;
      Result : C.windef.WINBOOL;
   begin
      C.winbase.GetStartupInfo (Startup_Info'Access);
      Startup_Info.dwFlags := C.winbase.STARTF_USESTDHANDLES
         or C.winbase.STARTF_FORCEOFFFEEDBACK;
      Source_Files (0) := Streams.Stream_IO.Naked.Non_Controlled (Input);
      Source_Files (1) := Streams.Stream_IO.Naked.Non_Controlled (Output);
      Source_Files (2) := Streams.Stream_IO.Naked.Non_Controlled (Error);
      for I in Handle_Index loop
         declare
            Source_Handle : constant C.winnt.HANDLE :=
               Streams.Naked_Stream_IO.Handle (Source_Files (I).all);
         begin
            if Streams.Naked_Stream_IO.Is_Standard (Source_Files (I).all) then
               Duplicated_Handles (I) := C.winbase.INVALID_HANDLE_VALUE;
               Target_Handles (I) := Source_Handle;
            else
               if C.winbase.DuplicateHandle (
                  hSourceProcessHandle => Current_Process,
                  hSourceHandle => Source_Handle,
                  hTargetProcessHandle => Current_Process,
                  lpTargetHandle => Duplicated_Handles (I)'Access,
                  dwDesiredAccess => 0,
                  bInheritHandle => 1,
                  dwOptions => C.winnt.DUPLICATE_SAME_ACCESS) = 0
               then
                  Raise_Exception (Use_Error'Identity);
               end if;
               Target_Handles (I) := Duplicated_Handles (I);
            end if;
         end;
      end loop;
      Startup_Info.hStdInput := Target_Handles (0);
      Startup_Info.hStdOutput := Target_Handles (1);
      Startup_Info.hStdError := Target_Handles (2);
      System.Zero_Terminated_WStrings.To_C (
         Command_Line,
         W_Command_Line (0)'Access);
      if Directory'Length > 0 then
         System.Zero_Terminated_WStrings.To_C (
            Directory,
            W_Directory (0)'Access);
         Directory_Ref := W_Directory (0)'Access;
      else
         Directory_Ref := null;
      end if;
      Result := C.winbase.CreateProcess (
         lpApplicationName => null,
         lpCommandLine => W_Command_Line (0)'Access,
         lpProcessAttributes => null,
         lpThreadAttributes => null,
         bInheritHandles => 1,
         dwCreationFlags => 0,
         lpEnvironment => C.windef.LPVOID (System.Null_Address),
         lpCurrentDirectory => Directory_Ref,
         lpStartupInfo => Startup_Info'Access,
         lpProcessInformation => Process_Info'Access);
      for I in Handle_Index loop
         if Duplicated_Handles (I) /= C.winbase.INVALID_HANDLE_VALUE then
            if C.winbase.CloseHandle (Duplicated_Handles (I)) = 0 then
               Raise_Exception (Use_Error'Identity);
            end if;
         end if;
      end loop;
      if Result = 0 then
         declare
            Error : constant C.windef.DWORD := C.winbase.GetLastError;
         begin
            case Error is
               when C.winerror.ERROR_FILE_NOT_FOUND
                  | C.winerror.ERROR_PATH_NOT_FOUND
                  | C.winerror.ERROR_INVALID_NAME =>
                  Raise_Exception (Name_Error'Identity);
               when others =>
                  Raise_Exception (System.Native_IO.IO_Exception_Id (Error));
            end case;
         end;
      else
         if C.winbase.CloseHandle (Process_Info.hThread) = 0 then
            Raise_Exception (Use_Error'Identity);
         end if;
         Reference (Child).all := Process_Info.hProcess;
      end if;
   end Create;

   function Create (
      Command_Line : String;
      Directory : String := "";
      Search_Path : Boolean := False;
      Input : Streams.Stream_IO.File_Type :=
         Streams.Stream_IO.Standard_Files.Standard_Input.all;
      Output : Streams.Stream_IO.File_Type :=
         Streams.Stream_IO.Standard_Files.Standard_Output.all;
      Error : Streams.Stream_IO.File_Type :=
         Streams.Stream_IO.Standard_Files.Standard_Error.all)
      return Process is
   begin
      return Result : Process do
         Create (
            Result,
            Command_Line,
            Directory,
            Search_Path,
            Input,
            Output,
            Error);
      end return;
   end Create;

   procedure Wait (Child : Process; Status : out Command_Line.Exit_Status) is
      Handle : constant C.winnt.HANDLE := Reference (Child).all;
   begin
      if C.winbase.WaitForSingleObject (
         Handle,
         C.winbase.INFINITE) /= C.winbase.WAIT_OBJECT_0
      then
         Raise_Exception (Use_Error'Identity);
      else
         declare
            Max : constant := C.windef.DWORD'Modulus / 2; -- 16#8000_0000#
            Exit_Code : aliased C.windef.DWORD;
         begin
            if C.winbase.GetExitCodeProcess (Handle, Exit_Code'Access) = 0 then
               Raise_Exception (Use_Error'Identity);
            end if;
            if Exit_Code < Max then
               Status := Command_Line.Exit_Status (Exit_Code);
            else
               --  terminated by an unhandled exception
               Status := Command_Line.Exit_Status'Last;
            end if;
         end;
      end if;
   end Wait;

   procedure Wait (Child : Process) is
      Dummy : Command_Line.Exit_Status;
      pragma Unreferenced (Dummy);
   begin
      Wait (Child, Dummy);
   end Wait;

   procedure Shell (
      Command_Line : String;
      Status : out Ada.Command_Line.Exit_Status)
   is
      --  unimplemented, should use ShellExecute
      P : constant Process := Create (Command_Line, Search_Path => True);
   begin
      Wait (P, Status);
   end Shell;

   procedure Shell (
      Command_Line : String)
   is
      Dummy : Ada.Command_Line.Exit_Status;
      pragma Unreferenced (Dummy);
   begin
      Shell (Command_Line, Dummy);
   end Shell;

   procedure Append_Argument (
      Command_Line : in out String;
      Last : in out Natural;
      Argument : String)
   is
      Has_Space : Boolean;
   begin
      --  add separator
      if Last >= Command_Line'First then
         if Last >= Command_Line'Last then
            raise Constraint_Error;
         end if;
         Last := Last + 1;
         Command_Line (Last) := ' ';
      end if;
      --  find space in argument
      Has_Space := False;
      for I in Argument'Range loop
         if Argument (I) = ' ' then
            Has_Space := True;
            exit;
         end if;
      end loop;
      --  open
      if Has_Space then
         if Last >= Command_Line'Last then
            raise Constraint_Error;
         end if;
         Last := Last + 1;
         Command_Line (Last) := '"';
      end if;
      if Last + Argument'Length > Command_Line'Last then
         raise Constraint_Error;
      end if;
      --  argument
      Command_Line (Last + 1 .. Argument'Length) := Argument;
      Last := Last + Argument'Length;
      --  close
      if Has_Space then
         if Last >= Command_Line'Last then
            raise Constraint_Error;
         end if;
         Last := Last + 1;
         Command_Line (Last) := '"';
      end if;
   end Append_Argument;

   package body Controlled is

      function Reference (Object : Process)
         return not null access C.winnt.HANDLE is
      begin
         return Object.Handle'Unrestricted_Access;
      end Reference;

      overriding procedure Finalize (Object : in out Process) is
      begin
         if Object.Handle /= C.winbase.INVALID_HANDLE_VALUE then
            if C.winbase.CloseHandle (Object.Handle) = 0 then
               null; -- raise Use_Error;
            end if;
         end if;
      end Finalize;

   end Controlled;

end Ada.Processes;