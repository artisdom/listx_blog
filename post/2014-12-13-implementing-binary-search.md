---
title: Implementing Binary Search
tags: programming, c, ruby, haskell
mathjax: on
---

If you are a programmer, I'm sure you've encountered the term *binary search* at some point in time.
I know what binary search is, but I'm writing this post to solidify my understanding of it.
I also want to compare how it might be naively implemented across my 3 favorite languages C, Ruby, and Haskell --- because naive code is the best code (to learn from)!

## Binary Subdivision

You can skip this section if you want --- I merely want to write how I first met and fell in love with the concept of *binary subdivision*.
I first discovered binary division when I was in high school.
It was a very pleasant realization, and at the time I did not fully realize what I had accidentally encountered.

The situation was so: my Biology teacher, Mr. Kennedy, told everyone to draw an even 4x4 square grid on the palms of our hands.
Everyone was supposed to draw their own 4x4 grid --- but this was when I asked myself, "how can I draw the most even-looking grid without using a ruler?"
You see, I could not use a ruler because I was using my right hand to draw onto my left hand --- and to hold a ruler properly I would need a third hand!
So there was the problem.

On the one hand, I could not simply draw the four horizontal and four vertical lines one after the other, left to right, top to bottom, because I knew that I would introduce a great deal of additive error.[^telephone]
I did not want to draw an ugly, lopsided square.

It took me a few seconds, but I came up with a plan.
I first drew a single large square.
Then knowing that I could easily eyeball with good accuracy where the *middle point of that square* was horizontally, I drew a vertical line down the *middle*.
I then did the same thing in the other axis vertically.
I repeated this procedure a few more times, *recursively subdividing* each smaller rectangular shape into halves, finally ending up with a nice-looking grid.
I glanced around the room, and later looked at other students' palms to see if they had discovered this "divide by $\frac{1}{2}$" trick, but to my dismay no one had done it; I knew this was the case because everybody else's square was sloppy.

I cannot honestly say if this was the very first time I realized the underlying geometric concepts at play here, but I can affirmatively say that it really was the first time I systematically applied such an elegant solution to a given problem.
I wonder if most people who draw grids even bother to think of it as a problem.

To me, binary subdivision is the underpinning principle behind binary search.
Continued subdvision by halves is like exponentiation in reverse; pretty soon, you end up with extremely tiny numbers.
This is where the power of binary search comes from!
Simply put, binary search is like binary subdivision, but you get to subdivide *toward* the location of whatever you're looking for.
Isn't that cool?

## The Problem

The problem is simple --- given a **sorted** list `KEYS` of items (for simplicity's sake, positive integers), determine if `key` is in it, and also, the position of `key` in the list if it is indeed in the list.
The catch is that you have no idea as to the contents of `KEYS` --- only that it is sorted from smallest to largest.

## Naive Approach --- Linear Search

The simplest way of doing this is by linear search.
It is probably the novice programmer's first reaction.
You just start from the first item in `KEYS`, and run a **for**-loop all the way across the list, looking at every single item.
There are now two possibilities --- either (1) you indeed discover `key`, and report back your position (aka the "index", usually in the form of the familiar `i` variable in C/C++/Java code), or (2) you find nothing.
If you are clever, you can optimize the search in the second situation by breaking out of the **for**-loop if the items you are comparing are larger than `key`; after all, `KEYS` is sorted, so we know for a fact that the later numbers are only going to get bigger, so there is no point in trying to find `key` in that crowd of numbers.

But think of the consequences --- what's the worst case scenario?
Imagine you have 1 trillion items, and that `key` is not in it, because let's say `key` is a much bigger number than the biggest number in `KEYS` --- but of course you haven't run the linear search yet, so you don't know that.
Given this situation, you would have to search the *entire* list of all numbers in `KEYS` before reaching condition (2) described above.

If you wanted to get a little more clever to avoid this problem of searching all 1 trillion items, you could tell the algorithm to refuse to enter the **for**-loop if `key` lies outside the *bounds* of `KEYS`.
Checking the bounds is easy and takes constant time, as you merely check for the first and last item's size (again, as `KEYS` is sorted), and those are your bounds.
This way, if `key` lies outside the bounds, you can *guarantee* that it is not in `KEYS`, no matter how many items `KEYS` has.

And, this is it.
There is nothing more to optimize using this method (let's not get into parallelization).
What else can you do, really, when searching linearly, looping through every item from the beginning to the next?

## Inverted Bounds-Checking, aka Binary Search

The heading of this subsection might have already given you a hint as to what binary search entails.
(Although, if you've read the *Binary Subdivision* section, you should have had a good idea anyhow.)
Binary search takes the concept of bounds-checking, and applies it repeatedly, recursively, against `KEYS`.
The only difference when I say "bounds-checking" in the context of binary search is that we do *not* care about the values of those bounds, but merely that they *are* the bounds.
This is because we only concern ourselves with dividing the list of sorted numbers by $\frac{1}{2}$ every time and take the *middle* index `middle_index`, which is located as close as possible to the middle element (halfway between the two bounds).
Indeed, the only way to get a valid `middle_index` value is if we know the bounds (the size of the list).
We keep doing this recursively until `KEYS[mid] == key`.

The following is the pseudocode.

- i toy/binary-search-pseudo-0.txt

There are some obvious holes in the code above.

First, we always assume that `KEYS` is made up of multiple elements, and that its halves `lower_keys` and `upper_keys` also have multiple elements in them.
In the extreme case, `KEYS` might be an empty list, which would make the whole thing explode.

Second, the `get_middle_index()`, `get_below_mid()`, and `get_above_mid()` functions remain undefined.

Aside: You might be wondering about lines 12-14.
We could write

```
else if key == KEYS[mid]
```

instead of just `else` on line 12, but that is redundant. This is because we already test for the two other conditions of `key` being *lesser* or *greater* than `middle_index`.
Therefore, we've excluded the two other conditions and are already only left with the third condition of `key == KEYS[mid]` evaluating to TRUE --- hence we write just `else` on line 12.

Addressing the holes above, we get the next version.[^hole-driven-development]

- i toy/binary-search-pseudo-1.txt

There are some obvious differences --- mainly the fact that we concern ourselves primarily with the first and last index numbers of the list, and work with these indices instead of working with the entire list `KEYS` itself.
The `get_below()` and `get_above()` functions are gone and have been replaced with the index bounds `first_index, middle_index` and `middle_index + 1, last_index`, respectively.
As you can see, working with these index numbers directly avoids a lot of abstraction.
Actually, the `list_size` abstraction can be further reduced in terms of indices, so that `list_size == 0` can be rewritten as `first_index > last_index`.[^list_size-shortcut]

## Theoretical Performance

You can probably see why binary search is so powerful.
It repeatedly divides the search region into $\frac{1}{2}$ of its original size.
It's sort of like [Zeno's Dichotomy Paradox](http://en.wikipedia.org/wiki/Zeno%27s_paradoxes), except that it uses the "absurdity" of Zeno's argument, and uses that to its advantage.
To me, these somewhat related, even tangential, connections make binary search that much more elegant.

Consider this: a list that has 100,000 elements will only take, in the worst case, around 16 calls.
Compare that to linear search, which will take at most 100,000 calls or iterations (if our item happens to be at the very last index).[^branch-prediction]
The time complexity of binary search for a list of $\mathit{KEYS\_TOTAL}$ elements is defined to be $\lfloor\log_2\mathit{KEYS\_TOTAL}\rfloor$.
Because this defines an exponential relationship, we can rest assured that we can *cut down* a very large list quickly.[^sorting]

## Naive Implementations

### Preliminary Details

I said at the beginning of the post that I would show a naive implementation in C, Ruby, and Haskell.
I could have simply written a `binary_search()` function (and only that function) for all three languages --- but instead I chose to write full standalone programs for all three that print out the same results.
Because they are all standalone programs, you can easily tweak some settings (namely, the `KEYS_TOTAL` value), and see how it scales.[^cmdline-args]
All versions use the new [PCG family](http://www.pcg-random.org) of pseudorandom number generators (RNGs), which have been created by Prof. Melissa E. O'Neill, author of the great paper *The Genuine Sieve of Eratosthenes*.[^sieve]

### C Version (Linux)

- i toy/binary-search.c

Overview:

- `pcg32_random_r()` is PCG's minimal implementation version.
This is RNG we depend on to get identical randomly-generated data in the other Ruby and Haskell versions.
- `uniform32()` tames all raw RNG's like `pcg32_random_r()`; it [removes any bias](2013-07-12-generating-random-numbers-without-modulo-bias.html) that might be introduced if we were to use a simple modulo operation.
Hence, we use `uniform32()` for all our RNG needs.
- `init_array()` takes an empty array of fixed size, and populates it with semi-random numbers.
I say *semi-random* because the number chosen to populate the array, in sequence, is steadily bumped up with the `j` variable, **eliminating the need for sorting it afterwards** in preparation for passing it to `binary_search()`.
- Finally, we have `binary_search()` itself, written in a way to closely match the pseudocode presented above.

I've tried to keep the code simple.
You may find it disturbing that we use the same type for `KEY_NOT_FOUND` as the actual valid key value (`mid`) itself.
This kind of type overloading is common in C, and is what gives C its bare metal speed --- at the cost of (probable) disaster, of course.

### Ruby Version

- i toy/binary-search.rb

This version, like the Haskell version, tries to follow the C version as much as possible.
One drawback of this version is that because Ruby does not support fixed-width integers, we have to make liberal use of the modulo operator `%` to emulate integer overflow.
We could just do a bitwise AND (`&`) with a mask, but that would risk increased verbosity.

### Haskell Version

- i toy/binary-search.hs

It pained me not to make use of Haskell's much faster, efficient `Array` data structure instead of plain lists (that are constructed with the square brackets `[]`).
And, I have to admit that it is written in a strange style; I've preserved the names of the variables from C and Ruby where I could, even though mixing snake_case with camelCase results in utter ugliness.
I also restrained myself from using the `State` monad for keeping track of `PCG32`'s state.
For you non-Haskellers, that means that I manually passed around RNG state (as you can see with `rng0`, `rng1`, `rng2`, etc.) as arguments and return values, because I did not want to place another barrier against quickly grasping the code.
Do you really want monad transformers in a "naive" implementation?[^state-monad-whatif]

The most immediate effect to me when writing the Haskell version was just how stateful the `uniform32()` and `init_array()` functions were.
The C/Ruby brethren perform lots of variable mutation in those parts, and are consequently difficult to understand from a *pure* (type system) perspective.
All of the silent type promotions in C were blatantly exposed by the Glasgow Haskell Compiler (GHC), making it necessary for me to include all of those explicit `fromIntegral` type promotions myself in `pcg32_random_r` and `init_array`.

But even with all of these explicit conversions and the un-idiomatic Haskell style (excluding coding style), I find the Haskell version much easier to understand.
Just compare how clean `binary_search` looks in Haskell versus the other ones!
And the fact that you can basically define nested functions/methods with the `where` clause makes hole-driven development a piece of cake.

## Conclusion and Hopes

I hope you've enjoyed looking at the various implementations of binary search.
Binary search is certainly something you can write on your own, although getting the surrounding technicalities correct can be a chore --- but isn't that always the case when trying to obvserve the behavior of an algorithm in practice?
You can look at the cute 10 or 15-line pseudocode on Wikipedia all day, but how can you be sure that it works?
This focus on **real world examples** has been a driving principle behind all of my blog posts, and I hope it has helped you understand the algorithm better.

Binary search is something you can apply in real life, too.
For me, I came into contact with it again when I learned about `git bisect`.
I personally try to use binary search myself when I code; for example, if a large block of code does not work, I delete large chunks out, making the deletions ever finer, until I get to the source of the problem.
You can think of these examples as binary search, where the key is the (as yet unknown) bad commit or line of code you have to fix.
You can be your own algorithm!
Isn't that cool?

Thanks for reading, and happy hacking!

[^telephone]: It's like in the children's ["Telephone"](http://en.wikipedia.org/wiki/Chinese_whispers) game, where the error of one person gets magnified at every step, until the end when the message gets so garbled up it becomes comical.

[^hole-driven-development]: "Hole-driven-development", as I like to call it, is a top-down approach to development.
You first define the larger pieces, and continuously define the smaller sub-pieces, until you reach atomic pieces (those pieces which cannot be further sub-divided).
You might have noticed that this style of writing code has an eerie parallel to the whole (no pun intended!) discussion about binary subdivision, and so forth.

	As an aside, in the Haskell community, *hole-driven Haskell* takes the same approach, but first you define the behaviors of the functions through its type signatures, and leave the implementation details undefined.
This way, you can use the compiler's type system to help you define what you want as you go; this is certainly a step up from *unassisted* hole-driven development that we are doing with the pseudocode here.

[^list_size-shortcut]: The condition `first_index > last_index` might not make sense.
This was the pseudocode on Wikipedia at the time I wrote this, and it didn't make sense to me at first.
But think of it this way: binary search involves division of the list into halves, repeatedly.
So `first_index` and `last_index` get closer and closer to each other.
The point is that the distance between these two markers will close, shrinking the list into smaller and smaller subparts.
We can't simply check if these two points meet, by writing `first_index == last_index`, because of the base case of a 1-element list.
Such a list will have `first_index` as 0, and the `last_index` as also 0 --- because there is only 1 index!
In this case, the condition `first_index == last_index` to check for an empty list is inadequate.

	If you look at how we call `binary_search()` again in lines 15 and 17, you will notice that the new definitions of `first_index` and `last_index` depend on `middle_index`, and it's this interplay with `middle_index` that forces `last_index` to eventually become smaller than `first_index`.
If you work out the algorithm through some small cases, you will see this happen eventually.

[^sorting]: However, be mindful to the fact that binary search relies on the input list being sorted.
Sorting a list itself is a fundamental problem in computer science, and there are numerous sorting algorithms as well as data structures that make such sorting more amenable.
In the real world, I think 90% of your time is going to be spent sorting the list first, by which time the speed benefits of binary search probably won't hold much influence.
If the search space is always small, you could easily get away with linear search --- why bother adding complexity where you don't need it?

[^branch-prediction]: Linear search does have the advantage that, on a sorted list, it can take advantage of branch prediction.
This is because the `if/else` test will *always go in one direction*, until when we get a match or when the element considered is greater than the search key.
But in the long run as you increase the search space, binary search will beat linear search hands down.

[^cmdline-args]: You could trivially add on a proper command-line argument handling mechanism.
In particular, `KEYS_TOTAL` is dying to be decoupled from the program's internals --- but I leave that as an exercise to you.
(Hint: use a command-line option parsing library!)

[^sieve]: MELISSA E. O'NEILL (2009). The Genuine Sieve of Eratosthenes. Journal of Functional Programming, 19, pp 95-106. doi:10.1017/S0956796808007004.
[Online draft version](http://www.cs.hmc.edu/~oneill/papers/Sieve-JFP.pdf).

[^state-monad-whatif]: What if I had indeed made use of the `State` monad, you ask?
Well, first I wouldn't need to pass in, or get back, the RNG state variables.
I would just run the RNG-state-changing functions *inside* the `State` monad (actually, probably the `StateT` monad transformer as we're in the `IO` monad anyway), to `get`/`put` the RNG states to read/write those values.
