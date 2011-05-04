{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
module Astro.Orbit.Conversion.Tests where

import Test.Hspec.Monadic
import Test.Hspec.QuickCheck (property)
import Test.QuickCheck ((==>))
import Data.AEq

import TestUtil

import Numeric.Units.Dimensional.Prelude
import Numeric.Units.Dimensional.LinearAlgebra
import qualified Prelude

import Astro.Orbit.COE
import Astro.Orbit.MEOE
import Astro.Orbit.SV
import Astro.Orbit.Conversion
import Astro.Orbit.Types



main = do
  hspec spec_sv2coe
  hspec spec_coe2meoe2coe
  hspec spec_sv2coe2meoe2sv
  hspec spec_coe2coeM


-- ----------------------------------------------------------
spec_coe2meoe2coe = describe "coe2meoe2coe" $ do

  it "Converting a COE to a MEOE and back to a COE does not change it"
    (coe2vec testCOE0 ~== (coe2vec . meoe2coe . coe2meoe) testCOE0)

  it "Converting a COE to a MEOE and back to a COE does not change it"
    (coe2vec testCOE1 ~== (coe2vec . meoe2coe . coe2meoe) testCOE1)

  it "Converting a COE (generated from a random SV) to a MEOE and back to a COE does not change it"
    (property $ \mu r v -> let coe = sv2coe mu r v :: COE True Double; i = inc coe
      in mu > 0*~(meter^pos3/second^pos2) && i /= pi && i /= negate pi
      ==> coe2vec coe ~== (coe2vec . meoe2coe . coe2meoe) coe
    )


-- ----------------------------------------------------------
spec_sv2coe2meoe2sv = describe "sv2coe2meoe2sv" $ do

  it "Converting a prograde SV to a MEOE and back to a SV does not change it"
    ((meoe2sv . coe2meoe . sv2coe') testSV0 ~== testSV0)

  it "Converting a retrograde SV to a MEOE and back to a SV does not change it – surprisingly!"
    ((fudgeSV . meoe2sv . coe2meoe . sv2coe') testSV0R ~== fudgeSV testSV0R)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it"
    ((fudgeSV . meoe2sv . coe2meoe . sv2coe') testSV1 ~== fudgeSV testSV1)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it"
    ((meoe2sv . coe2meoe . sv2coe') testSV2 ~== testSV2)

  it "Converting a retrograde SV to a MEOE and back to a SV does not change it – surprisingly!"
    ((meoe2sv . coe2meoe . sv2coe') testSV2R ~== testSV2R)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it significantly"
    ((fudgeSV . meoe2sv . coe2meoe . sv2coe') testSV3 ~== fudgeSV testSV3)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it significantly"
    ((fudgeSV . meoe2sv . coe2meoe . sv2coe') testSV4 ~== fudgeSV testSV4)

  it "Converting a random SV to a MEOE and back to a SV does not change it"
    (property $ \mu r v -> let coe = sv2coe mu r v :: COE True Double; i = inc coe
      in mu > 0*~(meter^pos3/second^pos2) && i /= pi && i /= negate pi
      ==> (r,v) ~== (meoe2sv $ coe2meoe $ sv2coe mu r v)
    )


-- ----------------------------------------------------------
spec_sv2coe = describe "sv2coe" $ do

  it "Inclination of prograde orbit in xy-plane is zero"
    (inc (sv2coe' testSV0) == _0)

  it "Inclination of retrograde orbit in xy-plane is pi"
    (inc (sv2coe' testSV0R) == pi)

  it "Inclination of orbit in xy-plane is zero (prograde) or pi (retrograde)"
    (property $ \mu x y vx vy -> mu > 0 *~ (meter ^ pos3 / second ^ pos2) ==>
      let r =  x <:  y <:. 0 *~ meter
          v = vx <: vy <:. 0 *~ mps
          i = inc (sv2coe mu r v) :: Angle Double
      in i == _0 || i == pi
    )

  it "RAAN of prograde orbit in xy-plane is pi"
    (raan (sv2coe' testSV0) == pi)

  it "RAAN of retrograde orbit in xy-plane is pi"
    (raan (sv2coe' testSV0R) == pi)

  it "RAAN of orbit in xy-plane is ±pi or zero"
    (property $ \mu x y vx vy -> mu > 0 *~ (meter ^ pos3 / second ^ pos2) ==>
      let r =  x <:  y <:. 0 *~ meter
          v = vx <: vy <:. 0 *~ mps
          ra = raan (sv2coe mu r v) :: Angle Double
      in ra ~== pi || ra ~== negate pi || ra == _0
    )

  it "For prograde orbit at perigee trueAnomaly = 0"
    (anomaly (sv2coe' testSV0) == Anom _0)

  it "For retrograde orbit at perigee trueAnomaly = 0"
    (anomaly (sv2coe' testSV0R) == Anom _0)

  it "For prograde orbit at apogee trueAnomaly = -pi"
    (anomaly (sv2coe' testSV1) == Anom (negate pi))

  it "For retrograde orbit at apogee trueAnomaly = pi"
    (anomaly (sv2coe' testSV1R) == Anom pi)

  it "Prograde orbit with AN, perigee, and anomaly coinciding on +x"
    (let coe = sv2coe' testSV2
      in raan coe == _0 && aop coe == _0 && anomaly coe == Anom _0
    )

  it "Retrograde orbit with AN, perigee, and anomaly coinciding on +x"
    (let coe = sv2coe' testSV2R
      in raan coe == _0 && aop coe == _0 && anomaly coe == Anom _0
    )

  it "Prograde orbit with DN, perigee, and anomaly coinciding on +x"
    (let coe = sv2coe' testSV3
      in raan coe == negate pi && aop coe == pi && anomaly coe == Anom _0
    )

  it "Prograde orbit with DN, apogee, and anomaly coinciding on +x"
    (let coe = sv2coe' testSV4
      in raan coe == negate pi && aop coe ~== _0 && anomaly coe == Anom pi
    )


-- ----------------------------------------------------------
spec_coe2coeM = describe "coe2meoe2coe" $ do

  it "Converting a COE to a COEm and back to a COE does not change it"
    (coe2vec testCOE0 ~== (coe2vec . coeM2coe . coe2coeM) testCOE0)

  it "Converting a COE to a COEm and back to a COE does not change it"
    (coe2vec testCOE1 ~== (coe2vec . coeM2coe . coe2coeM) testCOE1)

  {-
  -- This doesn't work for hyperbolic orbits(?).
  it "Converting a COE (generated from a random SV) to a COEm and back to a COE does not change it"
    (property $ \mu r v -> let coe = sv2coe mu r v :: COE Double; i = inc coe
      in mu > 0*~(meter^pos3/second^pos2) && i /= pi && i /= negate pi
      ==> coe2vec coe ~== (coe2vec . coeM2coe . coe2coeM) coe
    )
  -}

-- Convenience and utility functions.

mps = meter / second

-- | From Wikipedia.
mu_Earth = 398600.4418 *~ (kilo meter ^ pos3 / second ^ pos2)

-- | Convert an SV to a COE assuming Earth is central body.
sv2coe' = uncurry (sv2coe mu_Earth)

-- | Fudge a state vector to avoid comparing to zero elements
-- where the deviation may be greated than epsilon.
fudgeSV :: SV Double -> SV Double
fudgeSV (r,v) = (r >+< (a<:a<:.a), v >+< (b<:b<:.b))
  where
    a = vNorm r / (1e-9*~one)
    b = vNorm v / (1e-9*~one)


-- Test elements.

testCOE0 :: COE True Double
testCOE0 = COE
  { mu = mu_Earth
  , slr = 10000 *~ kilo meter
  , ecc = 0 *~ one
  , inc = 0 *~ degree
  , aop = 0 *~ degree
  , raan = 0 *~ degree
  , anomaly = Anom $ 0 *~ degree
  }

testCOE1 :: COE True Double
testCOE1 = COE
  { mu = mu_Earth
  , slr = 24000 *~ kilo meter
  , ecc = 0.01 *~ one
  , inc = 15 *~ degree
  , aop = (-105) *~ degree -- 255 *~ degree
  , raan = 35 *~ degree
  , anomaly = Anom $ 10 *~ degree
  }

testSV0 = (42156 *~ kilo meter <:    0 *~ meter <:. 0 *~ meter
          ,    0 *~ mps        <: 3075 *~ mps   <:. 0 *~ mps
          )

testSV0R = (42156 *~ kilo meter <:       0 *~ meter <:. 0 *~ meter
           ,    0 *~ mps        <: (-3075) *~ mps   <:. 0 *~ mps
           )

testSV1 = (42156 *~ kilo meter <:    0 *~ meter <:. 0 *~ meter
          ,    0 *~ mps        <: 3000 *~ mps   <:. 0 *~ mps
          )

testSV1R = (42156 *~ kilo meter <:       0 *~ meter <:. 0 *~ meter
           ,    0 *~ mps        <: (-3000) *~ mps   <:. 0 *~ mps
           )

testSV2 = ( 42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter
          , 0 *~ mps <: 3075 *~ mps <:. 1 *~ mps
          )
testSV2R = ( 42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter
           , 0 *~ mps <: (-3075) *~ mps <:. 1 *~ mps
           )

testSV3 = ( 42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter
          , 0 *~ mps <: 3075 *~ mps <:. (-1) *~ mps
          )

testSV4 = ( 42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter
          , 0 *~ mps <: 3000 *~ mps <:. (-1) *~ mps
          )