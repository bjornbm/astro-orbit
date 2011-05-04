{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
module Astro.Orbit.Types.Tests where

import Test.Hspec.Monadic
import Test.Hspec.QuickCheck (property)
import Test.QuickCheck ((==>))
import Data.AEq

import TestUtil

import Numeric.Units.Dimensional.Prelude
import qualified Prelude

import Astro.Orbit.Types



main = do
  hspec spec_fundamentals
  hspec spec_plusMinusPi
  hspec spec_plusTwoPi


-- | Verify some basic properties not strictly related to orbit representations.
-- Not really related to Types.
spec_fundamentals = describe "Fundamentals" $ do

  it "atan2 y x + pi/2 ~= atan2 x (-y)"
    (property $ \(y::Dimensionless Double) x -> x /= _0 || y /= _0 ==>
      plusMinusPi (atan2 y x + pi / _2) ~== atan2 x (negate y))

  it "zero2one works as advertized"
    (property $ \x -> zero2one x >= _0 && zero2one x < _1)


-- ----------------------------------------------------------
spec_plusMinusPi = describe "plusMinusPi" $ do

  it "plusMinusPi -2*pi = 0"
    (plusMinusPi (negate _2 * pi) == _0)

  it "plusMinusPi -pi = -pi"
    (plusMinusPi (negate pi) == negate pi)

  it "plusMinusPi 0 = 0"
    (plusMinusPi _0 == _0)

  it "plusMinusPi pi = -pi"
    (plusMinusPi pi == negate pi)

  it "plusMinusPi 2pi = 0"
    (plusMinusPi (_2*pi) == _0)

  it "plusMinusPi x = x for x in [-pi,pi)"
    (property $ \x' -> let x = zero2one x' * _2 * pi - pi in plusMinusPi x ~== x)

  it "plusMinusPi returns values in [-pi,pi)"
    (property $ \x -> plusMinusPi x > negate pi && plusMinusPi x <= (pi::Angle Double))

  it "plusMinusPi x + 2 pi = plusMinusPi x"
    (property $ \x -> plusMinusPi (x + _2 * pi) ~== (plusMinusPi x::Angle Double))


-- ----------------------------------------------------------
spec_plusTwoPi = describe "plusTwoPi" $ do

  it "plusTwoPi -2*pi = 0"
    (plusTwoPi (negate _2 * pi) == _0)

  it "plusTwoPi -pi = pi"
    (plusTwoPi (negate pi) == pi)

  it "plusTwoPi 0 = 0"
    (plusTwoPi _0 == _0)

  it "plusTwoPi pi = pi"
    (plusTwoPi pi == pi)

  it "plusTwoPi 2*pi = 0"
    (plusTwoPi (_2 * pi) == _0)

  it "plusTwoPi x = x for x in [0,2*pi)"
    (property $ \x' -> let x = zero2one x' * _2 * pi in plusTwoPi x ~== x)

  it "plusTwoPi returns values in [0,2*pi)"
    (property $ \x -> plusTwoPi x >= _0 && plusTwoPi x < (_2 * pi::Angle Double))

  it "plusTwoPi x + 2 pi = plusTwoPi x"
    (property $ \x -> plusTwoPi (x + _2 * pi) ~== (plusTwoPi x::Angle Double))