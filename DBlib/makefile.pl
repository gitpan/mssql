#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/makefile.pl 2     99-02-25 22:31 Admin $
#
# Makefile.pl for MSSQL::DBlib. Note that you need to tell where you
# have the include and library files for DB-Library.
#
# $History: makefile.pl $
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
$SQLDIR  = 'F:\MSSQL7\DEVTOOLS';

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

