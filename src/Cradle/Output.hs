{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Cradle.Output
  ( runAndGetOutput,
    Output (..),
    StdoutUntrimmed (..),
    StdoutTrimmed (..),
    Stderr (..),
  )
where

import Control.Arrow ((>>>))
import Cradle.ProcessConfiguration
import Data.ByteString.Char8
import Data.Char
import Data.Proxy
import GHC.Generics (Generic)
import System.Exit
import Prelude hiding (dropWhile)

runAndGetOutput :: forall output. (Output output) => ProcessConfiguration -> IO output
runAndGetOutput config = extractOutput <$> runProcess (configure (Proxy :: Proxy output) config)

class Output output where
  configure :: Proxy output -> ProcessConfiguration -> ProcessConfiguration
  extractOutput :: ProcessResult -> output

instance Output () where
  configure Proxy = id
  extractOutput = const ()

instance
  (Output a, Output b) =>
  Output (a, b)
  where
  configure Proxy =
    configure (Proxy :: Proxy a)
      >>> configure (Proxy :: Proxy b)
  extractOutput result =
    ( extractOutput result,
      extractOutput result
    )

instance
  (Output a, Output b, Output c) =>
  Output (a, b, c)
  where
  configure Proxy =
    configure (Proxy :: Proxy a)
      >>> configure (Proxy :: Proxy b)
      >>> configure (Proxy :: Proxy c)
  extractOutput result =
    ( extractOutput result,
      extractOutput result,
      extractOutput result
    )

instance
  (Output a, Output b, Output c, Output d) =>
  Output (a, b, c, d)
  where
  configure Proxy =
    configure (Proxy :: Proxy a)
      >>> configure (Proxy :: Proxy b)
      >>> configure (Proxy :: Proxy c)
      >>> configure (Proxy :: Proxy d)
  extractOutput result =
    ( extractOutput result,
      extractOutput result,
      extractOutput result,
      extractOutput result
    )

instance
  (Output a, Output b, Output c, Output d, Output e) =>
  Output (a, b, c, d, e)
  where
  configure Proxy =
    configure (Proxy :: Proxy a)
      >>> configure (Proxy :: Proxy b)
      >>> configure (Proxy :: Proxy c)
      >>> configure (Proxy :: Proxy d)
      >>> configure (Proxy :: Proxy e)
  extractOutput result =
    ( extractOutput result,
      extractOutput result,
      extractOutput result,
      extractOutput result,
      extractOutput result
    )

instance
  (Output a, Output b, Output c, Output d, Output e, Output f) =>
  Output (a, b, c, d, e, f)
  where
  configure Proxy =
    configure (Proxy :: Proxy a)
      >>> configure (Proxy :: Proxy b)
      >>> configure (Proxy :: Proxy c)
      >>> configure (Proxy :: Proxy d)
      >>> configure (Proxy :: Proxy e)
      >>> configure (Proxy :: Proxy f)
  extractOutput result =
    ( extractOutput result,
      extractOutput result,
      extractOutput result,
      extractOutput result,
      extractOutput result,
      extractOutput result
    )

newtype StdoutUntrimmed = StdoutUntrimmed
  { fromStdoutUntrimmed :: ByteString
  }
  deriving stock (Show, Eq, Ord, Generic)

instance Output StdoutUntrimmed where
  configure Proxy config = config {stdoutConfig = CaptureStream}
  extractOutput result =
    case stdout result of
      Nothing -> error "impossible: stdout not captured"
      Just stdout -> StdoutUntrimmed stdout

newtype StdoutTrimmed = StdoutTrimmed
  { fromStdoutTrimmed :: ByteString
  }
  deriving stock (Show, Eq, Ord, Generic)

instance Output StdoutTrimmed where
  configure Proxy config = config {stdoutConfig = CaptureStream}
  extractOutput result =
    let StdoutUntrimmed output = extractOutput result
     in StdoutTrimmed $ trim output
    where
      trim = dropWhile isSpace . dropWhileEnd isSpace

newtype Stderr = Stderr
  { fromStderr :: ByteString
  }
  deriving stock (Show, Eq, Ord, Generic)

instance Output Stderr where
  configure Proxy config = config {stderrConfig = CaptureStream}
  extractOutput result =
    case stderr result of
      Nothing -> error "impossible: stderr not captured"
      Just stderr -> Stderr stderr

instance Output ExitCode where
  configure Proxy config = config {throwOnError = False}
  extractOutput = exitCode
