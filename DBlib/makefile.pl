#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/makefile.pl 1     99-01-30 17:06 Sommar $
#
# Makefile.pl for MSSQL::DBlib. Note that you need to tell where you
# have the include and library files for DB-Library.
#
# $History: makefile.pl $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 17:06
# Created in $/Perl/MSSQL/DBlib
#---------------------------------------------------------------------


use ExtUtils::MakeMaker;
$SQLDIR  = 'C:\SQL65\DBLIB';    # This is where I have my DBlib files, where are yours?
#$SQLDIR  = 'E:\MSSQL7\DEVTOOLS';
WriteMakefile(
    'DEFINE'       => '-DCORE_PORT',
    'INC'          => "-I$SQLDIR\\INCLUDE",
    'NAME'         => 'MSSQL::DBlib',
    'LIBS'         => 'kernel32',  # Work-around for problem with AS 507.
    'OBJECT'       => 'DBlib$(OBJ_EXT)' . ' ' . "$SQLDIR\\LIB\\Ntwdblib.lib",
    'PMLIBDIRS'    => ['DBlib'],
    'VERSION_FROM' => 'DBlib.pm',
    'XS'           => { 'DBlib.xs' => 'DBlib.cpp' },
    'dynamic_lib'  => { OTHERLDFLAGS => '/base:"0x278600000"'}
    # Set base address to avoid DLL collision, makes startup speedier. Remove
    # if your compiler don't have this option.
);

sub MY::xs_c {
    '
.xs.cpp:
   $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

