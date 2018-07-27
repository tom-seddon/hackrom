# Building

Prerequisites:

* Some kind of Unix with all the usual Unix stuff
* GNU Make
* [64tass](https://sourceforge.net/projects/tass64/)

To build, type `make` in the root of the working copy.

The ROM is written to `.build/hackrom.rom`.

You can check out the `original` branch to get code that builds a
byte-for-byte identical copy of the original ROM.

# Building the original code

See the `hackrom-1.18` folder. I tried building this on my Master 128,
using ADFS (there's more than 31 files...) and after several aeons it
produced a binary identical to the one supplied.

If you want to try it: rename `S.ROMROFF` to `S.RONROFF`. And maybe
convert the line endings. I've left this all as-is in the Git repo in
the interests of historical accuracy.
