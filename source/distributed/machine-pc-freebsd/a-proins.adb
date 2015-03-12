with Ada.Exception_Identification.From_Here;
with System.Zero_Terminated_Strings;
with C.fcntl;
with C.unistd;
package body Ada.Processes.Inside is
   use Exception_Identification.From_Here;
   use type C.signed_int;
   use type C.size_t;

   procedure Spawn (
      Child : out C.sys.types.pid_t;
      Command_Line : String;
      Directory : String;
      Search_Path : Boolean;
      Input : System.Native_IO.Handle_Type;
      Output : System.Native_IO.Handle_Type;
      Error : System.Native_IO.Handle_Type) is
   begin
      Child := C.unistd.fork;
      if Child < 0 then
         Raise_Exception (Use_Error'Identity);
      elsif Child = 0 then
         --  child process
         if Directory /= "" then
            declare
               C_Directory : C.char_array (
                  0 ..
                  Directory'Length * System.Zero_Terminated_Strings.Expanding);
            begin
               System.Zero_Terminated_Strings.To_C (
                  Directory,
                  C_Directory (0)'Access);
               if C.unistd.chdir (C_Directory (0)'Access) < 0 then
                  C.unistd.C_qexit (127);
                  --  _exit is qualified as __attribute__((noreturn))
               end if;
            end;
         end if;
         declare
            C_Command_Line : C.char_array (
               0 ..
               Command_Line'Length * System.Zero_Terminated_Strings.Expanding);
            Arguments : C.char_ptr_array (0 .. 255) := (others => <>);
            Duplicated_Input : System.Native_IO.Handle_Type;
            Duplicated_Output : System.Native_IO.Handle_Type;
            Duplicated_Error : System.Native_IO.Handle_Type;
            Dummy : C.signed_int;
            pragma Unreferenced (Dummy);
         begin
            System.Zero_Terminated_Strings.To_C (
               Command_Line,
               C_Command_Line (0)'Access);
            Split_Argument (C_Command_Line, Arguments);
            if Input /= 0 or else Output /= 1 or else Error /= 2 then
               --  duplicate handles
               Duplicated_Input := C.unistd.dup (Input);
               Duplicated_Output := C.unistd.dup (Output);
               Duplicated_Error := C.unistd.dup (Error);
               --  close standard handles
               if C.unistd.close (0) < 0
                  or else C.unistd.close (1) < 0
                  or else C.unistd.close (2) < 0
               then
                  C.unistd.C_qexit (127);
               end if;
               --  set standard handles
               if C.unistd.dup2 (Duplicated_Input, 0) < 0
                  or else C.unistd.dup2 (Duplicated_Output, 1) < 0
                  or else C.unistd.dup2 (Duplicated_Error, 2) < 0
               then
                  C.unistd.C_qexit (127);
               end if;
               --  close duplicated handles
               if C.unistd.close (Duplicated_Input) < 0
                  or else C.unistd.close (Duplicated_Output) < 0
                  or else C.unistd.close (Duplicated_Error) < 0
               then
                  C.unistd.C_qexit (127);
               end if;
            end if;
            --  clear FD_CLOEXEC
            if C.fcntl.fcntl (0, C.fcntl.F_SETFD, 0) < 0
               or else C.fcntl.fcntl (1, C.fcntl.F_SETFD, 0) < 0
               or else C.fcntl.fcntl (2, C.fcntl.F_SETFD, 0) < 0
            then
               C.unistd.C_qexit (127);
            end if;
            if Search_Path then
               Dummy := C.unistd.execvp (Arguments (0), Arguments (0)'Access);
            else
               Dummy := C.unistd.execv (Arguments (0), Arguments (0)'Access);
            end if;
            C.unistd.C_qexit (127);
         end;
      end if;
   end Spawn;

end Ada.Processes.Inside;
