#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Errors.pm 2     99-01-30 16:57 Sommar $
#
# $History: Errors.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Errors;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(SQLEMEM SQLENULL SQLENLOG SQLEPWD
             SQLECONN SQLEDDNE SQLENULLO SQLESMSG SQLEBTOK
             SQLENSPE SQLEREAD SQLECNOR SQLETSIT SQLEPARM
             SQLEAUTN SQLECOFL SQLERDCN SQLEICN SQLECLOS
             SQLENTXT SQLEDNTI SQLETMTD SQLEASEC SQLENTLL
             SQLETIME SQLEWRIT SQLEMODE SQLEOOB SQLEITIM
             SQLEDBPS SQLEIOPT SQLEASNL SQLEASUL SQLENPRM
             SQLEDBOP SQLENSIP SQLECNULL SQLESEOF SQLERPND
             SQLECSYN SQLENONET SQLEBTYP SQLEABNC SQLEABMT
             SQLEABNP SQLEBNCR SQLEAAMT SQLENXID SQLEIFNB
             SQLEKBCO SQLEBBCI SQLEKBCI SQLEBCWE SQLEBCNN
             SQLEBCOR SQLEBCPI SQLEBCPN SQLEBCPB SQLEVDPT
             SQLEBIVI SQLEBCBC SQLEBCFO SQLEBCVH SQLEBCUO
             SQLEBUOE SQLEBWEF SQLEBTMT SQLEBEOF SQLEBCSI
             SQLEPNUL SQLEBSKERR SQLEBDIO SQLEBCNT SQLEMDBP
             SQLINIT SQLCRSINV SQLCRSCMD SQLCRSNOIND SQLCRSDIS
             SQLCRSAGR SQLCRSORD SQLCRSMEM SQLCRSBSKEY SQLCRSNORES
             SQLCRSVIEW SQLCRSBUFR SQLCRSFROWN SQLCRSBROL SQLCRSFRAND
             SQLCRSFLAST SQLCRSRO SQLCRSTAB SQLCRSUPDTAB SQLCRSUPDNB
             SQLCRSVIIND SQLCRSNOUPD SQLCRSOS2 SQLEBCSA SQLEBCRO
             SQLEBCNE SQLEBCSK SQLEUVBF SQLEBIHC SQLEBWFF
             SQLNUMVAL SQLEOLDVR SQLEBCPS SQLEDTC SQLENOTIMPL
             SQLENONFLOAT SQLECONNFB);

@ISA = qw(Exporter);

# Error numbers (dberrs) DB-Library error codes
sub SQLEMEM {          10000}
sub SQLENULL {         10001}
sub SQLENLOG {         10002}
sub SQLEPWD {          10003}
sub SQLECONN {         10004}
sub SQLEDDNE {         10005}
sub SQLENULLO {        10006}
sub SQLESMSG {         10007}
sub SQLEBTOK {         10008}
sub SQLENSPE {         10009}
sub SQLEREAD {         10010}
sub SQLECNOR {         10011}
sub SQLETSIT {         10012}
sub SQLEPARM {         10013}
sub SQLEAUTN {         10014}
sub SQLECOFL {         10015}
sub SQLERDCN {         10016}
sub SQLEICN {          10017}
sub SQLECLOS {         10018}
sub SQLENTXT {         10019}
sub SQLEDNTI {         10020}
sub SQLETMTD {         10021}
sub SQLEASEC {         10022}
sub SQLENTLL {         10023}
sub SQLETIME {         10024}
sub SQLEWRIT {         10025}
sub SQLEMODE {         10026}
sub SQLEOOB {          10027}
sub SQLEITIM {         10028}
sub SQLEDBPS {         10029}
sub SQLEIOPT {         10030}
sub SQLEASNL {         10031}
sub SQLEASUL {         10032}
sub SQLENPRM {         10033}
sub SQLEDBOP {         10034}
sub SQLENSIP {         10035}
sub SQLECNULL {        10036}
sub SQLESEOF {         10037}
sub SQLERPND {         10038}
sub SQLECSYN {         10039}
sub SQLENONET {        10040}
sub SQLEBTYP {         10041}
sub SQLEABNC {         10042}
sub SQLEABMT {         10043}
sub SQLEABNP {         10044}
sub SQLEBNCR {         10045}
sub SQLEAAMT {         10046}
sub SQLENXID {         10047}
sub SQLEIFNB {         10048}
sub SQLEKBCO {         10049}
sub SQLEBBCI {         10050}
sub SQLEKBCI {         10051}
sub SQLEBCWE {         10052}
sub SQLEBCNN {         10053}
sub SQLEBCOR {         10054}
sub SQLEBCPI {         10055}
sub SQLEBCPN {         10056}
sub SQLEBCPB {         10057}
sub SQLEVDPT {         10058}
sub SQLEBIVI {         10059}
sub SQLEBCBC {         10060}
sub SQLEBCFO {         10061}
sub SQLEBCVH {         10062}
sub SQLEBCUO {         10063}
sub SQLEBUOE {         10064}
sub SQLEBWEF {         10065}
sub SQLEBTMT {         10066}
sub SQLEBEOF {         10067}
sub SQLEBCSI {         10068}
sub SQLEPNUL {         10069}
sub SQLEBSKERR {       10070}
sub SQLEBDIO {         10071}
sub SQLEBCNT {         10072}
sub SQLEMDBP {         10073}
sub SQLINIT {          10074}
sub SQLCRSINV {        10075}
sub SQLCRSCMD {        10076}
sub SQLCRSNOIND {      10077}
sub SQLCRSDIS {        10078}
sub SQLCRSAGR {        10079}
sub SQLCRSORD {        10080}
sub SQLCRSMEM {        10081}
sub SQLCRSBSKEY {      10082}
sub SQLCRSNORES {      10083}
sub SQLCRSVIEW {       10084}
sub SQLCRSBUFR {       10085}
sub SQLCRSFROWN {      10086}
sub SQLCRSBROL {       10087}
sub SQLCRSFRAND {      10088}
sub SQLCRSFLAST {      10089}
sub SQLCRSRO {         10090}
sub SQLCRSTAB {        10091}
sub SQLCRSUPDTAB {     10092}
sub SQLCRSUPDNB {      10093}
sub SQLCRSVIIND {      10094}
sub SQLCRSNOUPD {      10095}
sub SQLCRSOS2 {        10096}
sub SQLEBCSA {         10097}
sub SQLEBCRO {         10098}
sub SQLEBCNE {         10099}
sub SQLEBCSK {         10100}
sub SQLEUVBF {         10101}
sub SQLEBIHC {         10102}
sub SQLEBWFF {         10103}
sub SQLNUMVAL {        10104}
sub SQLEOLDVR {        10105}
sub SQLEBCPS {   10106}
sub SQLEDTC {    10107}
sub SQLENOTIMPL {   10108}
sub SQLENONFLOAT {  10109}
sub SQLECONNFB {    10110}

1;
