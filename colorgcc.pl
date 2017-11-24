#!/usr/bin/perl -w

#
# colorgcc
#
# Version: 1.4.5
#
#
# A wrapper to colorize the output from compilers whose messages
# match the "gcc" format.
#
# Requires the ANSIColor module from CPAN.
#
# Usage:
#
# Option 1)
# In a directory that occurs in your PATH _before_ the directory
# where the compiler lives, create a softlink to colorgcc for
# each compiler you want to colorize:
#
#    g++ -> colorgcc
#    gcc -> colorgcc
#    cc  -> colorgcc
#    etc.
#
# That's it. When "g++" is invoked, colorgcc is run instead.
# colorgcc looks at the program name to figure out which compiler to run.
#
# Option 2)
# In a directory in your PATH, create the following links to colorgcc:
#    color-g++ -> colorgcc
#    color-c++ -> colorgcc
#    color-gcc -> colorgcc
#    color-cc  -> colorgcc
# Then override the compiler macros for make, for example:
#    make CXX=color-g++ CC=color-gcc
#
# The default settings can be overridden with ~/.colorgccrc.
# See the comments in the sample .colorgccrc for more information.
#
# Note:
#
# colorgcc will only emit color codes if:
#
#    (1) Its STDOUT is a tty and
#    (2) the value of $TERM is not listed in the "nocolor" option.
#
# If colorgcc colorizes the output, the compiler's STDERR will be
# combined with STDOUT. Otherwise, colorgcc just passes the output from
# the compiler through without modification.
#
# Author: Jamie Moyers <jmoyers@geeks.com>
# Started: April 20, 1999
# Licence: GNU Public License
#
# Credits (alphabetically):
#
#    Adam Nielsen <malvineous@shikadi.net>
#    Adrian Likins <adrian@gimp.org> <adrian@redhat.com>
#    Elias S. G. Carotti <ecarotti@athena.polito.it>
#    James E. Flemer <jflemer@alum.rpi.edu>
#    Johannes Schlüter <johannes@schlueters.de>
#    Juan Batiz-Benet <jbenet@cs.stanford.edu>
#    Rik Hemsley <rik@kde.org>
#    Scott Harrington <seh4@ix.netcom.com>
#    Steve Churchill <schurchi@ucsd.edu>
#    Steven Honeyman <stevenhoneyman@users.noreply.github.com>
#    Zuyi Hu <hzy068808@gmail.com>
#    foobarrior <nikitamalyavin@gmail.com>
#    olibre <olibre@Lmap.org>
#
#
###################################################################################
#
# Changes:
#
# 1.4.5  FooBarrior added chainedPath option for using colorgcc in chain with other tools (e.g. ccache)
#        He also cleaned up path lookup and other minor stuff
#        His contribution solves Archlinux bug #41423

# 1.4.2 Added detection for GCC_COLORS environment variable (gcc 4.9 -fdiagnostics-color)
#
# 1.4.1 Merged with gentoo-patches from fesselk
#       https://github.com/fesselk/colorgcc/commit/5f458441c225a4c5e69ea7b9097e31aabc4cc816
#
# 1.4.0 Search compiler within $PATH -> added function findPath()
#       More highlighting lines: "instanciated from", "note:" and linker error 
#
# 1.3.2 Better handling of command line arguments to compiler.
#
#       If we aren't colorizing output, we just exec the compiler which
#       preserves the original STDOUT and STDERR.
#
#       Removed STDIN kludge. STDIN being passed correctly now.
#
# 1.3.1 Added kludge to copy STDIN to the compiler's STDIN.
#
# 1.3.0 Now correctly returns (I hope) the return code of the compiler
#       process as its own.
#
# 1.2.1 Applied patch to handle text similar to -DPACKAGE=\"Package\".
#
# 1.2.0 Added tty check. If STDOUT is not a tty, don't do color.
#
# 1.1.0 Added the "nocolor" option to turn off the color if the terminal type
#       ($TERM) is listed.
#
# 1.0.0 Initial Version

use strict;
use warnings;

use List::Util 'first';
use IPC::Open3;
use File::Basename;
use File::Spec;
use Cwd 'abs_path';

use Term::ANSIColor;

my(%nocolor, %colors, %compilerPaths, %options);
my($unfinishedQuote, $previousColor);

sub initDefaults
{
  $options{"chainedPath"} = "0";
  $nocolor{"dumb"} = "true";

  $colors{"srcColor"}             = color("bold white");
  $colors{"identColor"}           = color("bold green"); 
  $colors{"introColor"}           = color("bold green");

  $colors{"introFileNameColor"} = color("blue");
  $colors{"introMessageColor"}  = color("blue");

  $colors{"noteFileNameColor"}    = color("bold cyan");
  $colors{"noteNumberColor"}      = color("bold white");
  $colors{"noteMessageColor"}     = color("bold cyan");

  $colors{"warningFileNameColor"} = color("bold cyan");
  $colors{"warningNumberColor"}   = color("bold white");
  $colors{"warningMessageColor"}  = color("bold yellow");

  $colors{"errorFileNameColor"}   = color("bold cyan");
  $colors{"errorNumberColor"}     = color("bold white");
  $colors{"errorMessageColor"}    = color("bold red");
}

sub loadPreferences
{
  # Usage: loadPreferences("filename");

  my($filename) = @_;

  open(PREFS, "<$filename") || return;

  while(<PREFS>)
  {
    next if (m/^\#.*/);          # It's a comment.
    next if (!m/(.*):\s*(.*)/);  # It's not of the form "foo: bar".

    my $option = $1;
    my $value = $2;

    if ($option eq "nocolor")
    {
      # The nocolor option lists terminal types, separated by
      # spaces, not to do color on.
      foreach my $term (split(' ', $value))
      {
        $nocolor{$term} = 1;
      }
    }
    elsif (defined $colors{$option})
    {
      $colors{$option} = color($value);
    }
    elsif (defined $options{$option})
    {
      $options{$option} = $value;
    }
    else
    {
      $compilerPaths{$option} = $value;
    }
  }
  close(PREFS);
}

sub srcscan
{
  # Usage: srcscan($text, $normalColor)
  #    $text -- the text to colorize
  #    $normalColor -- The escape sequence to use for non-source text.

  # Looks for text between ` and ', and colors it srcColor.

  my($line, $normalColor) = @_;

  if (defined $normalColor)
  {
    $previousColor = $normalColor;
  }
  else
  {
    $normalColor = $previousColor;
  }

  # These substitutions replace `foo' with `AfooB' where A is the escape
  # sequence that turns on the the desired source color, and B is the
  # escape sequence that returns to $normalColor.

  my($srcon)  = color("reset") . $colors{"srcColor"};
  my($srcoff) = color("reset") . $normalColor;

  $line = ($unfinishedQuote? $srcon : $normalColor) . $line;

  # Handle multi-line quotes.
  if ($unfinishedQuote) {
    if ($line =~ s/^([^\`]*?)\'/$1$srcoff\'/)
    {
      $unfinishedQuote = 0;
    }
  }
  if ($line =~ s/\`([^\']*?)$/\`$srcon$1/)
  {
    $unfinishedQuote = 1;
  }

  # Single line quoting.
  $line =~ s/\`(.*?)\'/\`$srcon$1$srcoff\'/g;

  # This substitute replaces ‘foo’ with ‘AfooB’ where A is the escape
  # sequence that turns on the the desired identifier color, and B is the
  # escape sequence that returns to $normalColor.
  my($identon)  = color("reset") . $colors{"identColor"};
  my($identoff) = color("reset") . $normalColor;

  $line =~ s/\‘(.*?)\’/\‘$identon$1$identoff\’/g;

  print($line, color("reset"));
}

#
# Main program
#

# Set up default values for colors and compilers.
initDefaults();

# Read the configuration file, if there is one.
my $configFile = $ENV{"HOME"} . "/.colorgccrc";
if (-f $configFile)
{
  loadPreferences($configFile);
}
elsif (-f '/etc/colorgcc/colorgccrc')
{
  loadPreferences('/etc/colorgcc/colorgccrc');
}

# Set our default output color.  This presumes that any unrecognized output
# is an error.
$previousColor = $colors{"errorMessageColor"};

sub unique{
  my %seen = ();
  grep { ! $seen{ $_ }++ } @_;
}

sub canExecute{
  warn "$_ is found but is not executable; skipping." if -e !-x;
  -x
}

#inspired from Thierry's snippet (Tve, 4-Jul-2002)
#http://www.tek-tips.com/viewthread.cfm?qid=305851
sub findPath
{
  my $program = shift;

  # Load the path
  my @path = File::Spec->path();

  #join paths with program name and get absolute path
  @path = unique map { grep defined($_), abs_path( File::Spec->join( $_, $program ) ) } @path;
  my $progPath = abs_path( $0 );

  if ($options{chainedPath})
  {
    my $lastPath;
    foreach (reverse @path)
    {
      return $lastPath if $_ eq $progPath;
      $lastPath = $_ if -x;
    }
  }
  else
  {
    # Find first file spec in paths, that
    # is not current program's file spec;
    # is executable
    return first { $_ ne $progPath and canExecute( $_ ) } @path;
  }
}

my $progName = fileparse $0;

# See if the user asked for a specific compiler.
my $compiler = 
$compilerPaths{$progName} || findPath($progName) || 
$compilerPaths{"gcc"}     || findPath("gcc");

# Get the terminal type.
my $terminal = $ENV{"TERM"} || "dumb";

# If it's in the list of terminal types not to color, or if
# GCC (in version 4.9+) is set to do its own coloring, or if
# we're writing to something that's not a tty, don't do color.
if (! -t STDOUT || $nocolor{$terminal} || defined $ENV{"GCC_COLORS"})
{
  exec $compiler, @ARGV
  or die("Couldn't exec");
}

# Keep the pid of the compiler process so we can get its return
# code and use that as our return code.
my $compiler_pid = open3('<&STDIN', \*GCCOUT, \*GCCOUT, $compiler, @ARGV);

# Colorize the output from the compiler.
while(<GCCOUT>)
{
  if (m#^(.+?\.[^:/ ]+):([0-9]+):(.*)$#) # filename:lineno:message
  {
    my $field1 = $1 || "";
    my $field2 = $2 || "";
    my $field3 = $3 || "";

    if (/instantiated from /)
    {
      srcscan($_, $colors{"introColor"})
    }
    elsif ($field3 =~ m/\s+note:.*/)
    {
      # Note
      print($colors{"noteFileNameColor"}, "$field1:", color("reset"));
      print($colors{"noteNumberColor"},   "$field2:", color("reset"));
      srcscan($field3, $colors{"noteMessageColor"});
    }
    elsif ($field3 =~ m/\s+warning:.*/)
    {
      # Warning
      print($colors{"warningFileNameColor"}, "$field1:", color("reset"));
      print($colors{"warningNumberColor"},   "$field2:", color("reset"));
      srcscan($field3, $colors{"warningMessageColor"});
    }
    elsif ($field3 =~ m/\s+error:.*/)
    {
      # Error
      print($colors{"errorFileNameColor"}, "$field1:", color("reset"));
      print($colors{"errorNumberColor"},   "$field2:", color("reset"));
      srcscan($field3, $colors{"errorMessageColor"});
    } 
    else
    {
      # Note
      print($colors{"noteFileNameColor"}, "$field1:", color("reset"));
      print($colors{"noteNumberColor"}, "$field2:", color("reset"));
      srcscan($field3, $colors{"noteMessageColor"});
    }
    print("\n");
  }
  elsif (m/(.+):\((.+)\):(.*)$/) # linker error
  {
    my $field1 = $1 || "";
    my $field2 = $2 || "";
    my $field3 = $3 || "";

    # Error
    print($colors{"errorFileNameColor"}, "$field1", color("reset"), ":(");
    print($colors{"errorNumberColor"},   "$field2", color("reset"), "):");
    srcscan($field3, $colors{"errorMessageColor"});
    print("\n");
  }
  elsif (m/^:.+`.*'$/) # filename:message:
  {
    srcscan($_, $colors{"warningMessageColor"});
  }
  elsif (m/^(.*?):(.+):$/) # filename:message:
  {
    my $field1 = $1 || "";
    my $field2 = $2 || "";
    # No line number, treat as an "introductory" line of text.
    print($colors{"introFileNameColor"}, "$field1:", color("reset"));
    srcscan($field2, $colors{"introMessageColor"});
    print("\n");
  }
  else # Anything else.
  {
    # Doesn't seem to be a warning or an error. Print normally.
    print(color("reset"), $_);
  }
}

if ($compiler_pid)
{
  # Get the return code of the compiler and exit with that.
  waitpid($compiler_pid, 0);
  exit ($? >> 8);
}
