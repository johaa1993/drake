pragma License (Unrestricted);
--  implementation unit
package System.Synchronous_Objects.Abortable is
   pragma Preelaborate;

   --  condition variable

   procedure Wait (
      Object : in out Condition_Variable;
      Mutex : in out Synchronous_Objects.Mutex;
      Timeout : Duration;
      Notified : out Boolean;
      Aborted : out Boolean);

   --  queue

   procedure Take ( -- waiting
      Object : in out Queue;
      Item : out Queue_Node_Access;
      Params : Address;
      Filter : Queue_Filter;
      Aborted : out Boolean);

   --  event

   procedure Wait (
      Object : in out Event;
      Aborted : out Boolean);
   procedure Wait (
      Object : in out Event;
      Timeout : Duration;
      Value : out Boolean;
      Aborted : out Boolean);

   --  group-synchronization

   procedure Wait (
      Object : in out Barrier;
      Notified : out Boolean;
      Aborted : out Boolean);

private

   Abort_Checking_Span : constant Duration := 1.0;

   procedure Wait (
      Object : in out Condition_Variable;
      Mutex : in out Synchronous_Objects.Mutex;
      Timeout : Native_Calendar.Native_Time;
      Notified : out Boolean;
      Aborted : out Boolean);

end System.Synchronous_Objects.Abortable;
