#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/DBSETLNAME.pm 2     99-01-30 16:57 Sommar $
#
# $History: DBSETLNAME.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::DBSETLNAME;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(DBSETHOST DBSETUSER DBSETPWD DBSETAPP
             DBSETID DBSETLANG DBSETSECURE DBVER42 DBVER60
             DBSETLOGINTIME DBSETFALLBACK);

@ISA = qw(Exporter);

# Macros for dbsetlname()
sub DBSETHOST {  1}
sub DBSETUSER {  2}
sub DBSETPWD {   3}
sub DBSETAPP {   4}
sub DBSETID {    5}
sub DBSETLANG {  6}
sub DBSETSECURE {  7}
sub DBVER42 {     8}
sub DBVER60 {     9}
sub DBSETLOGINTIME {  10}
sub DBSETFALLBACK {  12}

1;
