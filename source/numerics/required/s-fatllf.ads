pragma License (Unrestricted);
--  implementation unit required by compiler
package System.Fat_LLF is
   pragma Pure;

   package Attr_Long_Long_Float is

      --  required for Long_Long_Float'Adjacent by compiler (s-fatgen.ads)
      function Adjacent (X, Towards : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_nextafterl";

      --  required for Long_Long_Float'Ceiling by compiler (s-fatgen.ads)
      function Ceiling (X : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_ceill";

      --  required for Long_Long_Float'Compose by compiler (s-fatgen.ads)
      function Compose (Fraction : Long_Long_Float; Exponent : Integer)
         return Long_Long_Float;

      --  required for Long_Long_Float'Copy_Sign by compiler (s-fatgen.ads)
      function Copy_Sign (X, Y : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_copysignl";

      --  required for Long_Long_Float'Exponent by compiler (s-fatgen.ads)
      function Exponent (X : Long_Long_Float) return Integer;

      --  required for Long_Long_Float'Floor by compiler (s-fatgen.ads)
      function Floor (X : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_floorl";

      --  required for Long_Long_Float'Fraction by compiler (s-fatgen.ads)
      function Fraction (X : Long_Long_Float) return Long_Long_Float;

      --  required for Long_Long_Float'Leading_Part by compiler (s-fatgen.ads)
      function Leading_Part (X : Long_Long_Float; Radix_Digits : Integer)
         return Long_Long_Float;

      --  required for Long_Long_Float'Machine by compiler (s-fatgen.ads)
      function Machine (X : Long_Long_Float) return Long_Long_Float;

      --  required for LLF'Machine_Rounding by compiler (s-fatgen.ads)
      function Machine_Rounding (X : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_nearbyintl";

      --  required for Long_Long_Float'Model by compiler (s-fatgen.ads)
      function Model (X : Long_Long_Float) return Long_Long_Float
         renames Machine;

      --  required for Long_Long_Float'Pred by compiler (s-fatgen.ads)
      function Pred (X : Long_Long_Float) return Long_Long_Float;

      --  required for Long_Long_Float'Remainder by compiler (s-fatgen.ads)
      function Remainder (X, Y : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_remainderl";

      --  required for Long_Long_Float'Rounding by compiler (s-fatgen.ads)
      function Rounding (X : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_roundl";

      --  required for Long_Long_Float'Scaling by compiler (s-fatgen.ads)
      function Scaling (X : Long_Long_Float; Adjustment : Integer)
         return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_ldexpl";

      --  required for Long_Long_Float'Succ by compiler (s-fatgen.ads)
      function Succ (X : Long_Long_Float) return Long_Long_Float;

      --  required for Long_Long_Float'Truncation by compiler (s-fatgen.ads)
      function Truncation (X : Long_Long_Float) return Long_Long_Float
         with Import,
            Convention => Intrinsic, External_Name => "__builtin_truncl";

      --  required for LLF'Unbiased_Rounding by compiler (s-fatgen.ads)
      function Unbiased_Rounding (X : Long_Long_Float) return Long_Long_Float;

      --  required for Long_Long_Float'Valid by compiler (s-fatgen.ads)
      function Valid (X : not null access Long_Long_Float) return Boolean;
      pragma Export (Ada, Valid,
         "system__fat_llf__attr_long_long_float__valid");
      function Unaligned_Valid (A : Address) return Boolean;
      pragma Import (Ada, Unaligned_Valid,
         "system__fat_llf__attr_long_long_float__valid");
      pragma Machine_Attribute (Unaligned_Valid, "pure");

   end Attr_Long_Long_Float;

end System.Fat_LLF;
