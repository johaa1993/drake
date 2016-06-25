pragma License (Unrestricted);
--  implementation unit specialized for Windows
with C.winbase;
with C.windef;
with C.winnt;
package System.Native_Tasks is
   pragma Preelaborate;

   type Task_Attribute_Of_Abort;

   --  thread

   subtype Handle_Type is C.winnt.HANDLE;

   function Current return Handle_Type
      renames C.winbase.GetCurrentThread;

   subtype Parameter_Type is C.windef.LPVOID;
   subtype Result_Type is C.windef.DWORD;

   subtype Thread_Body_Type is C.winbase.PTHREAD_START_ROUTINE;
   pragma Convention_Identifier (Thread_Body_CC, WINAPI);
      --  WINAPI is stdcall convention on 32bit, or C convention on 64bit.

   procedure Create (
      Handle : aliased out Handle_Type;
      Parameter : Parameter_Type;
      Thread_Body : Thread_Body_Type;
      Error : out Boolean);

   procedure Join (
      Handle : Handle_Type; -- of target thread
      Abort_Current : access Task_Attribute_Of_Abort; -- of current thread
      Result : aliased out Result_Type;
      Error : out Boolean);
   procedure Detach (
      Handle : in out Handle_Type;
      Error : out Boolean);

   --  stack

   function Info_Block (Handle : Handle_Type) return C.winnt.struct_TEB_ptr;

   --  signals

   type Abort_Handler is access procedure;

   procedure Install_Abort_Handler (Handler : Abort_Handler);
   procedure Uninstall_Abort_Handler;

   pragma Inline (Install_Abort_Handler);
   pragma Inline (Uninstall_Abort_Handler);

   type Task_Attribute_Of_Abort is record
      Event : C.winnt.HANDLE;
      Blocked : Boolean;
   end record;
   pragma Suppress_Initialization (Task_Attribute_Of_Abort);

   procedure Initialize (Attr : in out Task_Attribute_Of_Abort);
   procedure Finalize (Attr : in out Task_Attribute_Of_Abort);

   procedure Send_Abort_Signal (
      Handle : Handle_Type;
      Attr : Task_Attribute_Of_Abort;
      Error : out Boolean);

   procedure Block_Abort_Signal (Attr : in out Task_Attribute_Of_Abort);
   procedure Unblock_Abort_Signal (Attr : in out Task_Attribute_Of_Abort);

   pragma Inline (Block_Abort_Signal);
   pragma Inline (Unblock_Abort_Signal);

end System.Native_Tasks;
