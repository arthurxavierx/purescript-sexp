module Test.Main
( main
, GenericRepTest(..)
) where

import Prelude

import Benchmark (benchmark)
import Benchmark.Plot.Gnuplot (gnuplot)
import Data.Argonaut.Core as AC
import Data.Argonaut.Parser as AP
import Data.Either (Either)
import Data.Generic.Rep as Rep
import Data.List ((:), List(..))
import Data.Maybe (Maybe(..))
import Data.Sexp (class AsSexp, class FromSexp, class ToSexp, Sexp(..), fromString, genericFromSexp, genericToSexp, toString)
import Data.Tuple (Tuple)
import Effect (Effect)
import Effect.Console (log)
import Test.QuickCheck (quickCheck')
import Test.QuickCheck.Arbitrary (class Arbitrary, arbitrary)
import Test.QuickCheck.Gen as Gen
import Test.QuickCheck.Laws.Data.Sexp (checkAsSexp)
import Type.Proxy (Proxy(..))

data GenericRepTest
  = A
  | B String
  | C {x :: Int, y :: Number}
  | D GenericRepTest

derive instance eqGenericRepTest :: Eq GenericRepTest
derive instance genericRepGenericRepTest :: Rep.Generic GenericRepTest _
instance toSexpGenericRepTest :: ToSexp GenericRepTest where toSexp a = genericToSexp a
instance fromSexpGenericRepTest :: FromSexp GenericRepTest where fromSexp a = genericFromSexp a
instance asSexpGenericRepTest :: AsSexp GenericRepTest

instance arbitraryGenericRepTest :: Arbitrary GenericRepTest where
  arbitrary = Gen.sized arbitrary'
    where
    arbitrary' 0 = pure A
    arbitrary' 1 = B <$> arbitrary
    arbitrary' n
      | n `mod` 2 == 0 = (\x y -> C {x, y}) <$> arbitrary <*> arbitrary
      | otherwise      = D <$> arbitrary' (n / 2)

main :: Effect Unit
main = do
  checkAsSexp (Proxy :: Proxy Sexp)
  checkAsSexp (Proxy :: Proxy Unit)
  checkAsSexp (Proxy :: Proxy Boolean)
  checkAsSexp (Proxy :: Proxy Char)
  checkAsSexp (Proxy :: Proxy Int)
  checkAsSexp (Proxy :: Proxy Number)
  checkAsSexp (Proxy :: Proxy String)
  checkAsSexp (Proxy :: Proxy (Array Sexp))
  checkAsSexp (Proxy :: Proxy Ordering)
  checkAsSexp (Proxy :: Proxy (List Sexp))
  checkAsSexp (Proxy :: Proxy (Maybe Sexp))
  checkAsSexp (Proxy :: Proxy (Tuple Int Sexp))
  checkAsSexp (Proxy :: Proxy (Either Int Sexp))
  checkAsSexp (Proxy :: Proxy GenericRepTest)

  log "Checking toString and fromString"
  quickCheck' 1000 \sexp -> Just sexp == fromString (toString sexp)

  log "Benchmarking against JSON"
  benchJSON <- benchmark (pure <<< genJSON) \j -> pure $ AP.jsonParser (AC.stringify j)
  benchSexp <- benchmark (pure <<< genSexp) \s -> pure $ fromString (toString s)
  log $ gnuplot [ {title: "JSON", benchmark: benchJSON}
                , {title: "Sexp", benchmark: benchSexp}
                ]

genJSON :: Int -> AC.Json
genJSON 0 = AC.fromString "hello world"
genJSON n = AC.fromArray $ go (n - 1)
  where
  go 0 = []
  go n' = [genJSON (n' / 2)] <> go (n' / 2)

genSexp :: Int -> Sexp
genSexp 0 = Atom "hello world"
genSexp n = List $ go (n - 1)
  where
  go 0 = Nil
  go n' = genSexp (n' / 2) : go (n' / 2)
