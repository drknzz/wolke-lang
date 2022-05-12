module Main where

import System.Environment ( getArgs )
import System.Exit ( exitSuccess, die )

import Gen.AbsWolke ( Program )
import Gen.LayoutWolke ( resolveLayout )
import Gen.ParWolke ( pProgram, myLexer )

import qualified TypeChecker as TC
import qualified Interpreter as I


run :: String -> IO ()
run content = 
    case result of
        Left err -> die err
        Right prog -> runTypeChecker prog >> I.run prog
    where
        tokens = resolveLayout True $ myLexer content
        result = pProgram tokens


runTypeChecker :: Program -> IO ()
runTypeChecker prog = do
    case TC.run prog of
        Left err -> die err
        _ -> return ()


usage :: IO ()
usage = do
    putStrLn $ unlines
        [ "usage: Call with one of the following arguments:"
        , "  --help          Show this help message."
        , "  (no arguments)  Interpret stdin."
        , "  (path to file)  Interpret content of a file."
        ]


runStdin :: IO ()
runStdin = getContents >>= run


runFile :: FilePath -> IO ()
runFile path = readFile path >>= run


main :: IO ()
main = do
    args <- getArgs
    case args of
        ["--help"] -> usage
        [] -> runStdin
        (path:_) -> runFile path