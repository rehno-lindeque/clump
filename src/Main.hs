{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ImportQualifiedPost #-}
module Main where

import Control.Monad (unless)
import Data.ByteString (ByteString)
import Data.ByteString qualified as ByteString 
import Data.Maybe (fromMaybe)
import System.Environment (getArgs, getProgName)
import System.Exit (die)
import System.IO
import System.IO.Error qualified as IO
import Text.Read (readMaybe)
import Data.Foldable (for_)
import Control.Exception (catch)

-- | Default idle timeout in seconds
defaultInterval :: Int
defaultInterval = 2

-- | Parse a string like "5" or "5s" into an Int number of seconds.
parseInterval :: String -> Maybe Int
parseInterval str =
  case stripSuffix "s" str >>= readMaybe of
    Just n | n > 0 -> Just n
    _              -> readMaybe str >>= \n ->
                        if n > 0 then Just n else Nothing
  where
    stripSuffix :: String -> String -> Maybe String
    stripSuffix suf s =
      let ls = length s
          lf = length suf
      in  if lf < ls && drop (ls - lf) s == suf
            then Just (take (ls - lf) s)
            else Nothing

-- | Print usage and exit.
usage :: IO a
usage = do
  prog <- getProgName
  hPutStrLn stderr $ unlines
    [ "Usage: " ++ prog ++ " --interval <seconds>[s] [--prefix <string>] [--suffix <string>]"
    , ""
    , "Options:"
    , "  --interval <interval>   Time (in seconds) of no input before flushing."
    , "                          Suffix 's' for seconds is optional (e.g., 5 or 5s)."
    , "  --prefix <string>       String to print before each flushed block."
    , "  --suffix <string>       String to print after each flushed block."
    , "  --help                  Display this help and exit."
    ]
  ioError (userError "exit")

-- | Parse command-line arguments into (intervalSecs, prefix, suffix).
parseArgs :: IO (Int, Maybe String, Maybe String)
parseArgs = do
  args <- getArgs
  let go :: [String] -> Maybe Int -> Maybe String -> Maybe String -> IO (Int, Maybe String, Maybe String)
      go [] mi mp mx =
        let interval = fromMaybe defaultInterval mi
        in  return (interval, mp, mx)

      go ("--help" : _) _ _ _ = usage

      go ("--interval" : iv : rest) _ mp mx =
        case parseInterval iv of
          Just secs -> go rest (Just secs) mp mx
          Nothing   -> die $ "Invalid interval: " ++ iv

      go ("--prefix" : p : rest) mi _ mx = go rest mi (Just p) mx
      go ("--suffix" : x : rest) mi mp _ = go rest mi mp (Just x)

      go (opt : _) _ _ _ = die $ "Unrecognized option: " ++ opt

  go args Nothing Nothing Nothing


-- | Accumulate bytes until hWaitForInput times out, then flush.
accumulate :: Int -> Maybe String -> Maybe String -> ByteString -> IO ()
accumulate intervalSecs mPrefix mSuffix buf = do
  ready <- hWaitForInput stdin (intervalSecs * 1000) `catch` eofHandler
  if ready
    then do
      chunk <- ByteString.hGetSome stdin 4096
      if ByteString.null chunk
        then do
          -- EOF: flush any remaining buffer, then exit
          flush mPrefix mSuffix buf
        else
          -- Append to buffer and loop again
          accumulate intervalSecs mPrefix mSuffix (buf <> chunk)
    else do
      -- Timed out: flush and reset buffer
      unless (ByteString.null buf) $ 
        flush mPrefix mSuffix buf
      accumulate intervalSecs mPrefix mSuffix ByteString.empty
  where
    eofHandler e = 
      if IO.isEOFError e 
        then do
          pure True
        else ioError e


-- | Flush the buffer once with optional prefix/suffix.
flush :: Maybe String -> Maybe String -> ByteString -> IO ()
flush prefix suffix content = do
  for_ prefix putStr
  ByteString.hPut stdout content
  for_ suffix putStr

main :: IO ()
main = do
  -- Ensure stdin and stdout are in binary mode, no buffering delays
  hSetBinaryMode stdin True
  hSetBinaryMode stdout True
  hSetBuffering stdin NoBuffering
  hSetBuffering stdout NoBuffering

  (intervalSecs, mPrefix, mSuffix) <- parseArgs
  accumulate intervalSecs mPrefix mSuffix ByteString.empty

