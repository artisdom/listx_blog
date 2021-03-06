---
title: "Haskell: System.Random.MWC: High Quality Fixed Seeds"
tags: haskell, rng
---

I use Bryan O'Sullivan's [`mwc-random`][mwc-random] package for my PRNG (pseudorandom number generator) needs in my Haskell projects.
`mwc-random` is very fast and generates high quality random numbers.
It has a pretty simple API, and gives you several options of initializing the RNG state.
One way is to use the `initialize` function, which simply takes a list of `Word32` elements and takes the first 256 of them to seed the generator (if less than 256, it fills the rest from a hard-coded list).
I've discovered that using a simple list of 3 small numbers representing the year, month, and day (e.g., `[2013, 4, 11]`) is not very good as an argument to `initialize`, as the generator behaves somewhat similarly to, say, one with slightly different date (e.g., `[2013, 4, 12]`).

### The Problem

I have a program that needs to be seeded on a day-by-day basis, and it must use the current date (year, month, and day only) as the seed; however, I need the seed to be random enough to make the MWC state spit out substantially different random numbers on different, yet similar days.
In essence, I need to change

```{.haskell .numberLines}
import qualified Data.Vector as V
import System.Random.MWC

	...
	gen <- initialize $ V.fromList [year, month, day]
	...
```

to something that has a much higher quality in terms of randomness.

## Enter the SHA-1 Hash Function

Ah, the venerable [SHA-1][sha1] function.
It's a real gem because you can use it to generate an extremely high-quality 160-bit (20-byte) random number from a given set of bytes; and, even if you change the input by a single byte, it will generate a **totally different** number.
*You can think of the SHA-1 hash function as a function that takes a seed and generates a random number --- where the seed can be 0 bytes or 123 bytes or whatever size.*
Thankfully, there is a SHA-1 [package][sha-hackage] available, so I don't need to write my own correct implementation of SHA-1 (not to mention that only a handful of programmers can even write such code).

### The Solution

To solve my problem, I just take the current date, then feed it to the SHA-1 function to get `sha1Hash`; I then then repeatedly call SHA-1 against `sha1Hash` recursively.
Meanwhile, each time I get a SHA-1 hash of 20 bytes, I append it to an empty string of bytes, `acc`.
When `acc` is large enough to be split up into 256 `Word32` elements, I feed it to `initialize`.
The result is that I get much better seed-vs-similar-seed randomness with MWC.

Here is the code:

- i rng/mwc-seed.hs

The neat `chop` function is by [Dan Burton][chop].
The octet conversion functions between `Word8` and `Word32` types are from [this message][octet].[^1]

[^1]: The distinction between big-endianness and little-endianness does not matter at all for purposes of my solution, but I still distinguished them anyway as a reference.

[mwc-random]:http://hackage.haskell.org/package/mwc-random
[sha1]:http://en.wikipedia.org/wiki/Sha1
[sha-hackage]:http://hackage.haskell.org/package/SHA
[chop]: http://stackoverflow.com/a/5188922/437583
[octet]:http://www.haskell.org/pipermail/beginners/2010-October/005571.html
