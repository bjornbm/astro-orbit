{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
module Astro.Orbit.ConversionSpec where

import Test.Hspec
import Test.QuickCheck (property, (==>))
import Data.AEq

import TestUtil
import TestInstances

import Numeric.Units.Dimensional.Prelude
import Numeric.Units.Dimensional.LinearAlgebra
import qualified Prelude

import Astro.Coords (ECI)
import Astro.Orbit.COE
import Astro.Orbit.MEOE (MEOE (..), eccentricity2)
import Astro.Orbit.SV
import Astro.Orbit.Conversion
import Astro.Orbit.Types hiding (ecc)


main = hspec spec
spec = do
  spec_sv2coe
  spec_coe2meoe2coe
  spec_sv2coe2meoe2sv
  spec_coe2coeM
  spec_meoe2meoeM


type SVD = SV Double
type CT = COE True Double
type MT = MEOE True Double

-- ----------------------------------------------------------
spec_coe2meoe2coe = describe "coe2meoe2coe" $ do

  it "Converting a COE to a MEOE and back to a COE does not change it"
    (testCOE0 ~== (meoe2coe . coe2meoe) testCOE0)

  it "Converting a COE to a MEOE and back to a COE does not change it"
    (testCOE1 ~== (meoe2coe . coe2meoe) testCOE1)

  it "Converting a COE (generated from a random SV) to a MEOE and back to a COE does not change it"
    (property $ \mu sv -> let coe = sv2coe mu sv :: CT in
      mu > _0 && orbmom sv /= _0
      ==> coe ~== (meoe2coe . coe2meoe) coe
    )


-- ----------------------------------------------------------

spec_sv2coe2meoe2sv = describe "sv2coe2meoe2sv" $ do

  it "Converting a random SV to a MEOE and back to a SV does not change it"
    (property $ \mu (sv :: SVD) -> mu > _0 && orbmom sv /= _0 ==>
      (meoe2sv . sv2meoe mu) sv ~== sv)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it"
    ((meoe2sv . sv2meoe mu_Earth) testSV0 ~== testSV0)

  it "Converting a retrograde SV to a MEOE and back to a SV does not change it – surprisingly!"
    ((fudgeSV . meoe2sv . sv2meoe mu_Earth) testSV0R ~== fudgeSV testSV0R)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it"
    ((fudgeSV . meoe2sv . sv2meoe mu_Earth) testSV1 ~== fudgeSV testSV1)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it"
    ((meoe2sv . sv2meoe mu_Earth) testSV2 ~== testSV2)

  it "Converting a retrograde SV to a MEOE and back to a SV does not change it – surprisingly!"
    ((meoe2sv . sv2meoe mu_Earth) testSV2R ~== testSV2R)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it significantly"
    ((fudgeSV . meoe2sv . sv2meoe mu_Earth) testSV3 ~== fudgeSV testSV3)

  it "Converting a prograde SV to a MEOE and back to a SV does not change it significantly"
    ((fudgeSV . meoe2sv . sv2meoe mu_Earth) testSV4 ~== fudgeSV testSV4)


-- ----------------------------------------------------------
spec_sv2coe = describe "sv2coe" $ do

  it "Converting a SV to a COE and back to a SV does not change it"
    (property $ \mu (sv :: SVD) -> mu > _0 && orbmom sv > _0 ==>
      (coe2sv . sv2coe mu) sv ~== sv)

  it "Inclination of prograde orbit in xy-plane is zero"
    (inc (sv2coe mu_Earth testSV0) == _0)

  it "Inclination of retrograde orbit in xy-plane is pi"
    (inc (sv2coe mu_Earth testSV0R) == pi)

  it "Inclination of orbit in xy-plane is zero (prograde) or pi (retrograde)"
    (property $ \mu x y vx vy -> mu > _0 ==>
      let r =  x <:  y <:. 0 *~ meter
          v = vx <: vy <:. 0 *~ mps
          i = inc (sv2coe mu (sv r v)) :: Angle Double
      in i == _0 || i == pi
    )

  it "RAAN of prograde orbit in xy-plane is pi"
    (raan (sv2coe mu_Earth testSV0) == pi)

  it "RAAN of retrograde orbit in xy-plane is pi"
    (raan (sv2coe mu_Earth testSV0R) == pi)

  it "RAAN of orbit in xy-plane is ±pi or zero"
    (property $ \mu x y vx vy -> mu > _0 ==>
      let r =  x <:  y <:. 0 *~ meter
          v = vx <: vy <:. 0 *~ mps
          ra = raan (sv2coe mu (sv r v)) :: Angle Double
      in ra ~== pi || ra ~== negate pi || ra == _0
    )

  it "For prograde orbit at perigee trueAnomaly = 0"
    (anomaly (sv2coe mu_Earth testSV0) == Anom _0)

  it "For retrograde orbit at perigee trueAnomaly = 0"
    (anomaly (sv2coe mu_Earth testSV0R) == Anom _0)

  it "For prograde orbit at apogee trueAnomaly = -pi"
    (anomaly (sv2coe mu_Earth testSV1) == Anom (negate pi))

  it "For retrograde orbit at apogee trueAnomaly = pi"
    (anomaly (sv2coe mu_Earth testSV1R) == Anom pi)

  it "Prograde orbit with AN, perigee, and anomaly coinciding on +x"
    (let coe = sv2coe mu_Earth testSV2
      in raan coe == _0 && aop coe == _0 && anomaly coe == Anom _0
    )

  it "Retrograde orbit with AN, perigee, and anomaly coinciding on +x"
    (let coe = sv2coe mu_Earth testSV2R
      in raan coe == _0 && aop coe == _0 && anomaly coe == Anom _0
    )

  it "Prograde orbit with DN, perigee, and anomaly coinciding on +x"
    (let coe = sv2coe mu_Earth testSV3
      in raan coe == negate pi && aop coe == pi && anomaly coe == Anom _0
    )

  it "Prograde orbit with DN, apogee, and anomaly coinciding on +x"
    (let coe = sv2coe mu_Earth testSV4
      in raan coe == negate pi && aop coe ~== _0 && anomaly coe == Anom pi
    )

-- ----------------------------------------------------------
spec_coe2coeM = describe "coe2coeM2coe" $ do

  it "Converting a COE to a COEm and back to a COE does not change it"
    (testCOE0 ~== (coeM2coe . coe2coeM) testCOE0)

  it "Converting a COE to a COEm and back to a COE does not change it"
    (testCOE1 ~== (coeM2coe . coe2coeM) testCOE1)

  -- This doesn't work for hyperbolic orbits.
  it "Converting an arbitrary COE to a COEm and back to a COE does not change it"
    (property $ \(c::CT) -> ecc c < _1 ==> c ~== (coeM2coe . coe2coeM) c)

  it "Converting an COE with zero eccentricity to a COEm doesn't change the anomaly"
    (property $ \(c'::CT) -> let c = c'{ ecc = _0 } in
      anom (anomaly c) ~==~ anom (anomaly (coe2coeM c)))

  it "Converting an COE with non-zero eccentricity to a COEm changes the anomaly"
    (property $ \(c::CT) -> ecc c < _1 && ecc c /= _0 ==>
      not (anom (anomaly c) ~==~ anom (anomaly (coe2coeM c))))

-- ----------------------------------------------------------
spec_meoe2meoeM = describe "meoe2meoeM2meoe" $ do

  -- This doesn't work for hyperbolic orbits.
  it "Converting an arbitrary MEOE to a MEOEm and back to a MEOE does not change it"
    (property $ \(m::MT) -> eccentricity2 m < _1 ==>
      m ~== (meoeM2meoe . meoe2meoeM) m)

  it "Converting an MEOE with zero eccentricity to a MEOEm doesn't change the longitude"
    (property $ \(m'::MT) -> let m = m'{ f = _0, g = _0 } in
      long (longitude m) ~==~ long (longitude (meoe2meoeM m)))

  it "Converting an MEOE with non-zero eccentricity to a MEOEm changes the longitude"
    (property $ \(m::MT) -> eccentricity2 m < _1 && eccentricity2 m /= _0 ==>
      not (long (longitude m) ~==~ long (longitude (meoe2meoeM m))))


-- Convenience and utility functions.

-- | Magnitude of orbit angular momentum per mass unit.
orbmom v = vNorm (pos v `crossProduct` vel v)

mps = meter / second

-- | From Wikipedia.
mu_Earth = 398600.4418 *~ (kilo meter ^ pos3 / second ^ pos2)

-- | Fudge a state vector to avoid comparing to zero elements
-- where the deviation may be greated than epsilon.
fudgeSV :: SVD -> SVD
fudgeSV state = sv (r >+< (a<:a<:.a)) (v >+< (b<:b<:.b))
  where
    r = pos state
    v = vel state
    a = vNorm r * (1e-6*~one)
    b = vNorm v * (1e-6*~one)


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

testSV0 = sv (42156 *~ kilo meter <:    0 *~ meter <:. 0 *~ meter)
             (    0 *~ mps        <: 3075 *~ mps   <:. 0 *~ mps)

testSV0R = sv (42156 *~ kilo meter <:       0 *~ meter <:. 0 *~ meter)
              (    0 *~ mps        <: (-3075) *~ mps   <:. 0 *~ mps)

testSV1 = sv (42156 *~ kilo meter <:    0 *~ meter <:. 0 *~ meter)
             (    0 *~ mps        <: 3000 *~ mps   <:. 0 *~ mps)

testSV1R = sv (42156 *~ kilo meter <:       0 *~ meter <:. 0 *~ meter)
              (    0 *~ mps        <: (-3000) *~ mps   <:. 0 *~ mps)

testSV2 = sv (42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter)
             (0 *~ mps <: 3075 *~ mps <:. 1 *~ mps)

testSV2R = sv (42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter)
              (0 *~ mps <: (-3075) *~ mps <:. 1 *~ mps)

testSV3 = sv (42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter)
             (0 *~ mps <: 3075 *~ mps <:. (-1) *~ mps)

testSV4 = sv (42156 *~ kilo meter <: 0 *~ meter <:. 0 *~ meter)
             (0 *~ mps <: 3000 *~ mps <:. (-1) *~ mps)
