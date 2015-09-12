package body System.Fat_Sflt is

   function frexp (value : Short_Float; exp : access Integer)
      return Short_Float
      with Import,
         Convention => Intrinsic, External_Name => "__builtin_frexpf";

   function inf return Short_Float
      with Import, Convention => Intrinsic, External_Name => "__builtin_inff";

   function isfinite (X : Short_Float) return Integer
      with Import,
         Convention => Intrinsic, External_Name => "__builtin_isfinite";
   pragma Warnings (Off, isfinite); -- [gcc 4.6] excessive prototype checking

   package body Attr_Short_Float is

      function Compose (Fraction : Short_Float; Exponent : Integer)
         return Short_Float is
      begin
         return Scaling (Attr_Short_Float.Fraction (Fraction), Exponent);
      end Compose;

      function Exponent (X : Short_Float) return Integer is
         Result : aliased Integer;
         Dummy : Short_Float;
      begin
         Dummy := frexp (X, Result'Access);
         return Result;
      end Exponent;

      function Fraction (X : Short_Float) return Short_Float is
         Dummy : aliased Integer;
      begin
         return frexp (X, Dummy'Access);
      end Fraction;

      function Leading_Part (X : Short_Float; Radix_Digits : Integer)
         return Short_Float
      is
         S : constant Integer := Radix_Digits - Exponent (X);
      begin
         return Scaling (Truncation (Scaling (X, S)), -S);
      end Leading_Part;

      function Machine (X : Short_Float) return Short_Float is
      begin
         return Short_Float (Long_Long_Float (X)); -- ???
      end Machine;

      function Pred (X : Short_Float) return Short_Float is
      begin
         return Adjacent (X, -inf);
      end Pred;

      function Succ (X : Short_Float) return Short_Float is
      begin
         return Adjacent (X, inf);
      end Succ;

      function Unbiased_Rounding (X : Short_Float) return Short_Float is
      begin
         return X - Remainder (X, 1.0);
      end Unbiased_Rounding;

      function Valid (X : not null access Short_Float) return Boolean is
      begin
         return isfinite (X.all) /= 0;
      end Valid;

   end Attr_Short_Float;

end System.Fat_Sflt;
