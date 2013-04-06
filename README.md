Scourge
=======
**( Single Celled Organisms Undergo Rapid Growth Enhancement )**

[Quick link to the 2010 prototype](http://www.rezmason.net/scourge/?numPlayers=2)

Scourge is a derivative of [Fungus](http://www.info-mac.org/viewtopic.php?t=4644), a game produced by [Ryan Koopmans](http://www.e-brains.com/) with [Jason Whong](http://jason.whong.org/) in 1992. Its core game mechanics are reminiscent of the rules of Go, Reversi, Tetris and Blokus. It is a fun and ruthless game that builds players' resolve and strains their friendships.

Scourge is written in [Haxe](http://www.haxe.org/), a highly versatile language that can compile to many, many platforms.

**NOTE: Scourge is currently built with Haxe 3 RC and Git-hosted haxelibs. Consequently it may be difficult to configure your build environment to build both Scourge and Haxe 2 projects easily.**

Scourge is written on top of a framework called the ROPES, which I'm developing simultaneously. While the ROPES primarily must support Scourge, it is designed to support the development of all sorts of turn-based games. At some point after Scourge is up and running, the ROPES will receive the attention it needs to stand alone as a separate project.

# Project Goals

I intend to achieve several things with this project:

+ Create a game with the same mechanics and gameplay on all platforms targetable by [NME](http://www.haxenme.org/)
+ Structure the development of the game with a unit testing framework (in this case, [MassiveUnit](https://github.com/massiveinteractive/MassiveUnit)... stop giggling)
+ Create a game framework called the ROPES that can be used to represent a large number of turn-based games
+ Ressurect the Fungus game variety, and expand on it with new and compelling game mechanics
+ Tell a compelling story with non-human characters
+ Release a game that costs money, but whose [source code is freely accessible](http://www.fsf.org/)
+ Write computer opponenets of various types
+ Create a game view that is based on OpenGL-style graphics APIs on multiple platforms
+ Create a game whose rules may be highly configurable at runtime
+ Implement multiplayer game support across all platforms, including chat support and multiplayer game configuration

# Contributing

If you have an interest in this project, please [contact me](mailto:jeremysachs@rezmason.net).

# Legal?

The source for Scourge and the ROPES is released under the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Scourge and the Ropes are trademarks of Jeremy Sachs. Blerp.
