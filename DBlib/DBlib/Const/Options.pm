#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Options.pm 2     99-01-30 16:57 Sommar $
#
# $History: Options.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Options;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(DBBUFFER DBOFFSET DBROWCOUNT DBSTAT
             DBTEXTLIMIT DBTEXTSIZE DBARITHABORT DBARITHIGNORE DBNOAUTOFREE
             DBNOCOUNT DBNOEXEC DBPARSEONLY DBSHOWPLAN DBSTORPROCID
             DBANSItoOEM DBOEMtoANSI DBCLIENTCURSORS DBSETTIME DBQUOTEDIDENT
            );

@ISA = qw(Exporter);

# dboptions
sub DBBUFFER {         0}
sub DBOFFSET {         1}
sub DBROWCOUNT {       2}
sub DBSTAT {           3}
sub DBTEXTLIMIT {      4}
sub DBTEXTSIZE {       5}
sub DBARITHABORT {     6}
sub DBARITHIGNORE {    7}
sub DBNOAUTOFREE {     8}
sub DBNOCOUNT {        9}
sub DBNOEXEC {         10}
sub DBPARSEONLY {      11}
sub DBSHOWPLAN {       12}
sub DBSTORPROCID {     13}
sub DBANSItoOEM  { 14}
sub DBOEMtoANSI  { 15}
sub DBCLIENTCURSORS {  16}
sub DBSETTIME {  17}
sub DBQUOTEDIDENT {  18}

1;
