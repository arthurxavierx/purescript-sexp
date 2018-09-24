module Test.QuickCheck.Laws.Data.Sexp
( checkAsSexp
) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Sexp (class AsSexp, fromSexp, toSexp)
import Effect (Effect)
import Effect.Console (log)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Arbitrary (class Arbitrary)
import Type.Proxy (Proxy)

checkAsSexp
  :: forall a
   . Arbitrary a
  => AsSexp a
  => Eq a
  => Proxy a
  -> Effect Unit
checkAsSexp _ = do
  log "Checking 'Losslessness' law for AsSexp"
  quickCheck \(x :: a) -> fromSexp (toSexp x) == Just x
