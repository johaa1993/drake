pragma License (Unrestricted);
--  implementation unit specialized for FreeBSD
package Ada.Calendar.Time_Zones.Inside is

   function UTC_Time_Offset (Date : Time) return Time_Offset;
   pragma Pure_Function (UTC_Time_Offset);

end Ada.Calendar.Time_Zones.Inside;
