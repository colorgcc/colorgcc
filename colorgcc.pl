#! /usr/bin/perl -w

#
# colorgcc
#
# Version: 1.3.2
#
# $Id: colorgcc,v 1.10 1999/04/29 17:15:52 jamoyers Exp $
#
# A wrapper to colorize the output from compilers whose messages
# match the "gcc" format.
#
# Requires the ANSIColor module from CPAN.
#
# Usage:
#
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
# Credits:
#
#    I got the idea for this from a script called "color_cvs":
#       color_cvs .03   Adrian Likins <adrian@gimp.org> <adrian@redhat.com>
#
#    <seh4@ix.netcom.com> (Scott Harrington)
#       Much improved handling of compiler command line arguments.
#       exec compiler when not colorizing to preserve STDOUT, STDERR.
#       Fixed my STDIN kludge.
#       
#    <ecarotti@athena.polito.it> (Elias S. G. Carotti)
#       Corrected handling of text like -DPACKAGE=\"Package\"
#       Spotted return code bug.
#
#    <erwin@erwin.andreasen.org> (Erwin S. Andreasen)
#    <schurchi@ucsd.edu> (Steve Churchill)
#       Return code bug fixes.
#
#    <rik@kde.org> (Rik Hemsley)
#       Found STDIN bug.
#
# Changes:
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

use Term::ANSIColor;
use IPC::Open3;

sub initDefaults
{
   $compilerPaths{"gcc"} = "/usr/bin/gcc";
   $compilerPaths{"g++"} = "/usr/bin/g++";
   $compilerPaths{"cc"}  = "/usr/bin/gcc";
   $compilerPaths{"c++"} = "/usr/bin/g++";
   $compilerPaths{"g77"} = "/usr/bin/g77";
   $compilerPaths{"f77"} = "/usr/bin/g77";
   $compilerPaths{"gcj"} = "/usr/bin/gcj";

   $nocolor{"dumb"} = "true";

   $colors{"srcColor"} = color("cyan");
   $colors{"introColor"} = color("blue");

   $colors{"warningFileNameColor"} = color("yellow");
   $colors{"warningNumberColor"}   = color("yellow");
   $colors{"warningMessageColor"}  = color("yellow");

   $colors{"errorFileNameColor"} = color("bold red");
   $colors{"errorNumberColor"}   = color("bold red");
   $colors{"errorMessageColor"}  = color("bold red");

   @{$translations{"warning"}} = ();
   @{$translations{"error"}}   = ();
}

sub loadPreferences
{
# Usage: loadPreferences("filename");

   my($filename) = @_;

   open(PREFS, "<$filename") || return;

   my $gccVersion;
   my $overrideCompilerPaths = 0;

   while(<PREFS>)
   {
      next if (m/^\#.*/);          # It's a comment.
      next if (!m/(.*):\s*(.*)/);  # It's not of the form "foo: bar".

      $option = $1;
      $value = $2;

      if ($option =~ m/\A(cc|c\+\+|gcc|g\+\+|g77|f77|gcj)\Z/)
      {
	 $compilerPaths{$option} = $value;
	 $overrideCompilerPaths  = 1;
      }
      elsif ($option eq "gccVersion")
      {
         $gccVersion = $value;
      }
      elsif ($option eq "nocolor")
      {
	 # The nocolor option lists terminal types, separated by
	 # spaces, not to do color on.
	 foreach $termtype (split(/\s+/, $value))
	 {
	    $nocolor{$termtype} = "true";
	 }
      }
      elsif ($option =~ m/(.+)Translations/)
      {
         @{$translations{$1}} = split(/\s+/, $value);
      }
      elsif ($option =~ m/Color$/)
      {
	 $colors{$option} = color($value);
      }
      else
      {
         # treat unknown options as user defined compilers
         $compilerPaths{$option} = $value;
      }
   }
   close(PREFS);

   # Append "-<gccVersion>" to user-defined compilerPaths
   if ($overrideCompilerPaths && $gccVersion) {
      $compilerPaths{$_} .= "-$gccVersion" foreach (keys %compilerPaths);
   }
}

sub srcscan
{
# Usage: srcscan($text, $normalColor)
#    $text -- the text to colorize
#    $normalColor -- The escape sequence to use for non-source text.

# Looks for text between ` and ', and colors it srcColor.

   my($line, $normalColor) = @_;

   my($srcon) = color("reset") . $colors{"srcColor"};
   my($srcoff) = color("reset") . $normalColor;

   $line = $normalColor . $line;

   # This substitute replaces `foo' with `AfooB' where A is the escape
   # sequence that turns on the the desired source color, and B is the
   # escape sequence that returns to $normalColor.
   $line =~ s/(\`|\')(.*?)\'/\`$srcon$2$srcoff\'/g;

   print($line, color("reset"));
}

#
# Main program
#

# Set up default values for colors and compilers.
initDefaults();

# Read the configuration file, if there is one.
$configFile = $ENV{"HOME"} . "/.colorgccrc";
$default_configFile = "/etc/colorgcc/colorgccrc";
if (-f $configFile)
{
   loadPreferences($configFile);
} elsif (-f $default_configFile ) {
   loadPreferences($default_configFile)
}

# Figure out which compiler to invoke based on our program name.
$0 =~ m%.*/(.*)$%;
$progName = $1 || $0;

$compiler = $compilerPaths{$progName} || $compilerPaths{"gcc"};
@comp_list = split /\s+/, $compiler;
$compiler = $comp_list[0];
@comp_args = ( @comp_list[1 .. $#comp_list], @ARGV );

# Check that we don't reference self
die "$compiler is self-referencing"
   if ( -l $compiler and (stat $compiler)[1] == (stat $0)[1] );

# Get the terminal type. 
$terminal = $ENV{"TERM"} || "dumb";

# If it's in the list of terminal types not to color, or if
# we're writing to something that's not a tty, don't do color.
if (! $ENV{"CGCC_FORCE_COLOR"} && (! -t STDOUT || $nocolor{$terminal}))
{
   exec $compiler, @comp_args
      or die("Couldn't exec");
}

# Keep the pid of the compiler process so we can get its return
# code and use that as our return code.
$compiler_pid = open3('<&STDIN', \*GCCOUT, \*GCCOUT, $compiler, @comp_args);
binmode(\*GCCOUT,":bytes");
binmode(\*STDOUT,":bytes");

# Colorize the output from the compiler.
while(<GCCOUT>)
{
   #if (m/^(.*?):([0-9]+):(.*)$/) # filename:lineno:message
   if (m/^(.*?):([0-9]+):([0-9]+):(.*)$/) # filename:lineNumber:columnNumber:message
   {
      $filename = $1 || "";
      $lineNumber = $2 || "";
      $columnNumber = $3 || "";
      $message = $4 || "";

      # See if this is a warning message.
      $is_warning = 0;
      for $translation ("warning", @{$translations{"warning"}})
      {
         if ($message =~ m/\s+$translation:(.*)/)
         {
            $tag=$translation;
            $message=$1;
            $is_warning = 1;
            last;
         }
      }
      # See if this is an error message.
      $is_error = 0;
      for $translation ("error", @{$translations{"error"}})
      {
         if ($message =~ m/\s+$translation:(.*)/)
         {
            $tag=$translation;
            $message=$1;
            $is_error = 1;
            last;
         }
      }

      if ($is_warning)
      {
	 # Warning
	 print($colors{"warningFileNameColor"}, "$filename:", color("reset"));
	 print($colors{"warningNumberColor"}, "$lineNumber:", color("reset"));
	 print($colors{"warningColumnNumberColor"}, "$columnNumber:", color("reset"));
	 print($colors{"warningTagColor"}, "$tag:", color("reset"));
	 srcscan($message, $colors{"warningMessageColor"});
      }
      elsif ($is_error)
      {
	 # Error
	 print($colors{"errorFileNameColor"}, "$filename:", color("reset"));
	 print($colors{"errorNumberColor"}, "$lineNumber:", color("reset"));
	 print($colors{"errorColumnNumberColor"}, "$columnNumber:", color("reset"));
	 print($colors{"errorTagColor"}, "$tag:", color("reset"));
	 srcscan($message, $colors{"errorMessageColor"});
      }
      else{
	 # Other
	 print($colors{"otherFileNameColor"}, "$filename:", color("reset"));
	 print($colors{"otherNumberColor"}, "$lineNumber:", color("reset"));
	 print($colors{"otherColumnNumberColor"}, "$columnNumber:", color("reset"));
	 srcscan($message, $colors{"otherMessageColor"});   
      }
      print("\n");
   }
   elsif (m/^(<command-line>):(.*)$/) # special-location:message
   {
      $filename = $1 || "";
      $lineNumber = $2 || "";

      # See if this is a warning message.
      $is_warning = 0;
      for $translation ("warning", @{$translations{"warning"}})
      {
         if ($lineNumber =~ m/\s+$translation:.*/)
         {
            $is_warning = 1;
            last;
         }
      }

      if ($is_warning)
      {
	 # Warning
	 print($colors{"warningFileNameColor"}, "$filename:", color("reset"));
	 srcscan($lineNumber, $colors{"warningMessageColor"});
      }
      else
      {
	 # Error
	 print($colors{"errorFileNameColor"}, "$filename:", color("reset"));
	 srcscan($lineNumber, $colors{"errorMessageColor"});
      }
      print("\n");
   }
   elsif (m/^(.*?):(.+):$/) # filename:message:
   {
      # No line number, treat as an "introductory" line of text.
      srcscan($_, $colors{"introColor"});
   }
   else # Anything else.        
   {
      # Doesn't seem to be a warning or an error. Print normally.
      print(color("reset"), $_);
   }
}

# Get the return code of the compiler and exit with that.
waitpid($compiler_pid, 0);
exit ($? >> 8);





