---
title: Using the Nix Package Manager for Haskell Development from Arch Linux
tags: programming, haskell, arch, linux, nix
---

I recently installed and configured NixOS on a laptop and had to learn how to develop Haskell on it.
The Nix community uses something called `cabal2nix` (version 2.0 and up!) and `nix-shell` to get the job done.
While things work quite smoothly right now in NixOS, I was wondering if I could do the same on my desktop Arch Linux box.

The answer is yes --- you can easily use Nix to create a 'system sandbox' of sorts (the Nix store) that is completely isolated from Arch's own Haskell packages/GHC.
To be clear, what we are trying to do is install the Nix package manager (which is composed of many satellite programs like `nix-env`, `nix-shell`, etc.) so that we can develop Haskell programs with all the advantages that come with it.

For myself, I have several different Haskell projects, and I wanted to avoid redownloading and recompiling the same packages for each project's Cabal sandbox environment.
Using Nix, I still have the same Cabal sandboxes (one for each project root), but Nix allows all the different sandboxes to share the same packages if the versions and dependencies are the same.
And plus, because the Nix store (where Nix stores everything --- `/nix/store`) is independent of Arch's `pacman` tool, there is no fear of conflict or things breaking whenever you upgrade Arch Linux's own Haskell packages.[^use-arch-haskell]

# Use the Nix Manual to install Nix

The [Nix manual](http://nixos.org/nix/manual/) has up-to-date documentation on how to get Nix.
When we say *Nix*, we are talking about the collection of console programs (with a `nix-` prefix in their names) that make up to form the Nix package management system --- much like how *Git* is made up of smaller programs that work as a team.
There is a `nix` package on the AUR, but I suggest simply following this guide.

The first step is to run the install script from the NixOS site (which hosts Nix and other related programs) as a normal user:

```
$ bash <(curl https://nixos.org/nix/install)
```

.
You will now have a directory called `/nix` in your system.
This is where everything related to Nix will be stored.
In addition, the script will create some hidden files under your user's home directory with the `.nix-` prefix.
The most important file for now is `~/.nix-profile`, because it links to a shell script that initializes the Nix environment (to bring in `nix-*` utilities into the current shell's scope).
You will get a message from the shell script to source this file, like this:

```
$ . /home/l/.nix-profile/etc/profile.d/nix.sh
```

.
For me, I put the whole thing into an alias for my shell called `nix`, like this:

```
# somewhere in my ~/.zshrc
alias nix='. /home/l/.nix-profile/etc/profile.d/nix.sh'
```

.[^fear-not]
So, whenever I want access to Nix utilities, I just type in `nix` and go on my merry way.

# Install `cabal2nix` and `cabal`

Now, use your alias to enable Nix.

```
$ nix
```

You now have access to all the `nix-*` utilities that make up to provide the Nix package management system.
You can list all Nix-packaged packages with `nix-env -qaP`.
For us, we're interested in the `cabal2nix` package.
As of the time of this writing, it is called `nixpkgs.haskellPackages.cabal2nix`.
However, the `haskellPackages` prefix refers to the old system that has been more or less deprecated as of [January 2015](http://article.gmane.org/gmane.linux.distributions.nixos/15513).
We need to use the `haskellngPackages` (note the `ng`) prefix instead.
I know that `nixpkgs.haskellngPackages.cabal2nix` isn't listed with the `nix-env -qaP` command, but I believe that's for legacy reasons.
You can still install it!
Let's do that now:

```
$ nix-env -iA nixpkgs.haskellngPackages.cabal2nix
```

.
This will give you the very useful `cabal2nix` binary which you can use to convert any `.cabal` file into something that Nix can understand!
Let's also install `cabal` for Nix:

```
$ nix-env -iA nixpkgs.haskellngPackages.cabal-install
```

.
This will install `cabal` to `~/.nix-profile/bin/cabal`.
This step is not really necessary if you have `cabal-install` already installed on the Arch Linux side with `pacman`.
However, I still recommend it because

1) if you're using Nix for Haskell development, there is no longer a need to use `cabal` outside of the Haskell/Nix development process;
2) it just makes sense to use the `cabal` package that comes from the same source tree as `cabal2nix` (i.e., from the same `haskellngPackages` set[^nix-channel]); and
3) as of the time of this writing the `cabal-install` version from Nix packages set is newer than the Arch version.

At the end of the day, your `cabal` binary should be writing to `~/.cabal` so take care to use one version and stick with it.

# Nixify your project

## Create a `.cabal` file

If you haven't done so already, create a Cabal file `your_project.cabal` in your project's root folder to describe the dependencies in the traditional Haskell way.
This step is mandatory!

## Create a `shell.nix` file

Go to your project's root folder that contains `your_project.cabal`, and do

```
$ cabal2nix --shell . > shell.nix
```

.
The actual syntax is `cabal2nix --shell path/to/cabal/file`, which prints out the contents of the `.nix` file to STDOUT.
In the case above, we redirect it to a file named `shell.nix`.
The name of this file is important because it is what `nix-shell` expects.

Now just invoke

```
$ nix-shell
```

and you're set.
You will be dropped into a `bash` instance that has knowledge of the Nix store.
The first time you run `nix-shell`, Nix will identify any missing dependencies and install them for you.
Because your project's `shell.nix` file describes a Haskell project, `nix-shell` will install GHC along the way.
So when it's ready, you can start `ghci`.
Because you installed `cabal2nix` earlier, you have access to `cabal` (i.e., `cabal` is a dependency of `cabal2nix`).

To build your binary just do `cabal build`!
Personally I like to instantiate a Cabal sandbox with `cabal sandbox init` first, and then do `cabal configure`, `cabal repl`, `cabal build`, etc.

# Local dependencies

If you're like me, you might have a Haskell library you wrote for yourself (let's call it "Private Project X" (PPX)) which is not on Hackage.
If you just want to build PPX on its own, you can use the same steps outlined above.
But what if your other project depends on PPX?

The trick is to use `cabal2nix`, and to set up your `~/.nixpkgs` folder.
You should already have `~/.nixpkgs` created by now as a result of installing Nix.
Make a folder called `~/.nixpkgs/my-local-hs`.
Now do

```
$ cabal2nix path/to/ppx > ~/.nixpkgs/my-local-hs/ppx.nix
```
.
This will create a Nix expression that can be used to build PPX with Nix.
It's like creating a PKGBUILD file.
The next step is to create a `~/.nixpkgs/config.nix` file, as follows:

- i config.nix

.
Now, invoke `cabal2nix --shell` for your other project that depends on PPX.
When you invoke `nix-shell` for this other project, Nix should be able to resolve the dependency, based on the information you gave it in `~/.nixpkgs/config.nix`.
That's it!

# Conclusion

I recommend trying Nix out for Haskell development, or just as a secondary package manager in general.
Right now, everything "Just Works" and it's a pleasure to see different Haskell projects re-use the same packages, even when they are Cabal-sandboxed, as long as you are doing everything within `nix-shell`.

Even though the title of this post suggests that this is an Arch Linux guide to Nix, there is nothing Arch-specific about it.
You should be able to use the steps in this post for any Linux distribution.

Happy hacking!

[^use-arch-haskell]: That being said, if you're using Nix then there is little reason to continue to use the Arch packages. I say this with some reluctance, as I am the author of the [cabal2pkgbuild utility](https://github.com/listx/cabal2pkgbuild).
[^fear-not]: There are no Nix utilities with `nix` as its name, so there's no concern about name clashing.
[^nix-channel]: To figure out what Nix packages set, a.k.a. *channel* you are using, do `nix-channel --list`.
