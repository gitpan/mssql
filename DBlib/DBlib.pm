#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib.pm 8     03-01-01 15:15 Sommar $
# Copyright (c) 1991-1995 Michael Peppler
# Copyright (c) 1997-2003 Erland Sommarskog
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.
#
# $History: DBlib.pm $
# 
# *****************  Version 8  *****************
# User: Sommar       Date: 03-01-01   Time: 15:15
# Updated in $/Perl/MSSQL/DBlib
# Updated year in Copyright,
#
# *****************  Version 7  *****************
# User: Sommar       Date: 02-12-29   Time: 20:40
# Updated in $/Perl/MSSQL/DBlib
# Added END section to cleanup. This is good when running from things
# like PerlScript.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 02-12-26   Time: 23:11
# Updated in $/Perl/MSSQL/DBlib
# We'are at version 1.009 now.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 01-10-21   Time: 14:57
# Updated in $/Perl/MSSQL/DBlib
# Added dbgetmaxprocs and dbsetmaxprocs.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 01-05-01   Time: 22:38
# Updated in $/Perl/MSSQL/DBlib
# MSSQL::DBlib 1.008
#
# *****************  Version 3  *****************
# User: Sommar       Date: 00-04-24   Time: 23:06
# Updated in $/Perl/MSSQL/DBlib
# Incremented to MSSQL::DBlib 1.006
#
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 17:04
# Updated in $/Perl/MSSQL/DBlib
# Updated to MSSQL 1.005. Now includes a dbnextrow and dbretdata
# implmented in Perl.
#---------------------------------------------------------------------


package MSSQL::DBlib;

require 5.003;

use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $Version);

use Exporter;
require DynaLoader;   # C<use> gives warning with AS Perl.

$VERSION = '1.009';

@ISA = qw(Exporter  DynaLoader);

@EXPORT = qw(dbmsghandle dberrhandle dbexit dbprtype
             BCP_SETL dbsetlogintime dbsettime DBGETTIME
             DBSETLAPP DBSETLHOST DBSETLNATLANG DBSETLPACKET
             DBSETLPWD DBSETLSECURE DBSETLTIME DBSETLUSER
             DBSETLVERSION dbsetmaxprocs dbgetmaxprocs);
@EXPORT_OK = qw(reformat_uniqueid);

bootstrap MSSQL::DBlib;

# Alias dblogin to new:
*new = \&dblogin;

END {
   image_rundown();
}

# dbnextrow and dbretdata are provided here for compatibility.
sub dbnextrow {
    my($X, $doAssoc, $wantref) = @_;

    my ($stat, $dataref);

    $doAssoc = 0 if not $doAssoc;
    $stat = $X->dbnextrow2($dataref, $doAssoc);
    $X->{DBstatus} = $stat;

    if ($wantref) {
       return (defined $dataref ? $dataref : undef);
    }
    else {
       if (defined $dataref) {
          if ($wantref) {
             return $dataref;
          }
          elsif ($doAssoc) {
             return %$dataref;
          }
          elsif (wantarray) {
             return @$dataref;
          }
          else {
             # Looks weird to return the last element? Well, it's compatibility.
             return $$dataref[$#$dataref];
          }
       }
       else {
          return ();
       }
    }
}


sub dbretdata {
    my($X, $doAssoc, $wantref) = @_;

    my ($stat, $dataref);

    $doAssoc = 0 if not $doAssoc;
    $dataref = $X->dbretdata2($doAssoc);

    if ($wantref) {
       return $dataref;
    }
    elsif ($doAssoc) {
       return %$dataref
    }
    elsif (wantarray) {
        return @$dataref;
    }
    else {
        return $$dataref[$#$dataref];
    }
}

# This utility routine reformats a hex string to a proper GUID.
sub reformat_uniqueid {
   my($hexstr) = @_;

   # Strip any leading 0x.
   $hexstr =~ s/^0x//;
   $hexstr = "\U$hexstr\E";

   # Check format.
   if ($hexstr =~ /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}/) {
      return $hexstr;
   }
   if (length($hexstr) != 32) {
      return undef;
   }
   if ($hexstr =~ /[^0-9A-F]/) {
      return undef;
   }

   # Split into an array.
   my @hexstr = split(//, $hexstr);

   # Now bring them together:
   local($") = "";
   $hexstr = "@hexstr[6..7]@hexstr[4..5]@hexstr[2..3]@hexstr[0..1]-" .
             "@hexstr[10..11]@hexstr[8..9]-@hexstr[14..15]@hexstr[12..13]-" .
             "@hexstr[16..19]-@hexstr[20..31]";
}



1;
