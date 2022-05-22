module TypeChecker where

import Control.Monad.Reader
import Control.Monad.Trans.Except
import Data.Functor.Identity
import Data.List ( intercalate )

import qualified Data.Map as M
import qualified Gen.AbsWolke as Abs
import Gen.PrintWolke ( Print, printTree )

import Utils


----------------------------------------------------- DATA TYPES -----------------------------------------------------

data Type
    = TInt
    | TStr
    | TBool
    | TVoid
    | TFun [Abs.Arg] Type
    deriving (Eq)

instance Show Type where
    show TInt = "Int"
    show TStr = "String"
    show TBool = "Boolean"
    show TVoid = "Void"
    show _ = ""


type Env = M.Map Var Type

type TCM a = ReaderT Env (Except Exception) a


-------------------------------------------------- HELPER FUNCTIONS --------------------------------------------------

throwEx :: Pos -> Exception -> TCM a
throwEx p e = lift $ throwE $ gluePos p e


convType :: Abs.Type -> Type
convType (Abs.Int _) = TInt
convType (Abs.Str _) = TStr
convType (Abs.Bool _) = TBool
convType (Abs.Void _) = TVoid


convArg :: Abs.Arg -> Type
convArg (Abs.ArgVal _ _ t) = convType t
convArg (Abs.ArgRef _ _ t) = convType t


invalidOp2 :: Print a => a -> Type -> Type -> Exception
invalidOp2 op t1 t2 = "Invalid operation: (" ++ printTree op ++ ") on type " ++ show t1 ++ " and type " ++ show t2


----------------------------------------------------- EXPRESSIONS -----------------------------------------------------

getType :: Abs.Expr -> TCM Type
getType (Abs.EVar p (Abs.Ident idn)) = do
    r <- ask
    case M.lookup idn r of
        Just t -> return t
        _ -> throwEx p ("Use of undefined variable: " ++ idn)

getType (Abs.ELitInt _ _) = return TInt

getType (Abs.ELitTrue _) = return TBool

getType (Abs.ELitFalse _) = return TBool

getType (Abs.EString _ _) = return TStr

getType (Abs.EApp p (Abs.Ident idn) args) = do
    r <- ask
    argTypes <- mapM getType args
    case idn of
        "main" -> throwEx p "The function main shall not be used within a program"
        _ -> case M.lookup idn r of
                Just (TFun arguments ret) -> do
                    checkArgRefs arguments args
                    if map convArg arguments == argTypes
                        then return ret
                        else throwEx p ("Invalid arguments given to application of function " ++ idn)
                _ -> throwEx p ("Invalid operation: application of " ++ idn)
    where
        checkArgRefs :: [Abs.Arg] -> [Abs.Expr] -> TCM ()
        checkArgRefs [] [] = pure ()
        checkArgRefs ((Abs.ArgRef _ _ _):xs) ((Abs.EVar _ _):ys) = checkArgRefs xs ys
        checkArgRefs ((Abs.ArgRef _ _ _):_) (arg:_) = throwEx (Abs.hasPosition arg) "Non-variable passed by reference"
        checkArgRefs (_:xs) (_:ys) = checkArgRefs xs ys
        checkArgRefs _ _ = pure ()

getType (Abs.Neg p exp) = do
    t <- getType exp
    case t of
        TInt -> return TInt
        _ -> throwEx p ("Invalid operation: (-) on type " ++ show t)

getType (Abs.Not p exp) = do
    t <- getType exp
    case t of
        TBool -> return TBool
        _ -> throwEx p ("Invalid operation: (not) on type " ++ show t)

getType (Abs.EMul p exp1 op exp2) = do
    t1 <- getType exp1
    t2 <- getType exp2
    if t1 == t2 && t1 == TInt
        then return t1
        else throwEx p (invalidOp2 op t1 t2)

getType (Abs.EAdd p exp1 op exp2) = do
    t1 <- getType exp1
    t2 <- getType exp2
    if t1 /= t2
        then throwEx p (invalidOp2 op t1 t2)
        else case t1 of
            TInt -> return TInt
            TStr -> isPlus op t1 t2
            _ -> throwEx p (invalidOp2 op t1 t2)
    where
        isPlus (Abs.Plus _) _ _ = return TStr
        isPlus op@(Abs.Minus _) t1 t2 = throwEx p (invalidOp2 op t1 t2)

getType (Abs.ERel p exp1 op exp2) = do
    t1 <- getType exp1
    t2 <- getType exp2
    if t1 /= t2
        then throwEx p (invalidOp2 op t1 t2)
        else case t1 of
            TInt -> return TBool
            TBool -> isEQUorNE op t1 t2
            TStr -> isEQUorNE op t1 t2
            _ -> throwEx p (invalidOp2 op t1 t2)
    where
        isEQUorNE (Abs.EQU _) _ _ = return TBool
        isEQUorNE (Abs.NE _) _ _ = return TBool
        isEQUorNE op t1 t2 = throwEx p (invalidOp2 op t1 t2)

getType (Abs.EAnd p exp1 exp2) = do
    t1 <- getType exp1
    t2 <- getType exp2
    if t1 == t2 && t1 == TBool
        then return t1
        else throwEx p ("Invalid operation: (and) on type " ++ show t1 ++ " and type " ++ show t2)

getType (Abs.EOr p exp1 exp2) = do
    t1 <- getType exp1
    t2 <- getType exp2
    if t1 == t2 && t1 == TBool
        then return t1
        else throwEx p ("Invalid operation: (or) on type " ++ show t1 ++ " and type " ++ show t2)


----------------------------------------------------- STATEMENTS -----------------------------------------------------

checkStmt :: Abs.Stmt -> TCM ()
checkStmt (Abs.Empty p) = return ()

checkStmt (Abs.SDef p t idn exp) = return ()

checkStmt (Abs.Ass p idn exp) = do
    r <- ask
    case M.lookup (convIdent idn) r of
        Nothing -> throwEx p ("Use of undefined variable: " ++ convIdent idn)
        Just t -> do
            t1 <- getType exp
            when (t /= t1) $ throwEx p ("Invalid assignment: " ++ show t ++ " = " ++ show t1)

checkStmt (Abs.Ret p exp) = do
    r <- ask
    case M.lookup "return" r of
        Nothing -> throwEx p "Out of function return use"
        Just t -> do
            t1 <- getType exp
            when (t /= t1) $
                throwEx (Abs.hasPosition exp) ("Invalid return type: expected " ++ show t ++ " but found " ++ show t1)

checkStmt (Abs.VRet p) = do
    r <- ask
    case M.lookup "return" r of
        Just TVoid -> return ()
        Just t -> throwEx p "No return value"
        Nothing -> throwEx p "Out of function return use"

checkStmt (Abs.Cond p exp b) = do
    t <- getType exp
    case t of
        TBool -> checkBlock b
        _ -> throwEx p ("Invalid type in if condition: expected " ++ show TBool ++ " but found " ++ show t)

checkStmt (Abs.CondElse p exp b1 b2) = do
    t <- getType exp
    case t of
        TBool -> checkBlock b1 >> checkBlock b2
        _ -> throwEx p ("Invalid type in if condition: expected " ++ show TBool ++ " but found " ++ show t)

checkStmt (Abs.While p exp b) = do
    t <- getType exp
    case t of
        TBool -> local (M.insert "while" TBool) (checkBlock b)
        _ -> throwEx p ("Invalid type in while condition: expected " ++ show TBool ++ " but found " ++ show t)

checkStmt (Abs.SExp p exp) = getType exp >> return ()

checkStmt st@(Abs.Break p) = do
    r <- ask
    case M.lookup "while" r of
        Nothing -> throwEx (Abs.hasPosition st) "Invalid use of break statement"
        _ -> return ()

checkStmt st@(Abs.Continue p) = do
    r <- ask
    case M.lookup "while" r of
        Nothing -> throwEx (Abs.hasPosition st) "Invalid use of continue statement"
        _ -> return ()

checkStmt (Abs.Print p exp) = do
    t <- getType exp
    when (t == TVoid) $ throwEx p "Invalid type in print statement: Void"

checkStmt (Abs.Assert p exp) = do
    t <- getType exp
    when (t /= TBool) $ throwEx p ("Invalid type in assert statement: " ++ show t)


--------------------------------------------------- MAIN FUNCTIONS ---------------------------------------------------

insertArgs :: [Abs.Arg] -> TCM Env
insertArgs [] = ask

insertArgs (a:args) = do
    r <- ask
    case M.lookup name r of
        Just t -> throwEx (Abs.hasPosition a) ("Duplicate argument in function definition: " ++ name)
        Nothing -> local (M.insert name (argType a)) (insertArgs args)
    where
        argName (Abs.ArgVal _ idn _) = convIdent idn
        argName (Abs.ArgRef _ idn _) = convIdent idn
        argType (Abs.ArgVal _ _ t) = convType t
        argType (Abs.ArgRef _ _ t) = convType t
        name = argName a


checkSDefs :: [Abs.Stmt] -> TCM ()
checkSDefs [] = return ()

checkSDefs ((Abs.SDef p t idn' exp):stmts) = do
    r <- ask
    case M.lookup idn r of
        Just _ -> throwEx p ("Local redefinition of " ++ idn)
        Nothing -> local (M.insert idn (convType t)) (checkSDefs stmts)
    where
        idn = convIdent idn'

checkSDefs (_:stmts) = checkSDefs stmts


checkBlock :: Abs.Block -> TCM ()
checkBlock (Abs.SBlock p stmts) = do
    local (const M.empty) (checkSDefs stmts)
    checkStmts stmts


checkStmts :: [Abs.Stmt] -> TCM ()
checkStmts [] = return ()

checkStmts (st@(Abs.SDef p t idn' exp):stmts) = do
    t1 <- getType exp
    if convType t /= t1
        then throwEx p ("Invalid assignment type of variable " ++ idn ++ ": expected " ++ show (convType t) ++ " but got " ++ show t1)
        else local (M.insert idn (convType t)) (checkStmts stmts)
    where
        idn = convIdent idn'

checkStmts (st:stmts) = checkStmt st >> checkStmts stmts


--------------------------------------------------- RUN FUNCTIONS ---------------------------------------------------

run :: Abs.Program -> Either Exception ()
run (Abs.Prog _ defs) = runExcept (runReaderT (checkProgram defs) M.empty)


checkProgram :: [Abs.Def] -> TCM ()
checkProgram [] = do
    r <- ask
    case M.lookup "main" r of
        Just (TFun [] TVoid) -> return ()
        Nothing -> throwEx Nothing "No main declaration"
        _ -> throwEx Nothing "Invalid main declaration"

checkProgram ((Abs.VarDef p t idn' exp):defs) = do
    r <- ask
    case M.lookup idn r of
        Just _ -> throwEx p ("Redefinition of " ++ idn)
        Nothing -> do
            t1 <- getType exp
            if convType t /= t1
                then throwEx p ("Invalid type of variable " ++ idn ++ ": expected " ++ show (convType t) ++ " but found " ++ show t1)
                else local (M.insert idn t1) (checkProgram defs)
        where
            idn = convIdent idn'

checkProgram (fun@(Abs.FunDef p idn' args ret' b@(Abs.SBlock pb stmts)):defs) = do
    when (null stmts) $ throwEx p ("Empty function: " ++ idn)
    r <- ask
    case M.lookup idn r of
        Just _ -> throwEx p ("Redefinition of " ++ idn)
        Nothing -> do
            let r_fun = M.insert idn (TFun args ret) M.empty
                r_fun_ret = M.insert "return" ret r_fun
            r_fun_ret_args <- local (const r_fun_ret) (insertArgs args)
            local (const r_fun_ret_args) (checkSDefs stmts)
            local (M.union r_fun_ret_args) (checkStmts stmts)
            local (M.union r_fun) (checkProgram defs)
    where
        idn = convIdent idn'
        ret = convType ret'