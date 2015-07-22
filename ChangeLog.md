#### 1.4.4 ####

   [Zuyi Hu](https://github.com/hzy199411) fixed the 
   [*undefined* directory while parsing `$PATH`](https://github.com/olibre/colorgcc/issues/3) 
   repported by [Markus Döring (burgerdev)](https://github.com/burgerdev).

#### 1.4.3 ####

   [Nikita Malyavin (FooBarrior)](https://github.com/FooBarrior) 
   added chainedPath option for using `colorgcc` in chain with other tools (e.g. `ccache`).
   He also cleaned up path lookup and other minor stuff.
   His contribution solves [Archlinux bug #41423](https://bugs.archlinux.org/task/41423).

#### 1.4.2 ####

   [Steven Honeyman](https://github.com/stevenhoneyman) 
   added detection for `GCC_COLORS` environment variable (GCC-4.9 `-fdiagnostics-color`)

#### 1.4.1 ####

   Merged with [gentoo-patches](https://github.com/fesselk/colorgcc/commit/5f458441c225a4c5e69ea7b9097e31aabc4cc816) 
   from [Karl Fessel](https://github.com/fesselk)

#### 1.4.0 ####

   [olibre](https://github.com/olibre) added function `findPath()` to search compiler within `$PATH`.
   More highlighting lines: "instanciated from", "note:" and linker error 

#### 1.3.2 ####

   Better handling of command line arguments to compiler.

   If not colorizing output, just exec the compiler to
   preserve the original STDOUT and STDERR.

   Removed STDIN kludge. STDIN is passed correctly now.

#### 1.3.1 ####

   Added kludge to pass contents of STDIN to the compiler if we're
   not running from a tty. Some tools (`imake`) pass input on STDIN.

#### 1.3.0 ####

   Modified the colorizing loop to be more strict. It was colorizing 
   text that looked almost, but not quite exactly like, warning
   and error messages.
	
   `colorgcc` was not exiting with the return code of the compiler process,
   confusing `make`. Fixed.

   Added a "Gotcha" section to the INSTALL.
	
   Added a CREDITS file.

   Added a COPYING file (GPLv2) renamed later to LICENSE.

#### 1.2.1 ####

   Applied patch to correct handling of escaped characters in compiler output.

#### 1.2.0 ####

   First public release.

   Added tty check: if STDOUT is not a tty, don't do color.


#### 1.1.0 ####

   Added the "nocolor" option to turn off the color 
   if the terminal type ($TERM) is listed.

#### 1.0.0 ####

   Initial Version
