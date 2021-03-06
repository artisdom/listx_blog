---
title: "Programming Puzzle: Game Button Sequence Recognizer"
tags: programming, haskell, ruby
mathjax: on
---

So just yesterday, I did a live coding interview.
Looking back, the problem I was presented with was very simple, but true to my usual nervous self, I over-analzyed the problem --- completely missing the point and needlessly complicating things.
In an effort to redeem myself, I thought about the problem again and even went out as to write tests for it, in both Ruby and Haskell.
If you want to have a crack at the problem yourself, be conservative about scrolling down the page!
Without further ado, I present the problem to you.

## The Problem

You are a game engine API writer.
You need to implement a mechanism that allows your developers to store and retrieve game moves based on the input to the game engine.
The two functions for this mechanism should be named `register()` and `on_button()`.

`register()` should take a named button sequence, and store it into the database of all named sequences.
A single named sequence might look like this: `(["down", "forward", "punch"], "hadoken")`.

`on_button()` should take a single key, and then return all named sequences that match the ones in the database.
E.g., `on_button("punch")` should return `"hadoken"` if the previous two inputs were `"down"` and `"forward"`.

### Some Constraints

#### Multiple Sequences

Because our API is flexible, we allow *multiple* named sequences with the *same sequence*.
Thus, you can expect something like this:

```
register(["up", "punch"], "uppercut")
register(["up", "punch"], "uppercut_2")
on_button("up")        # no result
on_button("punch")     # ["uppercut", "uppercut_2"]
```

.
You don't have to worry about multiple named sequences with the same sequence and also the same name --- we will worry about this "exact duplicate" situation in a later version of our API.

#### Input History

You might have noticed that `on_button()` depends on the input history of whatever buttons were *previously* entered into the game.
Because of this, you can alternatively write an `on_buttons()` function (plural with an "s") that takes the history of buttons as input; this way you don't have to silently depend on the global state of input history.

## My Nervous-Wreck Solution

I decided to use pure Haskell code in the actual interview.
The code I wrote had the general idea, but it was a big failure because it performed a naive, custom search without any thought given to data structures.
I actually went back and revised the code to make it compile and work *after* the interview was over; here it is in all its glory:

- i toy/game-button-seq/interview_ver.hs

.
I have to admit, the `step` function in `onButtons` is essentially unreadable.
But it does work:

```
$ ghci code/toy/game-button-seq/interview_ver.hs
GHCi, version 7.8.4: http://www.haskell.org/ghc/  :? for help
Loading package ghc-prim ... linking ... done.
Loading package integer-gmp ... linking ... done.
Loading package base ... linking ... done.
[1 of 1] Compiling Main             ( code/toy/game-button-seq/interview_ver.hs, interpreted )
Ok, modules loaded: Main.
*Main> onButtons ["down", "down", "forward", "punch"] buttonSeqDB
["charger","hadoken"]
```

.

Anyway, I will explain the behavior of the code.
The first thing to notice is that we feed into `step` the *reversed* list of `buttonHist`, so that we examine the button press history, from newest to oldest.
So we look at the just-pressed-button, then the one before that, and the one before, etc, backwards up the history.

As we look at each `button`, we use it to filter out all known sequences.
This filtering is done in `remaining`, where we check the last button of every known sequence, and see if that matches the current button.
That's what the line `filter ((==button) . last . fst)` does; the sister line `filter (not . null . fst) dbRem` is just there to prevent calling `last` on an empty list.

After we're done checking, we modify the entire sequence database `db`, such that we only care about the first $N - 1$ buttons in the sequence.
This way, on the next iteration, we can rest assured that checking against the "last" button in a sequence is not always the same button.
In subsequent runs of `step`, we have `dbRem`'s sequences slowly get reduced down to nothing as we keep chopping off all sequences' last button.
Keep in mind that we feed the filtered, matching entries of `db` back into subsequent runs of `step`, so that effectively we're only working with matching sequences.
Once we reach down to no buttons, we label these named sequences as `entriesComplete`, and append it into `foundSoFar`.

### Analysis

Obviously, this code has many problems.
First, it is virtually unreadable.
Readability is important, and the code feels very counter-intuitive --- it is marvelously complex when the problem statement sounds so simple.

Second, the fact that we have to bring in and mutate `dbRem`, which is a copy of the original given `ButtonSeqDB` type, seems wasteful.
We're wasting a lot of CPU cycles here.

## Ruby Solution Using Hashes

So on the day after (that is, *today* as of the time of this writing), I thought about the problem again and realized we can use hashes.
It is a very simple approach, with far less lines of code.
I even wrote some tests for it.
Here is the implementation below.

- i toy/game-button-seq/hash_ver.rb

And here is the test suite for it.
You can run it with `ruby test_hash_ver.rb`.

- i toy/game-button-seq/test_hash_ver.rb

### Analysis

The key insight was when I realized that you could indeed use a hash even though we have the requirement that multiple, identical button sequences can have different names.
The trick is to simply store the value as not a single name, but an array of possible names.
This is reflected in the `GameButtonSeq.register` method.

The heart of `on_buttons()` is a single `while` loop that checks the given button history against the database; we reduce the button sequence by 1 button on each iteration to check against shorter matches as well.
That's what the `button_seq.shift` is for.

## Haskell Solution Using Hashes

Inspired by the Ruby solution, I rewrote a Haskell version --- with tests to boot!
Here is the implementation.

- i toy/game-button-seq/GameButtonSeq.hs

The file is named `GameButtonSeq` because of Haskell naming conventions for files containing module code.
And here is the test for it.

- i toy/game-button-seq/test_hash_ver.hs

### Analysis

This Haskell version uses the standard `Data.Map` module, which provides an efficient, basic hash data structure.
What we first do is expand `buttonHist` to all of the cases we are interested in --- namely, all of the subsequences of concern.
E.g., given a list like `["up", "down", "right", "left"]`, `buttonHists` becomes:

```
[ ["up", "down", "right", "left"]
,       ["down", "right", "left"]
,               ["right", "left"]
,                        ["left"]
]
```

(spaces added for readability).
What we do is reduce the initial input list into all of the "sublist" combinations of $N$ buttons, $N - 1$ buttons, $N - 2$ buttons, etc.

The next step is to simply look at each sublist with `concatMap`, calling `extractNames`; we treat each sublist as a key, and look for it in our `db` hash.
We then simply concatenate the results.

The `onButtons2` is an alternate version which uses `mapMaybe` to reduce it down to just two lines of code.

## Conclusion

I cringe as I look back at the half-baked code I wrote during the interview.
Even the working, compilable version that I wrote after the interview remains ugly and hard to reason about.
I can picture my interviewer being grossed out by my ugly, hacky version wondering if I even know what hashes are...

The moral of the story is to think carefully about the most obvious data structure to use, before embarking on writing a solution --- no matter how trivial it seems.
For myself, I was nervous and did not realize how simple the problem actually was until the day after when I rewrote the solution in Ruby.
It was so simple and straightforward that I even wrote some test cases for it[^testing].

I hope you had some fun writing out your own solutions.
Happy hacking!

[^testing]: You can test the Haskell hash version in this blog post if you clone this blog's repo and then build it with Cabal (I've listed the program as an executable with all the constraints in the `blog.cabal` file in the repo root folder).
For the Ruby version, simply do `ruby path/to/test_hash_ver.rb` and Ruby will run the tests inside.
