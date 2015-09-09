{-# LANGUAGE BangPatterns #-}

--------------------------------------------------------------------------------
-- |
-- Module      :  HEP.Analysis.Histogram1D
-- Copyright   :  (c) 2015 Chan Beom Park
-- License     :  BSD-style
-- Maintainer  :  Chan Beom Park <cbpark@gmail.com>
-- Stability   :  experimental
-- Portability :  GHC
--
-- Types and functions for 1D histogram.
--
--------------------------------------------------------------------------------
module HEP.Analysis.Histogram1D
       (
         Hist1D (..)
       , emptyHist
       , histogram
       , histogram1
       , scaleHist
       , integrate
       , unitNormalize
       , add
       , sub
       , showHist1D
       , bins
       , contents
       ) where

import           Data.Vector.Unboxed (Unbox, Vector)
import qualified Data.Vector.Unboxed as V

newtype Hist1D a = Hist1D { getHist :: Maybe (Vector (a, Double)) }
                 deriving Show

emptyHist :: Hist1D a
emptyHist = Hist1D Nothing

instance (Eq a, Unbox a) => Monoid (Hist1D a) where
  mempty = emptyHist
  mappend h1 h2 = h1 `seq` h2 `seq` add h1 h2

add :: (Eq a, Unbox a) => Hist1D a -> Hist1D a -> Hist1D a
add = combine (+)

sub :: (Eq a, Unbox a) => Hist1D a -> Hist1D a -> Hist1D a
sub = combine (-)

combine :: (Eq a, Unbox a) =>
           (Double -> Double -> Double) -> Hist1D a -> Hist1D a -> Hist1D a
combine _ (Hist1D Nothing)   hist               = hist
combine _ hist               (Hist1D Nothing)   = hist
combine f (Hist1D (Just h1)) (Hist1D (Just h2)) =
  let (bin1, x1) = V.unzip h1
      (bin2, x2) = V.unzip h2
  in Hist1D $ if bin1 /= bin2
              then Nothing
              else Just $ V.zip bin1 (V.zipWith f x1 x2)

histogram :: (Fractional a, Ord a, Unbox a) =>
             Int  -- ^ Number of bins
          -> a    -- ^ Lower bound
          -> a    -- ^ Upper bound
          -> [a]  -- ^ Data
          -> Hist1D a
histogram nbin lo hi xs
  | hi <= lo  = Hist1D Nothing
  | otherwise = let !binVector = binList nbin lo hi
                    !lowhigh = V.zip binVector (V.tail binVector)
                    !hist = V.map (flip (uncurry count) (V.fromList xs)) lowhigh
                in Hist1D $ Just (V.zip binVector hist)

-- | Histogram for single element.
histogram1 :: (Fractional a, Ord a, Unbox a) => Int -> a -> a -> a -> Hist1D a
histogram1 nbin lo hi x = histogram nbin lo hi [x]

binList :: (Fractional a, Num a, Unbox a) => Int -> a -> a -> Vector a
binList nbin lo hi = V.iterateN (nbin + 1) (+ binsize) lo
  where binsize = (hi - lo) / fromIntegral nbin

count :: (Ord a, Unbox a) => a -> a -> Vector a -> Double
count lo hi = fromIntegral . V.length . V.filter ((&&) <$> (>= lo) <*> (< hi))

scaleHist :: Unbox a => Double -> Hist1D a -> Hist1D a
scaleHist _ (Hist1D Nothing)  = Hist1D Nothing
scaleHist s (Hist1D (Just h)) = Hist1D $ (Just . V.map (\(b, x) -> (b, s*x))) h

integrate :: Unbox a => Hist1D a -> Double
integrate (Hist1D Nothing)  = 0
integrate (Hist1D (Just h)) = V.foldr (\(_, x) i -> x + i) 0 h

unitNormalize :: Unbox a => Hist1D a -> Hist1D a
unitNormalize (Hist1D Nothing)  = Hist1D Nothing
unitNormalize hist              = scaleHist (1.0 / integrate hist) hist

showHist1D :: (Show a, Unbox a) => Hist1D a -> String
showHist1D (Hist1D Nothing)  = ""
showHist1D (Hist1D (Just h)) = unlines . map toStr $ V.toList h
  where toStr (b, x) = show b ++ ", " ++ show x

bins :: Unbox a => Hist1D a -> [a]
bins (Hist1D Nothing) = []
bins (Hist1D (Just h)) = map fst $ V.toList h

contents :: Unbox a => Hist1D a -> [Double]
contents (Hist1D Nothing)  = []
contents (Hist1D (Just h)) = map snd $ V.toList h
