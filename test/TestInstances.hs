{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving #-}


module TestInstances where

import Test.QuickCheck hiding (property)-- (Arbitrary, arbitrary, (==>))
import Data.AEq
import TestUtil
import Numeric.Units.Dimensional.Prelude
import qualified Prelude
import Astro.Orbit.Types


-- Instances
deriving instance Arbitrary a => Arbitrary (SemiMajorAxis a)
deriving instance Arbitrary a => Arbitrary (SemiLatusRectum a)
deriving instance Arbitrary a => Arbitrary (Anomaly t a)
deriving instance Arbitrary a => Arbitrary (Longitude t a)

-- Arbitrary instance always returns values >= 0.
instance (Num a, Ord a, Arbitrary a) => Arbitrary (Eccentricity a) where
    arbitrary = do
      NonNegative e <- arbitrary
      return $ Ecc (e*~one)



deriving instance AEq a => AEq (SemiMajorAxis a)
deriving instance AEq a => AEq (SemiLatusRectum a)
deriving instance AEq a => AEq (Eccentricity a)

instance (RealFloat a, Eq a) => Eq (Anomaly t a) where
  (Anom x) == (Anom y) = plusMinusPi x == plusMinusPi y

instance (RealFloat a, AEq a) => AEq (Anomaly t a) where
  (Anom x) ~== (Anom y) = plusMinusPi x ~== plusMinusPi y
                       || plusTwoPi x ~== plusTwoPi y  -- move the boundaries.

instance (RealFloat a, Eq a) => Eq (Longitude l a) where
  (Long x) == (Long y) = plusMinusPi x == plusMinusPi y

instance (RealFloat a, AEq a) => AEq (Longitude l a) where
  (Long x) ~== (Long y) = plusMinusPi x ~== plusMinusPi y
                       || plusTwoPi x ~== plusTwoPi y  -- move the boundaries.