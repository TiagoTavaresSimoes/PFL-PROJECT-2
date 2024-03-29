-- PFL 2023/24 - Haskell practical assignment quickstart
import Data.Char (isDigit, isAlpha, isSpace)
import Data.List (intercalate, sortBy)
import Data.Function (on)
import Data.Ord (comparing)
import Data.Maybe (fromMaybe)

-- Part 1

-- Do not modify our definition of Inst and Code
data Inst =
  Push Integer | Add | Mult | Sub | Tru | Fals | Equ | Le | And | Neg | Fetch String | Store String | Noop |
  Branch Code Code | Loop Code Code
  deriving (Eq, Show)
type Code = [Inst]

-- define Stack and State types
type Stack = [Either Integer Bool]
type State = [(String, Either Integer Bool)]

-- createEmptyStack :: Stack
createEmptyStack :: Stack
createEmptyStack = []

-- Function to convert a stack element (either integer bool) to string
eitherToStr :: Either Integer Bool -> String
eitherToStr (Left i) = show i
eitherToStr (Right b) = show b

-- stack2Str :: Stack -> String
stack2Str :: Stack -> String
stack2Str stack = "[" ++ intercalate "," (map eitherToStr stack) ++ "]"

-- createEmptyState :: State
createEmptyState :: State
createEmptyState = []

-- stateElemToStr :: Function to convert a state element (key-value pair) to string
stateElemToStr :: (String, Either Integer Bool) -> String
stateElemToStr (key, Left i) = key ++ "=" ++ show i
stateElemToStr (key, Right b) = key ++ "=" ++ show b

-- state2Str :: State -> String
state2Str :: State -> String
state2Str state = intercalate "," (map stateElemToStr (sortBy (comparing fst) state))

-- run :: (Code, Stack, State) -> (Code, Stack, State)
run :: (Code, Stack, State) -> (Code, Stack, State)
run ([], stack, state) = ([], stack, state)  -- No code to run
run (inst:rest, stack, state) =
  case inst of
    Push n -> run (rest, Left n : stack, state)
    Add -> case stack of
              (Left b : Left a : xs) -> run (rest, Left (a + b) : xs, state)
              _ -> error "Add expects two integers on top of the stack"
    Mult -> case stack of
              (Left b : Left a : xs) -> run (rest, Left (a * b) : xs, state)
              _ -> error "Mult expects two integers on top of the stack"
    Sub -> case stack of
              (Left b : Left a : xs) -> run (rest, Left (b - a) : xs, state)
              _ -> error "Sub expects two integers on top of the stack"
    Tru -> run (rest, Right True : stack, state)
    Fals -> run (rest, Right False : stack, state)
    Equ -> case stack of
              (Left b : Left a : xs) -> run (rest, Right (a == b) : xs, state)
              (Right b : Right a : xs) -> run (rest, Right (a == b) : xs, state)
              _ -> error "Equ expects two values of the same type on top of the stack"
    Le -> case stack of
          (Left a : Left b : xs) -> run (rest, Right (a <= b) : xs, state)
          _ -> error "Le expects two integers on top of the stack" 
    And -> case stack of
              (Right b : Right a : xs) -> run (rest, Right (a && b) : xs, state)
              _ -> error "And expects two booleans on top of the stack"
    Neg -> case stack of
              (Right a : xs) -> run (rest, Right (not a) : xs, state)
              _ -> error "Neg expects a boolean on top of the stack"
    Fetch varName -> case lookup varName state of
                        Just val -> run (rest, val : stack, state)
                        Nothing -> error ("Variable not found: " ++ varName)
    Store varName -> case stack of
                    (v : xs) -> let newState = if any ((== varName) . fst) state
                                            then map (\(k, val) -> if k == varName then (k, v) else (k, val)) state
                                            else (varName, v) : state
                                in run (rest, xs, newState)
                    [] -> error "Store expects a value on the stack"
    Noop -> run (rest, stack, state)
    Branch code1 code2 -> case stack of
                              (Right True : xs) -> run (code1 ++ rest, xs, state)
                              (Right False : xs) -> run (code2 ++ rest, xs, state)
                              _ -> error "Branch expects a boolean on top of the stack"
    Loop code1 code2 -> 
      let loopedCode = code1 ++ [Branch (code2 ++ [Loop code1 code2]) [Noop]]
      in run (loopedCode ++ rest, stack, state)

-- To help you test your assembler
testAssembler :: Code -> (String, String)
testAssembler code = (stack2Str stack, state2Str state)
  where (_,stack,state) = run(code, createEmptyStack, createEmptyState)

-- Examples:
-- testAssembler [Push 10,Push 4,Push 3,Sub,Mult] == ("-10","")
-- testAssembler [Fals,Push 3,Tru,Store "var",Store "a", Store "someVar"] == ("","a=3,someVar=False,var=True")
-- testAssembler [Fals,Store "var",Fetch "var"] == ("False","var=False")
-- testAssembler [Push (-20),Tru,Fals] == ("False,True,-20","")
-- testAssembler [Push (-20),Tru,Tru,Neg] == ("False,True,-20","")
-- testAssembler [Push (-20),Tru,Tru,Neg,Equ] == ("False,-20","")
-- testAssembler [Push (-20),Push (-21), Le] == ("True","")
-- testAssembler [Push 5,Store "x",Push 1,Fetch "x",Sub,Store "x"] == ("","x=4")
-- testAssembler [Push 10,Store "i",Push 1,Store "fact",Loop [Push 1,Fetch "i",Equ,Neg] [Fetch "i",Fetch "fact",Mult,Store "fact",Push 1,Fetch "i",Sub,Store "i"]] == ("","fact=3628800,i=1")

-- Part 2

-- TODO: Define the types Aexp, Bexp, Stm and Program

data Aexp = 
    Const Integer          -- Constant
    | Var String           -- Variable
    | Add2 Aexp Aexp        -- Addition
    | Sub2 Aexp Aexp        -- Subtraction
    | Mult2 Aexp Aexp       -- Multiplication
    deriving (Show)        -- Adicionando Show aqui

data Bexp = 
    BConst Bool            -- Boolean Constant
    | Eq2 Aexp Aexp         -- Equality
    | Le2 Aexp Aexp         -- Less or Equal
    | And2 Bexp Bexp        -- Logical And
    | Neg2 Bexp             -- Negation
    | BEq Bexp Bexp         -- Comparação de booleanos
    deriving (Show)        -- Adicionando Show aqui

data Stm = 
    Assign String Aexp     -- x := a
    | Seq2 Stm Stm          -- instr1 ; instr2
    | If2 Bexp Stm Stm      -- if b then s1 else s2
    | While2 Bexp Stm       -- while b do s

-- compA :: Aexp -> Code
compA :: Aexp -> Code
compA (Const n)    = [Push n]
compA (Var x)      = [Fetch x]
compA (Add2 a1 a2) = compA a1 ++ compA a2 ++ [Add]
compA (Sub2 a1 a2) = compA a1 ++ compA a2 ++ [Sub]
compA (Mult2 a1 a2) = compA a1 ++ compA a2 ++ [Mult]


-- compB :: Bexp -> Code
compB :: Bexp -> Code
compB (BConst b)      = [if b then Tru else Fals]
compB (Eq2 a1 a2)     = compA a2 ++ compA a1 ++ [Equ]
compB (BEq b1 b2)     = compB b2 ++ compB b1 ++ [Equ]  -- Adicionando comparação de booleanos
compB (Le2 a1 a2)     = compA a2 ++ compA a1 ++ [Le]
compB (And2 b1 b2)    = compB b2 ++ compB b1 ++ [And]
compB (Neg2 b)        = compB b ++ [Neg]


-- compile :: Program -> Code
compileStm :: Stm -> Code
compileStm (Assign x a) = compA a ++ [Store x]
compileStm (Seq2 s1 s2) = compileStm s1 ++ compileStm s2
compileStm (If2 b s1 s2) = compB b ++ [Branch (compileStm s1) (compileStm s2)]
compileStm (While2 b s) = [Loop (compB b ++ [Neg]) (compileStm s)]

-- compile :: [Stm] -> Code
compile :: [Stm] -> Code
compile [] = []
compile (stm:stms) = compileStm stm ++ compile stms


-- lexer that splits the input string into tokens
lexer :: String -> [String]
lexer = words . map (\c -> if c `elem` [';', '(', ')'] then ' ' else c)

parseAexp :: [String] -> (Aexp, [String])
parseAexp (var:"-":n:rest)
    | isAlpha (head var) && all isDigit n = (Sub2 (Var var) (Const (read n)), rest)
parseAexp (n:rest)
    | all isDigit n = (Const (read n), rest)
    | otherwise     = (Var n, rest)
parseAexp (op:a1:a2:rest)
    | op `elem` ["+", "-", "*"] =
        let (exp1, rest1) = parseAexp [a1]
            (exp2, rest2) = parseAexp (a2:rest)
            operation = case op of
                "+" -> Add2
                "-" -> Sub2
                "*" -> Mult2
            in (operation exp1 exp2, rest2)
    | otherwise = error $ "Unrecognized operator in parseAexp: " ++ op

parseBexp :: [String] -> (Bexp, [String])
parseBexp tokens = 
    let (bexp1, rest1) = parseSimpleBexp tokens
    in case rest1 of
        ("and":rest2) -> 
            let (bexp2, rest3) = parseBexp rest2
            in (And2 bexp1 bexp2, rest3)
        ("=":rest2) -> 
            let (bexp2, rest3) = parseBexp rest2
            in (BEq bexp1 bexp2, rest3)
        _ -> (bexp1, rest1)

parseSimpleBexp :: [String] -> (Bexp, [String])
parseSimpleBexp tokens = case tokens of
    -- Handle boolean constants
    ("True":rest) -> (BConst True, rest)
    ("False":rest) -> (BConst False, rest)

    -- Handle negation
    ("not":rest) -> 
        let (bexp, rest1) = parseSimpleBexp rest
        in (Neg2 bexp, rest1)

    -- Handle simple comparisons
    a1:op:a2:rest ->
        let (exp1, _) = parseAexp [a1]
            (exp2, rest2) = parseAexp [a2]
            bexp = case op of
                "==" -> Eq2 exp1 exp2
                "<=" -> Le2 exp1 exp2
                _ -> error $ "Unrecognized operator in parseSimpleBexp: " ++ op
        in (bexp, rest ++ rest2)
    -- Handle parentheses
    ("(":rest) -> 
        let (bexp, ")":rest') = parseSimpleBexp rest
        in (bexp, rest')

    -- Unrecognized patterns
    xs -> error $ "Unrecognized pattern in parseSimpleBexp: " ++ show xs


parseStm :: [String] -> (Stm, [String])
parseStm [] = error "No more tokens"
parseStm (";":rest) = parseStm rest
parseStm (var:":=":rest) =
    let (exp, rest') = parseAexp rest
    in (Assign var exp, dropWhile (== ";") rest')
parseStm ("if":rest) =
    let (bexp, restAfterBexp) = parseBexp rest
    in case span (/= "else") restAfterBexp of
        (thenPart, "else":elsePart) ->
            let (thenStm, _) = parseStm thenPart
                (elseStm, restElse) = parseStm elsePart
            in (If2 bexp thenStm elseStm, dropWhile (== ";") restElse)
        _ -> error "Syntax error in if-then-else statement"
parseStm ("while":rest) =
    let (bexp, restAfterBexp) = parseBexp rest
        (stm, rest') = parseStm restAfterBexp
    in (While2 bexp stm, dropWhile (== ";") rest')
parseStm l = error $ "Unrecognized statement: " ++ show l

parseStatements :: [String] -> ([Stm], [String])
parseStatements [] = ([], [])
parseStatements tokens = 
    let (stm, restTokens) = parseStm tokens
        (stms, finalTokens) = parseStatements restTokens
    in (stm : stms, finalTokens)


-- parse :: String -> Program
parse :: String -> [Stm]
parse input = 
    let tokens = lexer input
        (stms, _) = parseStatements tokens
    in stms

-- To help you test your parser
testParser :: String -> (String, String)
testParser programCode = (stack2Str stack, state2Str state)
  where (_,stack,state) = run(compile (parse programCode), createEmptyStack, createEmptyState)


main :: IO ()
main = do
    let (stackResult, stateResult) = testAssembler [Push 10,Store "i",Push 1,Store "fact",Loop [Push 1,Fetch "i",Equ,Neg] [Fetch "i",Fetch "fact",Mult,Store "fact",Push 1,Fetch "i",Sub,Store "i"]]
    putStrLn $ "Testing:" ++ show (stackResult, stateResult)



-- Examples:
-- testParser "x := 5; x := x - 1;" == ("","x=4")
-- testParser "if (not True and 2 <= 5 = 3 == 4) then x :=1 else y := 2" == ("","y=2")
-- testParser "x := 42; if x <= 43 then x := 1; else (x := 33; x := x+1;)" == ("","x=1")
-- testParser "x := 42; if x <= 43 then x := 1; else x := 33; x := x+1;" == ("","x=2")
-- testParser "x := 42; if x <= 43 then x := 1; else x := 33; x := x+1; z := x+x;" == ("","x=2,z=4")
-- testParser "x := 2; y := (x - 3)*(4 + 2*3); z := x +x*(2);" == ("","x=2,y=-10,z=6")
-- testParser "i := 10; fact := 1; while (not(i == 1)) do (fact := fact * i; i := i - 1;);" == ("","fact=3628800,i=1")