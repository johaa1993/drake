package body System.Native_Time is
   use type C.signed_int;
   use type C.signed_long;

   --  implementation

   function To_timespec (D : C.sys.time.struct_timeval)
      return C.time.struct_timespec is
   begin
      return (
         tv_sec => D.tv_sec,
         tv_nsec => C.signed_long (D.tv_usec) * 1_000);
   end To_timespec;

   function To_timespec (D : Duration) return C.time.struct_timespec is
      Nanosecond : constant Nanosecond_Number :=
         Nanosecond_Number'Integer_Value (D);
      Sub_Second : constant Nanosecond_Number := Nanosecond mod 1_000_000_000;
   begin
      return (
         tv_sec =>
            C.sys.types.time_t ((Nanosecond - Sub_Second) / 1_000_000_000),
         tv_nsec => C.signed_long (Sub_Second));
   end To_timespec;

   function To_Duration (D : C.time.struct_timespec) return Duration is
   begin
      return Duration'Fixed_Value (
         Nanosecond_Number'Integer_Value (To_Duration (D.tv_sec))
         + Nanosecond_Number (D.tv_nsec));
   end To_Duration;

   function To_Duration (D : C.sys.time.struct_timeval) return Duration is
   begin
      return To_Duration (To_timespec (D));
   end To_Duration;

   function To_Duration (D : C.sys.types.time_t) return Duration is
   begin
      return Duration'Fixed_Value (
         (Nanosecond_Number (D)) * 1_000_000_000);
   end To_Duration;

   procedure Simple_Delay_For (D : Duration) is
      Req_T : aliased C.time.struct_timespec := To_timespec (D);
      Rem_T : aliased C.time.struct_timespec;
      R : C.signed_int;
   begin
      loop
         R := C.time.nanosleep (Req_T'Access, Rem_T'Access);
         exit when R = 0;
         Req_T := Rem_T;
      end loop;
   end Simple_Delay_For;

   procedure Delay_For (D : Duration) is
   begin
      if D >= 0.0 then
         Delay_For_Hook.all (D);
      end if;
   end Delay_For;

end System.Native_Time;
