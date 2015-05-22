with System.Synchronous_Control;
package body System.Once is
   pragma Suppress (All_Checks);

   Yet : constant := 0;
   Start : constant := 1;
   Done : constant := 2;

   function sync_val_compare_and_swap (
      A1 : not null access Flag;
      A2 : Flag;
      A3 : Flag)
      return Flag
      with Import,
         Convention => Intrinsic,
         External_Name => "__sync_val_compare_and_swap_1";

   --  implementation

   procedure Initialize (
      Flag : not null access Once.Flag;
      Process : not null access procedure) is
   begin
      case sync_val_compare_and_swap (Flag, Yet, Start) is
         when Yet => -- succeeded to swap
            pragma Assert (Flag.all = Start);
            Process.all;
            Flag.all := Done;
         when Start => -- wait
            loop
               Synchronous_Control.Yield;
               exit when Flag.all = Done;
            end loop;
         when others => -- done
            null;
      end case;
   end Initialize;

end System.Once;
