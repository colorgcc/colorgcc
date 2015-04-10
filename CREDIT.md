`colorgcc` has continuously improved over the last 16 years
thanks to the following people:

#### Adrian Likins <adrian@redhat.com> ####

   `color_cvs` gave the idea for `colorgcc`.

#### Jamie Moyers <jmoyers@geeks.com> ####

   Wrote and maintained `colorgcc` until version 1.3.2.

#### Scott Harrington <seh4@ix.netcom.com> ####

   General solution to the escape chars in compiler command line
   args problem.

   exec compiler when not colorizing to preserve STDOUT, STDERR.

   Fixed the STDIN kludge.

#### Elias S. G. Carotti <ecarotti@athena.polito.it> ####

   Corrected handling of text like -DPACKAGE=\"Package\"

   Spotted return code bug.

#### Erwin S. Andreasen <erwin@erwin.andreasen.org> ####

   Return code bug fix.

#### Steve Churchill <schurchi@ucsd.edu> ####

   Return code bug fix.

#### Rik Hemsley <rik@kde.org> ####

   Found STDIN bug.

#### [olibre](https://github.com/olibre) ####

   Added function `findPath()` to search compiler within `$PATH`.
   
   More highlighting lines: "instanciated from", "note:" and linker error.

#### [Karl Fessel](https://github.com/fesselk) ####

   [gentoo-patches](https://github.com/fesselk/colorgcc/commit/5f458441c225a4c5e69ea7b9097e31aabc4cc816) 
   to colorize Notes, to indetify color and to clean the *2 space indetion*.

#### [Steven Honeyman](https://github.com/stevenhoneyman) ####

   Added detection for `GCC_COLORS` environment variable (GCC-4.9 `-fdiagnostics-color`).

#### [Nikita Malyavin (FooBarrior)](https://github.com/FooBarrior) ####
 
   Added chainedPath option for using `colorgcc` in chain with other tools (e.g. `ccache`).
   
   Also cleaned up path lookup and other minor stuff.
   
   His contribution solves [Archlinux bug #41423](https://bugs.archlinux.org/task/41423).

#### [Markus Döring (burgerdev)](https://github.com/burgerdev) ####

   Repported bug [*undefined* directory while parsing `$PATH`](https://github.com/olibre/colorgcc/issues/3).
   
#### [Zuyi Hu](https://github.com/hzy199411) ####

   Fixed the above bug [*undefined* directory while parsing `$PATH`](https://github.com/olibre/colorgcc/issues/3).


