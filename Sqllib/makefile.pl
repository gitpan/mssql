#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/sqllib/makefile.pl 1     99-01-30 17:06 Sommar $
#
# Makefile.pl for MSSQL::Sqllib.
#
# $History: makefile.pl $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 17:06
# Created in $/Perl/MSSQL/sqllib
#---------------------------------------------------------------------


use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'MSSQL::Sqllib',
    'VERSION_FROM' => 'Sqllib.pm',
    'PREREQ_PM'    => {'MSSQL::DBlib' => 0}
);

