---
title: The Parking Lot Problem: A Successor to FizzBuzz?
tags: programming, ruby, haskell
mathjax: on
---

In one of my side projects, I encountered a pair of interesting problems, the first of which which I call the *Parking Lot* problem, and the sister problem the *Parking Load* problem.
They are but toy problems, but to anyone outside of the programming field, they sound quite complicated!

## Problem Statement

Imagine an infinite parking lot, where each parking space is given a natural number, starting with 0, 1, 2, 3, ... to infinity.
The entire lot is a single row of spaces --- so that space `0` is the one closest to the entrance.
There are a finite number of cars parked in the lot in it at random, as people come and go as they wish.
A new car has just arrived outside the lot, and the driver asks you, *"Where is the closest open parking space?"*

The only information you have is the *taken* spaces list (`T`), which lists all the occupied parking spaces.

## Some Preliminary Observations

The most important thing here is `T`.
If `T` is empty, then our parking lot is empty, so the answer is obviously `0`.
In all other cases, we have to figure out the lowest number that is *absent* from `T`.
Essentially, we can reduce the problem as follows:

- Find the lowest number not present in the set of integers `T`, where the lowest possible number is `0`.

I used the metaphor of the parking spaces because it is more memorable, and more importantly, more familiar to the general public.

## Mathematical Approach

Conceptually, the problem is very simple.
Consider the infinite set `N`, which includes all natural numbers, starting from `0`.
Then obviously, we can start with `N` itself, and remove every number in `N` that is also present in `T`.
Then, when we are done (`T` is empty), we can look at `N` and retrieve the lowest number.

### Sorting

Intuitively, we are really only interested in first consecutive group of cars parked next to each other.
Essentially, what you do is walk along from the very first parking space, `0`, and see if it is occupied.
If it is occupied, you move on to the next space --- if it is not occupied, you can stop because you found your answer!

There is no way to solve the problem without first sorting `T`.[^nosort]
You can solve the problem without sorting only in the edge case where `T`'s lowest number is greater than `0` --- i.e., if the car most closely parked to the entrance is not on `0`, then you do not need to bother sorting `T`, because the answer is simply `0`.
And, finding the lowest number in a given set is always a $O(n)$ operation because you just need to loop through the entire set one time, keeping track of the lowest number found.

In the more common case (as seen in real life), the parking space closest to the driver (the most desirable parking space) is already taken; and what's more, the group of spaces closest to the driver is already taken.
In this case, we have to proceed from space `0`, and incrementally observe every subsequent space, until we arrive at an empty parking space.
The insight here is that we are treating the multitude of consecutively parked cars as one giant car parked across multiple spaces, and are just trying to find the total number of spaces this car occupies.

## Ruby

I think it is time for some actual code.
While I could explain how the Ruby version works, I feel that I have already expounded upon the problem at length above, so the code here should make intuitive sense.

```{.ruby .numberLines}
def get_parking_space(t)
	t_sorted = t.sort

	i = 0
	while i < t_sorted.size
		if i < t_sorted[i]
			break
		end
		i += 1
	end

	return i
end
```

## Haskell

The Haskell version is a direct translation of the Ruby version, as an iterative approach works just fine.
The only drawback is that we use `Int` instead of the arbitrarily large `Integer` type for succinctness (we can use `Integer`, but some built-in functions like `sort` only work on `Int`).

```{.haskell .numberLines}
import Data.List

getParkingSpace :: [Int] -> Int
getParkingSpace ts
    | null ts = 0
    | otherwise = loop 0 $ sort ts
    where
    loop i ts'
        | i == length ts' = i
        | i < ts' !! i = i
        | otherwise = loop (i + 1) ts'
```

## Low-Level Interlude

Did you realize that the basic concept here is the same as finding the least significant bit (LSB)?
I.e., if the parking lot is one giant computer word, and a `1` bit represents an available parking space, then we are simply trying to find the LSB (the index of the bit being the same thing as the parking space number).
This is such a common scenario, that there are native hardware instructions for this on most all CPUs.
The canonical name for this operation is [*find first set*](http://en.wikipedia.org/wiki/Find_first_set) or *find first one*.[^twos]
In Linux, you can do `man ffs` to learn about how to use it in your C program.

Of course, the parking lot in our problem is of infinite size, which makes the size of `T` arbitrarily large, and thus we cannot use `ffs` here.

# The Parking Load Problem

An interesting related problem is what I call the *Parking Load* problem.
The scenario is the same as in the *Parking Lot* problem, but with the following twist: if the last (most far away) parked car determines the bounds of the parking lot (i.e., it is no longer considered infinitely large), then how many parking spaces are available?

Interestingly, this problem is easier to solve than the first problem.
This seems paradoxical --- surely, finding the first available parking space is easier than counting every single available space!
But it is true --- this problem is indeed easier --- because we can solve the problem *without sorting*.

If we talk in terms of our "Low-Level Interlude," this is the same as saying, "Count the number of `1` bits."
There are very clever ways of counting bits, but that is not our concern, and so I will present a naive solution in Ruby.

## Ruby

```{.ruby .numberLines}
def get_parking_load(t)
	if t.empty?
		return "Infinity"
	else
		return (t.max - t.size) + 1
	end
end
```

## Haskell

The Haskell version is not much different.

```{.haskell .numberLines}
getParkingLoad :: [Int] -> Either String Int
getParkingLoad t
	| null t = Left "Infinity"
	| otherwise = Right $ (maximum t) - (length t) + 1
```

## A Successor to FizzBuzz?

For some reason, I get a strong feeling that these problems are much more interesting than [FizzBuzz](http://en.wikipedia.org/wiki/Fizz_buzz).
The fact that we talk about an *infinitely large* parking lot will probably throw a lot of newbies and naive thinkers off the right track.
You have to be especially careful about edge cases, such as the empty list in the second Haskell version.
I believe that good coders have a keen sense of edge cases, because good algorithms must withstand them without blowing up.
Just review the Haskell solutions and notice all of the edge cases that we have to look out for!

You might even get some crazy answers that talk at length about related nonessential tangents and Big-O notation, but fail to realize just how simple, at least conceptually, the problem becomes once you sort `T`.
And, I like these problems more than FizzBuzz because there are so many interesting points about it.
For example, you can ask a simple related question: if you were the keeper of this parking lot, what kind of data structure would you use to keep track of the taken parking spaces?
And of course, there are very conspicuous low-level analogues that more experienced coders can relate to.

I hope you enjoyed reading about these problems.
Maybe you can quiz your friend about it, and see how they respond!

Happy hacking!

[^nosort]: You can, for example, loop from `0` to infinity and then see if this number exists in `T` --- but this is probably the worst way to solve the problem, at least from a computational perspective.
[^twos]: A closely related operation is [two's complement](http://en.wikipedia.org/wiki/Two's_complement) arithmetic. You can read about it from the ["Find first set"](http://en.wikipedia.org/wiki/Find_first_set) article on Wikipedia.