{-|
Module      : plutus-horrocubes-counter.
Description : Application to generate the plutus script of the counter contract.
License     : Apache-2.0
Maintainer  : angel.castillob@protonmail.com
Stability   : experimental
-}

-- LANGUAGE EXTENSIONS --------------------------------------------------------

{-# LANGUAGE OverloadedStrings #-}

-- IMPORTS --------------------------------------------------------------------

import Cardano.Api                     hiding (TxId)
import Data.String                     (IsString (..))
import Ledger
import Ledger.Bytes                    (getLedgerBytes)
import Prelude
import System.Environment              (getArgs)
import Data.Hex
import qualified Plutus.V1.Ledger.Api  as Plutus
import qualified Data.ByteString.Short as SBS
import           Ledger.Value          as Value
import Horrocubes.Counter

-- DEFINITIONS ----------------------------------------------------------------

-- | Application entry point.
-- The user must provide four arguments: The currency symbol, the token name, the publick key hash and the output path.
main :: IO ()
main = do
    [currencySymbol', tokenName', publicKey', filePath] <- getArgs
    let nft       = Value.AssetClass ( toCurrencySymbol currencySymbol', toTokenName tokenName')
        publicKey = toPublicKeyHash publicKey'

    counterContractResult <- writeFileTextEnvelope filePath Nothing $ counterScript publicKey nft
    case counterContractResult of
        Left err -> print $ displayError err
        Right () -> putStrLn $ "wrote NFT policy to file " ++ filePath

    writePlutusScript $ counterScriptShortBs (CounterParameter {identityNft = nft, ownerPkh = publicKey})

-- | Displays the execution budget.
writePlutusScript :: SBS.ShortByteString -> IO ()
writePlutusScript scriptSBS =
  do
  case Plutus.defaultCostModelParams of
        Just m ->
          let (logout, e) = Plutus.evaluateScriptCounting Plutus.Verbose m scriptSBS []
          in do print ("Log output" :: String) >> print logout
                case e of
                  Left evalErr -> print ("Eval Error" :: String) >> print evalErr
                  Right exbudget -> print ("Ex Budget" :: String) >> print exbudget
        Nothing -> error "defaultCostModelParams failed"

-- | Creates a token name from a byte array.
toCurrencySymbol :: String -> CurrencySymbol
toCurrencySymbol symbol = CurrencySymbol { unCurrencySymbol = getLedgerBytes $ fromString $ hex symbol }

-- | Creates a token name from a byte array.
toTokenName :: String -> TokenName
toTokenName tn = TokenName { unTokenName = getLedgerBytes $ fromString $ hex tn }

-- | Creates a token name from a byte array.
toPublicKeyHash :: String -> PubKeyHash
toPublicKeyHash pkh = PubKeyHash { getPubKeyHash = getLedgerBytes $ fromString $ hex pkh }