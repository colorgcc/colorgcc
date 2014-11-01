colorgcc (1.3.3):
-----------------
A wrapper to colorize the output from compilers whose messages
match the "gcc" format.

Requires the ANSIColor module from CPAN.

Usage:
------
Option 1)
In a directory that occurs in your PATH _before_ the directory
where the compiler lives, create a softlink to colorgcc for
each compiler you want to colorize:

   g++ -> colorgcc
   gcc -> colorgcc
   cc  -> colorgcc
   etc.

That's it. When "g++" is invoked, colorgcc is run instead.
colorgcc looks at the program name to figure out which compiler to run.

Option 2)
In a directory in your PATH, create the following links to colorgcc:
   color-g++ -> colorgcc
   color-c++ -> colorgcc
   color-gcc -> colorgcc
   color-cc  -> colorgcc
Then override the compiler macros for make, for example:
   make CXX=color-g++ CC=color-gcc

The default settings can be overridden with ~/.colorgccrc.
See the comments in the sample .colorgccrc for more information.

Note:
-----
colorgcc will only emit color codes if:

   (1) Its STDOUT is a tty and
   (2) the value of $TERM is not listed in the "nocolor" option.

If colorgcc colorizes the output, the compiler's STDERR will be
combined with STDOUT. Otherwise, colorgcc just passes the output from
the compiler through without modification.

----------------------------------------
Author: Jamie Moyers <jmoyers@geeks.com>
Started: April 20, 1999
Licence: GNU Public License
----------------------------------------

Credits:
--------
   I got the idea for this from a script called "color_cvs":
      color_cvs .03   Adrian Likins <adrian@gimp.org> <adrian@redhat.com>

   <seh4@ix.netcom.com> (Scott Harrington)
      Much improved handling of compiler command line arguments.
      exec compiler when not colorizing to preserve STDOUT, STDERR.
      Fixed my STDIN kludge.

   <ecarotti@athena.polito.it> (Elias S. G. Carotti)
      Corrected handling of text like -DPACKAGE=\"Package\"
      Spotted return code bug.

   <erwin@erwin.andreasen.org> (Erwin S. Andreasen)
   <schurchi@ucsd.edu> (Steve Churchill)
      Return code bug fixes.

   <rik@kde.org> (Rik Hemsley)
      Found STDIN bug.

   <deekej@linuxmail.org> (Dee'Kej)
      1.3.3 changes.

Changes:
--------
1.3.3 Regular expression for source code outputs fixed.

      Overtaken updates improvements from colorgcc-1.3.2.0-10 of Ubuntu
      version (trusty).

      Color output has been refined -- to provide bigger control of which
      part of the output has which color -- with possible improvements
      in the future to adapt the changes of GCC output.

1.3.2 Better handling of command line arguments to compiler.

      If we aren't colorizing output, we just exec the compiler which
      preserves the original STDOUT and STDERR.

      Removed STDIN kludge. STDIN being passed correctly now.

1.3.1 Added kludge to copy STDIN to the compiler's STDIN.

1.3.0 Now correctly returns (I hope) the return code of the compiler
      process as its own.

1.2.1 Applied patch to handle text similar to -DPACKAGE=\"Package\".

1.2.0 Added tty check. If STDOUT is not a tty, don't do color.

1.1.0 Added the "nocolor" option to turn off the color if the terminal type
      ($TERM) is listed.

1.0.0 Initial Version

