pragma License (Unrestricted);
--  implementation unit specialized for POSIX (Darwin, FreeBSD, or Linux)
with C.sys.types;
with C.unistd;
package System.Native_Credentials is
   pragma Preelaborate;

   subtype User_Id is C.sys.types.uid_t;
   subtype Group_Id is C.sys.types.gid_t;

   function Current_User return User_Id
      renames C.unistd.getuid;
   function Current_Group return Group_Id
      renames C.unistd.getgid;

   function User_Name (Id : User_Id := Current_User) return String;
   function Group_Name (Id : Group_Id := Current_Group) return String;

   --  Check which a resouce belongs

   function Belongs_To_Current_User (Id : User_Id) return Boolean;
   function Belongs_To_Current_Group (Id : Group_Id) return Boolean;

   pragma Inline (Belongs_To_Current_User);

end System.Native_Credentials;
