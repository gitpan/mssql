#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Streamtokens.pm 2     99-01-30 16:57 Sommar $
#
# $History: Streamtokens.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Streamtokens;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(SQLCOLFMT OLD_SQLCOLFMT SQLPROCID SQLCOLNAME
             SQLTABNAME SQLCOLINFO SQLALTNAME SQLALTFMT SQLERROR
             SQLINFO SQLRETURNVALUE SQLRETURNSTATUS SQLRETURN SQLCONTROL
             SQLALTCONTROL SQLROW SQLALTROW SQLDONE SQLDONEPROC
             SQLDONEINPROC SQLOFFSET SQLORDER SQLLOGINACK);

@ISA = qw(Exporter);

# Data stream tokens
sub SQLCOLFMT {       0xa1}
sub OLD_SQLCOLFMT {   0x2a}
sub SQLPROCID {       0x7c}
sub SQLCOLNAME {      0xa0}
sub SQLTABNAME {      0xa4}
sub SQLCOLINFO {      0xa5}
sub SQLALTNAME {      0xa7}
sub SQLALTFMT {       0xa8}
sub SQLERROR {        0xaa}
sub SQLINFO {         0xab}
sub SQLRETURNVALUE {  0xac}
sub SQLRETURNSTATUS {  0x79}
sub SQLRETURN {       0xdb}
sub SQLCONTROL {      0xae}
sub SQLALTCONTROL {   0xaf}
sub SQLROW {          0xd1}
sub SQLALTROW {       0xd3}
sub SQLDONE {         0xfd}
sub SQLDONEPROC {     0xfe}
sub SQLDONEINPROC {   0xff}
sub SQLOFFSET {       0x78}
sub SQLORDER {        0xa9}
sub SQLLOGINACK {     0xad} # NOTICE: change to real value

1;
