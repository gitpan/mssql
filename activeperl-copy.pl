#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/activeperl-copy.pl 7     03-01-01 20:20 Sommar $
#
# A simple script for installing a binary under ActivePerl 5xx and up.
# PPM? I haven't learnt that, and anyway this is simple enough.
#
# $History: activeperl-copy.pl $
# 
# *****************  Version 7  *****************
# User: Sommar       Date: 03-01-01   Time: 20:20
# Updated in $/Perl/MSSQL
# Unlink destination before copying, because of File Exists error.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 03-01-01   Time: 18:53
# Updated in $/Perl/MSSQL
# Ehum, need \\ between "".
#
# *****************  Version 5  *****************
# User: Sommar       Date: 03-01-01   Time: 18:47
# Updated in $/Perl/MSSQL
# Need to trim $].
#
# *****************  Version 4  *****************
# User: Sommar       Date: 03-01-01   Time: 18:40
# Updated in $/Perl/MSSQL
# Fixed syntax error and updated message now that there is only one
# README.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 03-01-01   Time: 16:27
# Updated in $/Perl/MSSQL
# Now the script covers all of 5xx, 6xx and 8xx.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 00-05-04   Time: 23:03
# Updated in $/Perl/MSSQL
# Corrected error messages to point to the right README.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 00-05-01   Time: 22:27
# Updated in $/Perl/MSSQL
# Just updated incorrect description.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 17:07
# Created in $/Perl/MSSQL
#---------------------------------------------------------------------

use strict;
use File::Copy;

sub makedir {
    my($dir) = @_;
    mkdir $dir, 0755;
    if (not -d $dir) {
       die "Failed to create '$dir': $!\n";
    }
}

sub do_copy{
   my($src, $dest) = @_;
   if (-e $dest) {
      system(qq!attrib -r "$dest"!);
      unlink($dest);
   }
   print "Copying $src to $dest\n";
   copy($src, $dest) or die "Could not copy $src: $!\n";
   system(qq!attrib +r "$dest"!);
}

my $perltop = shift(@ARGV);
if (not $perltop) {
   $perltop = $^X;
   if ($perltop =~ /\\/) {
      my @perltop = split(/\\/, $perltop);
      pop(@perltop);
      pop(@perltop);
      $perltop = join('\\', @perltop);
   }
   else {
      my @PATH = split(/;/, $ENV{'PATH'});
      my $progname = $perltop;
      $progname = "$progname.EXE" unless $progname =~ /.exe$/i;
      undef $perltop;
      while (@PATH) {
         if (-e "$PATH[0]\\$progname") {
            $perltop = $PATH[0];
            my @perltop = split(/\\/, $perltop);
            pop(@perltop);
            $perltop = join('\\', @perltop);
            last;
         }
         shift @PATH;
      }
   }
}

my $ver = substr($], 0, 5);

if (not (grep ($_ == $ver, (5.005, 5.006, 5.008)))) {
   print "You have Perl version $ver, but this install kit includes only binaries\n";
   print "for ActivePerl 5xx, 6xx and 8xx (Perl 5.005, 5.6 and 5.8 respectively).\n";
   print "You will need to install from sources. See README.html.\n";
   exit 245;
}

print "Installing MSSQL modules in $perltop\n";

my $libdir  = "$perltop\\site\\lib\\Mssql";
my $autodir = "$perltop\\site\\lib\\auto\\Mssql";
makedir($libdir);
makedir("$libdir\\DBlib");
makedir("$libdir\\DBlib\\Const");
makedir($autodir);
makedir("$autodir\\DBlib");

do_copy("blib\\arch\\auto\\MSSQL\\DBlib\\DBlib-$ver.dll",
        "$autodir\\DBlib\\DBlib.dll");


do_copy('DBlib\DBlib.pm',       "$libdir\\DBlib.pm");
do_copy('DBlib\DBlib\Const.pm', "$libdir\\DBlib\\Const.pm");
do_copy('Sqllib\Sqllib.pm',     "$libdir\\Sqllib.pm");

opendir(D, 'DBlib\\DBlib\\Const');
my @const_files = readdir(D);
@const_files = grep(/\.pm$/i, @const_files);
closedir(D);

my $file;
foreach $file (@const_files) {
   do_copy("DBlib\\DBlib\\Const\\$file", "$libdir\\DBlib\\Const\\$file");
}

