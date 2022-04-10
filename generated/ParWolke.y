-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module ParWolke where
import AbsWolke
import LexWolke
import ErrM

}

%name pProgram Program
-- no lexer declaration
%monad { Err } { thenM } { returnM }
%tokentype {Token}
%token
  '!=' { PT _ (TS _ 1) }
  '%' { PT _ (TS _ 2) }
  '&' { PT _ (TS _ 3) }
  '(' { PT _ (TS _ 4) }
  ')' { PT _ (TS _ 5) }
  '*' { PT _ (TS _ 6) }
  '+' { PT _ (TS _ 7) }
  ',' { PT _ (TS _ 8) }
  '-' { PT _ (TS _ 9) }
  '->' { PT _ (TS _ 10) }
  '/' { PT _ (TS _ 11) }
  ':' { PT _ (TS _ 12) }
  ';' { PT _ (TS _ 13) }
  '<' { PT _ (TS _ 14) }
  '<=' { PT _ (TS _ 15) }
  '=' { PT _ (TS _ 16) }
  '==' { PT _ (TS _ 17) }
  '>' { PT _ (TS _ 18) }
  '>=' { PT _ (TS _ 19) }
  'Boolean' { PT _ (TS _ 20) }
  'False' { PT _ (TS _ 21) }
  'Function' { PT _ (TS _ 22) }
  'Int' { PT _ (TS _ 23) }
  'String' { PT _ (TS _ 24) }
  'True' { PT _ (TS _ 25) }
  'Void' { PT _ (TS _ 26) }
  'and' { PT _ (TS _ 27) }
  'break' { PT _ (TS _ 28) }
  'continue' { PT _ (TS _ 29) }
  'def' { PT _ (TS _ 30) }
  'else' { PT _ (TS _ 31) }
  'if' { PT _ (TS _ 32) }
  'not' { PT _ (TS _ 33) }
  'or' { PT _ (TS _ 34) }
  'pass' { PT _ (TS _ 35) }
  'print' { PT _ (TS _ 36) }
  'return' { PT _ (TS _ 37) }
  'while' { PT _ (TS _ 38) }
  '{' { PT _ (TS _ 39) }
  '}' { PT _ (TS _ 40) }

L_ident  { PT _ (TV $$) }
L_integ  { PT _ (TI $$) }
L_quoted { PT _ (TL $$) }


%%

Ident   :: { Ident }   : L_ident  { Ident $1 }
Integer :: { Integer } : L_integ  { (read ( $1)) :: Integer }
String  :: { String }  : L_quoted {  $1 }

Program :: { (Program ()) }
Program : ListDef { AbsWolke.Prog () $1 }
Def :: { (Def ()) }
Def : 'def' Ident '(' ListArg ')' '->' Type Block { AbsWolke.FunDef () $2 $4 $7 $8 }
    | Type Ident '=' Expr { AbsWolke.VarDef () $1 $2 $4 }
ListDef :: { [Def ()] }
ListDef : Def { (:[]) $1 } | Def ListDef { (:) $1 $2 }
Arg :: { (Arg ()) }
Arg : Ident ':' Type { AbsWolke.ArgVal () $1 $3 }
    | Ident ':' Type '&' { AbsWolke.ArgRef () $1 $3 }
ListArg :: { [Arg ()] }
ListArg : {- empty -} { [] }
        | Arg { (:[]) $1 }
        | Arg ',' ListArg { (:) $1 $3 }
Block :: { (Block ()) }
Block : '{' ListStmt '}' { AbsWolke.SBlock () (reverse $2) }
ListStmt :: { [Stmt ()] }
ListStmt : {- empty -} { [] } | ListStmt Stmt { flip (:) $1 $2 }
Stmt :: { (Stmt ()) }
Stmt : 'pass' ';' { AbsWolke.Empty () }
     | Block { AbsWolke.BStmt () $1 }
     | Def ';' { AbsWolke.SDef () $1 }
     | Ident '=' Expr ';' { AbsWolke.Ass () $1 $3 }
     | 'return' Expr ';' { AbsWolke.Ret () $2 }
     | 'return' ';' { AbsWolke.VRet () }
     | 'if' Expr Block { AbsWolke.Cond () $2 $3 }
     | 'if' Expr Block 'else' Block { AbsWolke.CondElse () $2 $3 $5 }
     | 'while' Expr Block { AbsWolke.While () $2 $3 }
     | Expr ';' { AbsWolke.SExp () $1 }
     | 'break' ';' { AbsWolke.Break () }
     | 'continue' ';' { AbsWolke.Continue () }
     | 'print' '(' Expr ')' ';' { AbsWolke.Print () $3 }
Type :: { (Type ()) }
Type : 'Int' { AbsWolke.Int () }
     | 'String' { AbsWolke.Str () }
     | 'Boolean' { AbsWolke.Bool () }
     | 'Void' { AbsWolke.Void () }
     | 'Function' '(' ListType ')' Type { AbsWolke.Fun () $3 $5 }
ListType :: { [Type ()] }
ListType : {- empty -} { [] }
         | Type { (:[]) $1 }
         | Type ',' ListType { (:) $1 $3 }
Expr6 :: { Expr () }
Expr6 : Ident { AbsWolke.EVar () $1 }
      | Integer { AbsWolke.ELitInt () $1 }
      | 'True' { AbsWolke.ELitTrue () }
      | 'False' { AbsWolke.ELitFalse () }
      | Ident '(' ListExpr ')' { AbsWolke.EApp () $1 $3 }
      | String { AbsWolke.EString () $1 }
      | '(' Expr ')' { $2 }
Expr5 :: { Expr () }
Expr5 : '-' Expr6 { AbsWolke.Neg () $2 }
      | 'not' Expr6 { AbsWolke.Not () $2 }
      | Expr6 { $1 }
Expr4 :: { Expr () }
Expr4 : Expr4 MulOp Expr5 { AbsWolke.EMul () $1 $2 $3 }
      | Expr5 { $1 }
Expr3 :: { Expr () }
Expr3 : Expr3 AddOp Expr4 { AbsWolke.EAdd () $1 $2 $3 }
      | Expr4 { $1 }
Expr2 :: { Expr () }
Expr2 : Expr2 RelOp Expr3 { AbsWolke.ERel () $1 $2 $3 }
      | Expr3 { $1 }
Expr1 :: { Expr () }
Expr1 : Expr2 'and' Expr1 { AbsWolke.EAnd () $1 $3 } | Expr2 { $1 }
Expr :: { (Expr ()) }
Expr : Expr1 'or' Expr { AbsWolke.EOr () $1 $3 } | Expr1 { $1 }
ListExpr :: { [Expr ()] }
ListExpr : {- empty -} { [] }
         | Expr { (:[]) $1 }
         | Expr ',' ListExpr { (:) $1 $3 }
AddOp :: { (AddOp ()) }
AddOp : '+' { AbsWolke.Plus () } | '-' { AbsWolke.Minus () }
MulOp :: { (MulOp ()) }
MulOp : '*' { AbsWolke.Times () }
      | '/' { AbsWolke.Div () }
      | '%' { AbsWolke.Mod () }
RelOp :: { (RelOp ()) }
RelOp : '<' { AbsWolke.LTH () }
      | '<=' { AbsWolke.LE () }
      | '>' { AbsWolke.GTH () }
      | '>=' { AbsWolke.GE () }
      | '==' { AbsWolke.EQU () }
      | '!=' { AbsWolke.NE () }
{

returnM :: a -> Err a
returnM = return

thenM :: Err a -> (a -> Err b) -> Err b
thenM = (>>=)

happyError :: [Token] -> Err a
happyError ts =
  Bad $ "syntax error at " ++ tokenPos ts ++ 
  case ts of
    [] -> []
    [Err _] -> " due to lexer error"
    _ -> " before " ++ unwords (map (id . prToken) (take 4 ts))

myLexer = tokens
}

