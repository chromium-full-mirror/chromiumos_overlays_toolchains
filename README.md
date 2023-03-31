# CrOS Toolchains Overlay

This overlay holds the various CrOS toolchain packages.

There is a single `cross-*-linux-*` directory as all of our Linux toolchains use
the same underlying packages.  This isn't a strict requirement to keep in case
we ever want to change or tweak one target, but it makes management a little bit
easier.
