module Utils where

import System.Exit ( exitFailure )
import qualified Gen.AbsWolke as Abs


----------------------------------------------------- DATA TYPES -----------------------------------------------------

type Exception = String

type Var = String

type Pos = Abs.BNFC'Position


------------------------------------------------------ FUNCTIONS ------------------------------------------------------

showPos :: Pos -> String
showPos Nothing = "(Ln ?, Col ?)"
showPos (Just (line, col)) = "(Ln " ++ show line ++ ", Col " ++ show col ++ ")"


gluePos :: Pos -> Exception -> Exception
gluePos p e = showPos p ++ " => " ++ e


convIdent :: Abs.Ident -> String
convIdent (Abs.Ident x) = x