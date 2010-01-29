module Data.XDR.PrettyPrinter
    ( ppXDR
    ) where

import Text.PrettyPrint.Leijen as PP hiding (braces, indent)

import Data.XDR.AST

----------------------------------------------------------------

indent :: Int
indent = 8

ppOptional :: (a -> Doc) -> Maybe a -> Doc
ppOptional _ Nothing = empty
ppOptional fn (Just a) = fn a

braces :: [Doc] -> Doc
braces ds = nest indent (lbrace <$> vcat ds) <$> rbrace

ppXDR :: Specification -> String
ppXDR = show . ppSpec
    where
      ppSpec (Specification defs) = vcat . punctuate linebreak . map ppDef $ defs

      ppDef (DefTypedef td) = ppTypedef td
      ppDef (DefConstant cd) = ppConstdef cd

      ppTypedef (Typedef n ti) = text "typedef" <+> ppTypedefInternal n ti <> semi

      ppTypedefInternal n (DefSimple di) = ppDecl (Decl n di)
      ppTypedefInternal n (DefEnum ed) = text "enum" <+> ppEnumDetail ed <+> text n
      ppTypedefInternal n (DefStruct sd) = text "struct" <+> ppStructDetail sd <+> text n
      ppTypedefInternal n (DefUnion ud) = text "union" <+> ppUnionDetail ud <+> text n

      ppEnumDetail (EnumDetail xs) = braces . punctuate comma . map ppEnumDef $ xs
      ppEnumDef (n, c) = text n <+> text "=" <+> ppConstant c

      ppStructDetail (StructDetail decls) = braces . map ((<> semi) . ppDecl) $ decls

      ppUnionDetail (UnionDetail selector cases mDefault) =
          vcat $ concat [ [ text "switch" <> parens (ppDecl selector) <+> lbrace ]
                        , map ppCase cases
                        , [ppDflt mDefault]
                        , [rbrace]
                        ]

      ppCase (c, d) = nest indent (ppConstant c <> colon <$> ppDecl d <> semi)
      ppDflt d = ppOptional (\d -> nest indent (text "default:" <$> ppDecl d)) d

      ppConstdef (ConstantDef n c) = text "const" <+> text n <+> text "=" <+> ppConstant c <> semi

      ppConstant (ConstLit n) = text . show $ n

      ppDecl (Decl n (DeclSimple t)) = ppType t <+> text n
      ppDecl (Decl n (DeclArray t c)) = ppType t <+> text n <> (brackets . ppConstant $ c)
      ppDecl (Decl n (DeclVarArray t mc)) = ppType t <+> text n <+> ppVarSize mc
      ppDecl (Decl n (DeclOpaque c)) = text "opaque" <+> text n <> (brackets . ppConstant $ c)
      ppDecl (Decl n (DeclVarOpaque mc)) = text "opaque" <+> text n <> ppVarSize mc
      ppDecl (Decl n (DeclString mc)) = text "string" <+> text n <> ppVarSize mc
      ppDecl (Decl n (DeclPointer t)) = ppType t <> text "*" <+> text n
      ppDecl DeclVoid = text "void"

      ppVarSize :: Maybe Constant -> Doc
      ppVarSize = angles . ppOptional ppConstant

      ppType TInt = text "int"
      ppType TUInt = text "unsigned int"
      ppType THyper = text "hyper"
      ppType TUHyper = text "unsigned hyper"
      ppType TFloat = text "float"
      ppType TDouble = text "double"
      ppType TQuad = text "quad"
      ppType TBool = text "bool"
      ppType (TEnum ed) = text "enum" <+> ppEnumDetail ed
      ppType (TStruct sd) = text "struct" <+> ppStructDetail sd
      ppType (TUnion ud) = text "union" <+> ppUnionDetail ud
      ppType (TTypedef n) = text n

----------------------------------------------------------------