module Main where

-- IO
import System.IO
import System.Environment
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL

-- JuicyPixels
import Codec.Picture hiding (Traversal)
import Codec.Picture.Types hiding (Traversal)

-- Stuff for wav encoding
import Codec.ByteString.Builder
import Codec.Wav
import Data.Audio
import Data.Array.Unboxed
import Data.Int

-- Other
import Data.List
import Control.Lens

-- Reallocates empty samples to take the place of filled ones, spreading the
-- reallocations evenly across the row
rowSamples :: [Bool] -> [Double]
rowSamples r
  -- Output all zeroes if we have no data on this row
  | null filled = replicate w 0

  -- Otherwise, replicate each filled pixel by its number of samples
  | otherwise = concat (zipWith replicate numSamples filled)
  where
    -- Width of the row
    w = length r

    -- Convert a sample to its corresponding amplitude based on its X position
    -- Maps x values [0,w - 1] to [-1.0,1.0]
    amplitude x = x / fromIntegral (w - 1) * 2.0 - 1.0

    -- Samples for all filled pixels
    filled = 
        [ amplitude i
        | (i,v) <- zip [0 ..] r 
        , v ]

    numFilled = length filled

    numEmpty = w - numFilled

    -- Total number of empty samples reallocated at filled sample n,
    -- where n <- [0 .. numFilled)
    allocatedSamples = 
        [ n * numEmpty `div` numFilled
        | n <- [0 ..] ]

    -- Number of empty samples reallocated to each specific pixel n, plus one
    -- sample for its default allocated sample, where n <- [0 .. numFilled)
    numSamples = 
        map (+ 1) $ zipWith subtract allocatedSamples (tail allocatedSamples)

monochrome :: PixelRGB8 -> Bool
monochrome (PixelRGB8 r g b) = sum `div` 3 > 127
  where
    sum = fromIntegral r + fromIntegral g + fromIntegral b :: Int

pixels :: Image PixelRGB8 -> [Bool]
pixels img = monochrome <$> toListOf p img
  where
    p :: Traversal (Image PixelRGB8) (Image PixelRGB8) PixelRGB8 PixelRGB8
    p = imagePixels

-- Pixels are reversed for display with waterfall displays which move from top
-- to bottom
rows :: Int -> [Bool] -> [[Bool]]
rows width = reverse . chunk
  where
    chunk [] = []
    chunk xs = 
        let (h,t) = splitAt width xs
        in h : chunk t

samples :: Image PixelRGB8 -> [Double]
samples img = concatMap rowSamples . rows (imageWidth img) $ pixels img

writeSamples :: Handle -> [Double] ->  IO ()
writeSamples ofile = BL.hPut ofile . toLazyByteString . buildWav . audio
  where
    audio samples = 
        Audio 48000 1 . listArray (0, length samples - 1) $ map s16le samples
    s16le :: Double -> Int16
    s16le = round . (* 32767)


run :: Handle -> Handle -> IO ()
run input output = do
    img <- decodeImage <$> B.hGetContents input
    either (hPutStrLn stderr) (writeSamples output . samples . convertRGB8) img

displayHelp :: IO ()
displayHelp = do
    path <- getExecutablePath
    hPutStrLn stderr ("Usage: " ++ path ++ " [infile [outfile]]")

main :: IO ()
main = do
    args <- getArgs
    case args of
        ["-h"] -> displayHelp
        ["--help"] -> displayHelp
        [i] -> withFile i ReadMode (flip run stdout)
        [i,o] -> withFile i ReadMode (withFile o WriteMode . run)
        _ -> displayHelp
