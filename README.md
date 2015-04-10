# `colorgcc`

A wrapper (Perl script) to colorize the output of `gcc`/`g++` compilers.

- Version: 1.4.4
- Original author:      [Jamie Moyers](mailto:jmoyers@geeks.com)
- Recent maintainer and contributors: 
                        [olibre](https://github.com/olibre)
                      , [Nikita Malyavin (FooBarrior)](https://github.com/FooBarrior)
                      , [Juan Batiz-Benet](https://github.com/jbenet)
                      , [Steven Honeyman](https://github.com/stevenhoneyman)
                      , [Johannes Schlüter](https://github.com/johannes)
                      , [Zuyi Hu](https://github.com/hzy199411)
                      , [Adam Nielsen (Malvineous)](https://github.com/Malvineous)
                      , [Karl Fessel](https://github.com/fesselk)
                      , [James E. Flemer](https://github.com/jflemer)
- Earlier contributors: [Adrian Likins](mailto:adrian@redhat.com)
                      , [Scott Harrington](mailto:seh4@ix.netcom.com)
                      , [Elias S. G. Carotti](mailto:ecarotti@athena.polito.it)
                      , [Erwin S. Andreasen](mailto:erwin@erwin.andreasen.org)
                      , [Steve Churchill](mailto:schurchi@ucsd.edu)
                      , [Rik Hemsley](mailto:rik@kde.org)
- Started: April 20, 1999
- GNU General Public License v2 (see file [`LICENSE`](LICENSE))

## Requirements

- A terminal that groks color escape sequences
- Perl module ANSIColor.pm (available at www.cpan.org)
- Perl modules Open3, Basename, Spec and Cwd

## Install

Copy `colorgcc` in a directory of your choice (e.g. `~/bin`).

Then create symlinks pointing to `colorgcc`. There are two options described above.

The directory where these links are created must be placed in `$PATH` **before** the directory where the compiler lives.

### Option 1

Create a link to `colorgcc` for each compiler you want to colorize:

    > ls
    colorgcc
    > ln -sv colorgcc gcc; ln -sv colorgcc g++; ln -sv colorgcc cc; ln -sv colorgcc c++;
    gcc -> colorgcc
    g++ -> colorgcc
    cc  -> colorgcc
    c++ -> colorgcc
    > PATH="$(pwd):$PATH"

When `g++` is invoked, `colorgcc` is run instead and looks at the program name to figure out which compiler to run.
The right compiler is then searched within the rest of the `$PATH`.

### Option 2

Create links to `colorgcc` using composed filenames:

    color-g++ -> colorgcc
    color-c++ -> colorgcc
    color-gcc -> colorgcc
    color-cc  -> colorgcc
   
Then override the compiler macros for `make`:

    make CXX=color-g++ CC=color-gcc

## Configuration

The default settings can be overridden with `~/.colorgccrc`.

See the comments in the sample `.colorgccrc` for more information.

## Note

`colorgcc` will only emit color codes if:

1. Its STDOUT is a tty and
2. the value of $TERM is not listed in the "nocolor" option.

If `colorgcc` colorizes the output, the compiler's STDERR will be
combined with STDOUT. Otherwise, `colorgcc` just passes the output from
the compiler through without modification.

## Gotchas

Packages that use `autoconf` (`./configure`) apparently determine
the default location of `$prefix` from the location of `gcc`. 
If you create the links as recommended above, `$prefix` will become
**that** directory instead of what it should be (`/usr/local` for
example). 

It's easy to get around this by giving an explicit `--prefix=/usr/local`
when you configure a package, but it's a minor annoyance.
