# Hackrom

Handy utility ROM for the BBC Micro by James Bonfield and Stephen
Youell.

## Building

Prerequisites:

* Some kind of Unix with all the usual Unix stuff
* GNU Make
* [64tass](https://sourceforge.net/projects/tass64/)

To build, type `make`.

The ROM is written to `.build/hackrom.rom`.

You can check out the `original` branch to get code that builds a
byte-for-byte identical copy of the original ROM.

## Licence

From the original readme:

> This code is copyright 1993 by James Bonfield and Stephen Youell.
> You may copy and distribute copies of this source code provided that
> this copyright notice stays intact and that it is distributed
> without charge. You may modify this code and redistribute provided
> you clearly document your changes. This code carries no warranty and
> the authors do not hold themselves responsible for any death or
> mutilation caused by use of the code ;-)

There's probably a modern open source analogue to this...

## Original code

See the `hackrom-1.18` folder. I tried building this on my Master 128,
and it produced an identical binary to the one supplied.

If you want to try it: rename `S.ROMROFF` to `S.RONROFF`. And maybe
convert the line endings. I've left this all as-is in the Git repo in
the interests of historical accuracy.
