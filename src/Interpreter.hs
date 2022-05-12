module Interpreter where

import Control.Monad.Reader
import Control.Monad.Trans.State
import Control.Monad.Trans.Except
import Control.Monad.Except ( throwError )
import System.Exit ( die )
import qualified Data.Map as M

import qualified Gen.AbsWolke as Abs
import Utils


----------------------------------------------------- DATA TYPES -----------------------------------------------------

data Value
    = VInt Integer
    | VStr String
    | VBool Bool
    | VVoid
    | VFun [Abs.Arg] Abs.Block Env
    | Blank
    deriving (Eq)

instance Show Value where
    show (VInt v) = show v
    show (VStr v) = show v
    show (VBool v) = show v
    show _ = ""

data Return
    = RReturn Value
    | RBreak
    | RContinue
    

type Loc = Int

type Env = M.Map Var Loc

type Store = (M.Map Loc Value, Loc)

type IM a = StateT Store (ReaderT Env (ExceptT Exception IO)) a


-------------------------------------------------- HELPER FUNCTIONS --------------------------------------------------

throwEx :: Pos -> Exception -> IM a
throwEx p e = throwError $ gluePos p e


--------------------------------------------- MEMORY MANAGEMENT FUNCTIONS ---------------------------------------------

alloc :: IM Loc
alloc = do
    (m, l) <- get
    put (m, l + 1)
    return $ l + 1


getLoc :: Var -> IM Loc
getLoc x = do
    r <- ask
    case M.lookup x r of
        Just loc -> return loc
        Nothing -> throwEx Nothing ("Invalid variable name: " ++ x)


storeInsert :: Loc -> Value -> IM ()
storeInsert loc v = do
    (m, l) <- get
    put (M.insert loc v m, l)


getValue :: Var -> IM (Either Exception Value)
getValue x = do
    loc <- getLoc x
    (m, l) <- get
    case M.lookup loc m of
        Just v -> return $ Right v
        Nothing -> return $ Left ("Invalid variable name: " ++ x)


----------------------------------------------------- EXPRESSIONS -----------------------------------------------------

eval :: Abs.Expr -> IM Value
eval (Abs.EVar p idn) = do
    v <- getValue (convIdent idn)
    case v of
        Left e -> throwEx p e
        Right v -> return v

eval (Abs.ELitInt p v) = return $ VInt v

eval (Abs.ELitTrue p) = return $ VBool True

eval (Abs.ELitFalse p) = return $ VBool False

eval (Abs.EApp p idn exps) = do
    v <- getValue (convIdent idn)
    case v of
        Left e -> throwEx p e
        Right fun@(VFun args (Abs.SBlock _ b) env) -> do
            r <- insertArgs args exps env
            local (const r) (f b)
        Right _ -> return Blank
    
    where
        insertArgs ((Abs.ArgVal _ idn t):args) (e:exps) env = do
            loc <- alloc
            v <- eval e
            let env' = M.insert (convIdent idn) loc env
            storeInsert loc v
            insertArgs args exps env'
        insertArgs ((Abs.ArgRef _ idn t):args) ((Abs.EVar _ x):exps) env = do
            loc <- getLoc (convIdent x)
            let env' = M.insert (convIdent idn) loc env
            insertArgs args exps env'
        insertArgs ((Abs.ArgRef _ idn t):args) (exp:exps) env = do
            throwEx (Abs.hasPosition exp) "Non-variable passed by reference"
        insertArgs _ _ env = return env

        f b = do
            ret <- runSt b
            case ret of
                Just (RReturn v) -> return v
                _ -> return Blank

eval (Abs.EString p s) = return $ VStr s

eval (Abs.Neg p exp) = do
    (VInt v) <- eval exp
    return $ VInt (-v)

eval (Abs.Not p exp) = do
    (VBool v) <- eval exp
    return $ VBool (not v)

eval (Abs.EMul p exp1 op exp2) = do
    v1 <- eval exp1
    v2 <- eval exp2
    divException op v2
    return $ calculate op v1 v2
    where
        calculate (Abs.Times _) (VInt v1) (VInt v2) = VInt (v1 * v2)
        calculate (Abs.Mod _) (VInt v1) (VInt v2) = VInt (v1 `mod` v2)
        calculate (Abs.Div _) (VInt v1) (VInt v2) = VInt (v1 `div` v2)
        calculate _ _ _ = Blank

        divException (Abs.Div _) (VInt v) = when (v == 0) $ throwEx p "Division by 0"
        divException (Abs.Mod _) (VInt v) = when (v == 0) $ throwEx p "Modulo by 0"
        divException _ _ = return ()

eval (Abs.EAdd p exp1 op exp2) = do
    v1 <- eval exp1
    v2 <- eval exp2
    return $ calculate op v1 v2
    where
        calculate (Abs.Plus _) (VStr v1) (VStr v2) = VStr (v1 ++ v2)
        calculate (Abs.Minus _) (VInt v1) (VInt v2) = VInt (v1 - v2)
        calculate (Abs.Plus _) (VInt v1) (VInt v2) = VInt (v1 + v2)
        calculate _ _ _ = Blank

eval (Abs.ERel p exp1 op exp2) = do
    v1 <- eval exp1
    v2 <- eval exp2
    return $ VBool (calculate op v1 v2)
    where
        calculate (Abs.EQU _) v1 v2 = v1 == v2
        calculate (Abs.NE _) v1 v2 = v1 /= v2

        calculate (Abs.LTH _) (VInt v1) (VInt v2) = v1 < v2
        calculate (Abs.LE _) (VInt v1) (VInt v2) = v1 <= v2
        calculate (Abs.GTH _) (VInt v1) (VInt v2) = v1 > v2
        calculate (Abs.GE _) (VInt v1) (VInt v2) = v1 >= v2
        calculate _ _ _ = False

eval (Abs.EAnd p exp1 exp2) = do
    (VBool v1) <- eval exp1
    (VBool v2) <- eval exp2
    return $ VBool (v1 && v2)

eval (Abs.EOr p exp1 exp2) = do
    (VBool v1) <- eval exp1
    (VBool v2) <- eval exp2
    return $ VBool (v1 || v2)


----------------------------------------------------- STATEMENTS -----------------------------------------------------

runSt :: [Abs.Stmt] -> IM (Maybe Return)
runSt [] = return Nothing

runSt ((Abs.Empty p):stmts) = runSt stmts

runSt ((Abs.SDef p t idn exp):stmts) = do
    r <- ask
    loc <- alloc
    v <- eval exp
    storeInsert loc v
    local (M.insert (convIdent idn) loc) (runSt stmts)

runSt ((Abs.Ass p idn exp):stmts) = do
    v <- eval exp
    l <- getLoc (convIdent idn)
    storeInsert l v
    runSt stmts

runSt ((Abs.Ret p exp):stmts) = do
    v <- eval exp
    return $ Just (RReturn v)

runSt ((Abs.VRet p):stmts) = return $ Just (RReturn VVoid)

runSt ((Abs.Cond p exp (Abs.SBlock _ b)):stmts) = do
    v <- eval exp
    case v of
        VBool True -> do
            ret <- runSt b
            case ret of
                Just r@(RReturn val) -> return $ Just r
                Just RBreak -> return $ Just RBreak
                Just RContinue -> return $ Just RContinue
                Nothing -> runSt stmts
        _ -> runSt stmts

runSt ((Abs.CondElse p exp (Abs.SBlock _ b1) (Abs.SBlock _ b2)):stmts) = do
    v <- eval exp
    case v of
        VBool True -> do
            ret <- runSt b1
            case ret of
                Just r@(RReturn val) -> return $ Just r
                Just RBreak -> return $ Just RBreak
                Just RContinue -> return $ Just RContinue
                Nothing -> runSt stmts
        _ -> do
            ret <- runSt b2
            case ret of
                Just r@(RReturn val) -> return $ Just r
                Just RBreak -> return $ Just RBreak
                Just RContinue -> return $ Just RContinue
                Nothing -> runSt stmts

runSt w@((Abs.While p exp (Abs.SBlock _ b)):stmts) = do
    v <- eval exp
    case v of
        VBool True -> do
            ret <- runSt b
            case ret of
                Just r@(RReturn val) -> return $ Just r
                Just RBreak -> runSt stmts
                Just RContinue -> runSt w
                Nothing -> runSt w
        _ -> runSt stmts

runSt ((Abs.SExp _ exp):stmts) = eval exp >> runSt stmts

runSt ((Abs.Break _):stmts) = return $ Just RBreak

runSt ((Abs.Continue _):stmts) = return $ Just RContinue

runSt ((Abs.Print _ exp):stmts) = do
    v <- eval exp
    liftIO $ print v
    runSt stmts

runSt ((Abs.Assert p exp):stmts) = do
    (VBool v) <- eval exp
    if not v
        then throwEx p "Assertion error"
        else runSt stmts


--------------------------------------------------- MAIN FUNCTIONS ---------------------------------------------------

allocDefs :: [Abs.Def] -> IM Env
allocDefs [] = ask

allocDefs ((Abs.FunDef p idn args t b):defs) = do
    r <- ask
    loc <- alloc
    storeInsert loc (VFun args b (M.insert (convIdent idn) loc r))
    local (M.insert (convIdent idn) loc) (allocDefs defs)

allocDefs ((Abs.VarDef p t idn exp):defs) = do
    r <- ask
    loc <- alloc
    v <- eval exp
    storeInsert loc v
    local (M.insert (convIdent idn) loc) (allocDefs defs)


prepare :: [Abs.Def] -> IM ()
prepare defs = do
    r <- allocDefs defs
    v <- local (const r) (getValue "main")
    case v of
        Left e -> throwEx Nothing e
        Right (VFun [] (Abs.SBlock stmts _) _) -> do
            local (const r) (eval (Abs.EApp Nothing (Abs.Ident "main") []))
            return ()
        Right _ -> return ()


--------------------------------------------------- RUN FUNCTIONS ---------------------------------------------------

run :: Abs.Program -> IO ()
run (Abs.Prog p defs) = do
    x <- interpretProgram $ prepare defs
    case x of
        Left e -> die e
        _ -> return ()


interpretProgram :: IM () -> IO (Either Exception ())
interpretProgram x = runExceptT (runReaderT (evalStateT x (M.empty, 0)) M.empty)