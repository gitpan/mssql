#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Datatypes.pm 2     99-01-30 16:57 Sommar $
#
# $History: Datatypes.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Datatypes;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(SQLVOID SQLTEXT SQLVARBINARY SQLINTN
             SQLVARCHAR SQLBINARY SQLIMAGE SQLCHAR SQLINT1
             SQLBIT SQLINT2 SQLINT4 SQLMONEY SQLDATETIME
             SQLFLT8 SQLFLTN SQLMONEYN SQLDATETIMN SQLFLT4
             SQLMONEY4 SQLDATETIM4 SQLDECIMAL SQLNUMERIC SQLUNIQUEIDENTIFIER);

@ISA = qw(Exporter);

# Data Type Tokens
sub SQLVOID {         0x1f}
sub SQLTEXT {         0x23}
sub SQLVARBINARY {    0x25}
sub SQLINTN {         0x26}
sub SQLVARCHAR {      0x27}
sub SQLBINARY {       0x2d}
sub SQLIMAGE {        0x22}
sub SQLCHAR {         0x2f}
sub SQLINT1 {         0x30}
sub SQLBIT {          0x32}
sub SQLINT2 {         0x34}
sub SQLINT4 {         0x38}
sub SQLMONEY {        0x3c}
sub SQLDATETIME {     0x3d}
sub SQLFLT8 {         0x3e}
sub SQLFLTN {         0x6d}
sub SQLMONEYN {       0x6e}
sub SQLDATETIMN {     0x6f}
sub SQLFLT4 {         0x3b}
sub SQLMONEY4 {       0x7a}
sub SQLDATETIM4 {     0x3a}
sub SQLDECIMAL {      0x6a}
sub SQLNUMERIC {      0x6c}

sub SQLUNIQUEIDENTIFIER {36}


1;
