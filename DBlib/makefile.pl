#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/makefile.pl 3     00-09-09 18:13 Sommar $
#
# Makefile.pl for MSSQL::DBlib. Note that you need to tell where you
# have the include and library files for DB-Library.
#
# $History: makefile.pl $
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 00-09-09   Time: 18:13
# Updated in $/Perl/MSSQL/DBlib
# Library files for SQL Server in a new place.
#
# *****************  Version 2  *****************
# User: Admin        Date: 99-02-25   Time: 22:31
# Updated in $/Perl/MSSQL/DBlib
# Moved my SQL tools to a new place.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 17:06
# Created in $/Perl/MSSQL/DBlib
#---------------------------------------------------------------------


use ExtUtils::MakeMaker;

# This is where I have my DBlib files, where are yours?
$SQLDIR  = '"F:\Program\Microsoft SQL Server\80\Tools\DevTools"';

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

