{-# LANGUAGE ForeignFunctionInterface #-}

module HEP.Kinematics.Variable.MTLowerAndUpper (mTBound) where

import           Foreign.C.Types

import           HEP.Kinematics  (FourMomentum, HasFourMomentum (..),
                                  TransverseMomentum)

#include <mTLowerAndUpperBound_c.h>

foreign import ccall unsafe "mTLowerAndUpperBound_c.h mt_bound"
  c_MTBound :: CDouble -> CDouble -> CDouble -> CDouble
            -> CDouble -> CDouble -> CDouble -> CDouble
            -> CDouble -> CDouble
            -> CDouble
            -> CDouble

mTBoundPrim :: [Double] -> [Double] -> [Double] -> Double -> Double
mTBoundPrim visA visB ptmiss mIntermediate =
  let (eVisA:pxVisA:pyVisA:pzVisA:_) = map realToFrac visA
      (eVisB:pxVisB:pyVisB:pzVisB:_) = map realToFrac visB
      (pxMiss:pyMiss:_) = map realToFrac ptmiss
  in realToFrac $ c_MTBound eVisA pxVisA pyVisA pzVisA
                            eVisB pxVisB pyVisB pzVisB
                            pxMiss pyMiss
                            (realToFrac mIntermediate)

-- | calculates mTBound defined in <http://arxiv.org/abs/1106.2322 arXiv:1106.2322>.
mTBound :: FourMomentum       -- ^ four-momentum of the first visible systme
        -> FourMomentum       -- ^ four-momentum of the second visible system
        -> TransverseMomentum -- ^ missing transverse momentum
        -> Double             -- ^ mass of the intermediate particle
        -> Double
mTBound visA visB ptmiss mIntermediate =
  let (eVisA, pxVisA, pyVisA, pzVisA) = epxpypz visA
      (eVisB, pxVisB, pyVisB, pzVisB) = epxpypz visB
      (pxX, pyX) = pxpy ptmiss
  in mTBoundPrim [eVisA, pxVisA, pyVisA, pzVisA] [eVisB, pxVisB, pyVisB, pzVisB]
                 [pxX, pyX] mIntermediate