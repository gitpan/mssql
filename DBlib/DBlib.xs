/*---------------------------------------------------------------------
 $Header: /Perl/MSSQL/DBlib/DBlib.xs 3     99-01-30 17:05 Sommar $

  Copyright (c) 1991-1995    Michael Peppler, original Sybperl
  Copyright (c) 1996         Christian Mallwitz, NT port of Sybperl
  Copyright (c) 1997-1999    Erland Sommarskog, MSSQL::DBlib from NT-Sybperl.

  You may copy this under the terms of the GNU General Public License,
  or the Artistic License, copies of which should have accompanied
  your Perl kit.

  $History: DBlib.xs $
 * 
 * *****************  Version 3  *****************
 * User: Sommar       Date: 99-01-30   Time: 17:05
 * Updated in $/Perl/MSSQL/DBlib
 * MSSQL 1.005
 *
 * *****************  Version 2  *****************
 * User: Sommar       Date: 98-02-12   Time: 22:22
 * Updated in $/Perl/MSSQL/DBlib
 * Fix in initialize: scriptname was incorrectly analysed.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 98-01-19   Time: 22:33
 * Created in $/Perl/MSSQL/DBlib
  ---------------------------------------------------------------------*/


#ifdef CORE_PORT   // That is, anything but AS 3xx.
#ifdef PERL_OBJECT
#else
// No Perl object? Then fake it!
// #define CPerlObj int
#define CPERLarg
#define CPERLarg_
#define PERL_OBJECT_THIS
#define PERL_OBJECT_THIS_
#endif
#include "win32.h"
#include <math.h> // VC-5.0 brainmelt

// "Polluting" names that were replaced in later Perl versions.
#include "patchlevel.h"
#if PATCHLEVEL < 5
#define PL_dowarn dowarn
#define PL_sv_undef sv_undef
#define PL_na na
#endif

#else
// This is ActiveState Build 3xx.
#define PERL_OBJECT
#define MSWIN32
#define CPerlObj          CPerl
#define CPERLarg_         CPerl *pPerl,
#define CPERLarg          CPerl *pPerl
#define PERL_OBJECT_THIS_ pPerl,
#define PERL_OBJECT_THIS  pPerl
#define PL_dowarn         pPerl->dowarn
#define PL_sv_undef       sv_undef
#define PL_na             na
#define newRV_noinc       newRV
#endif


#define DBNTWIN32
#include <windows.h>

#undef IN         // Defined by windows.h but confuses us further down.
#undef OUT        // Ditto

#define WIN32_LEAN_AND_MEAN
#if defined(__cplusplus) && defined(CORE_PORT)
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined(__cplusplus) && defined(CORE_PORT)
}
#endif



#define XS_VERSION "1.005"

#define BOOL     int

#include <sqlfront.h>
#include <sqldb.h>

#include <time.h>

#undef DBNTWIN32


typedef enum hash_key_id
{
    HV_dbproc,
    HV_compute_id,
    HV_dbstatus,
    HV_nullundef,
    HV_keepnum,
    HV_bin0x,
    HV_rpcinfo,
    HV_dateformat,
    HV_msecformat,
    HV_bcpcolinfo,
    HV_bcpnumcols,
    HV_cloneflag
} hash_key_id;

static char *hash_keys[] = { "dbproc", "ComputeID", "DBstatus", "dbNullIsUndef",
                             "dbKeepNumeric", "dbBin0x", "rpcInfo", "dateFormat",
                             "msecFormat", "bcpColInfo", "bcpNumCols", "cloneFlag"};

struct RpcInfo
{
    int type;
    union {
        DBINT       i;
        DBFLT8      f;
        DBCHAR     *c;
        DBBINARY   *b;
        DBDATETIME  d;
    } u;
    int size;
    void *value;
    struct RpcInfo *next;
};

typedef struct {
    int   dbNullIsUndef;
    int   dbKeepNumeric;
    int   dbBin0x;
    char *dateFormat;
    char *msecFormat;
} options;


static LOGINREC *login;


// Call back stuff has been borrowed from DB_File.xs. Since this includes a Perl pointer,
// we are not thread safe.
#ifdef PERL_OBJECT
   typedef struct
   {
       SV       * sub;
       CPerlObj * pPerl;
   } CallBackInfo;
   static CallBackInfo err_callback = { 0, 0 } ;
   static CallBackInfo msg_callback = { 0, 0 } ;
#else
   typedef struct
   {
       SV    * sub;
   } CallBackInfo;
   static CallBackInfo err_callback = { 0} ;
   static CallBackInfo msg_callback = { 0} ;
#endif

// A couple of simplifyed calls for our own use...
static SV **my_hv_fetch (CPERLarg_ HV *hv, hash_key_id id)
{
    return hv_fetch(hv, hash_keys[id], strlen(hash_keys[id]), FALSE);
}

static SV **my_hv_store (CPERLarg_ HV *hv, hash_key_id id, SV *sv)
{
    return hv_store(hv, hash_keys[id], strlen(hash_keys[id]), sv, 0);
}

static void my_hv_delete(CPERLarg_ HV *hv, hash_key_id id)
{
    hv_delete(hv, hash_keys[id], strlen(hash_keys[id]), G_DISCARD);
}


// Extrace the DBPROC from the Perl pointer. As a side effect we delete
// DBstatus which is moot at this stage.
static DBPROCESS *getDBPROC (CPERLarg_ SV *dbp, int check_dead = 1)
{
    HV *hv;
    SV **svp;
    DBPROCESS *dbproc;

    if(!SvROK(dbp))
        croak("dbproc parameter is not a reference");
    hv = (HV *)SvRV(dbp);
    if(! (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_dbproc)) )
        croak("no dbproc key in hash");
    dbproc = (struct dbprocess *)SvIV(*svp);
    if (DBDEAD(dbproc) && check_dead) {
       croak("dbproc is dead or not enabled");
    }

    // Save the Perl handle in the dbproc, so we can retrieve it in callbacks.
    if (dbproc) {
       dbsetuserdata(dbproc, (LPVOID) dbp);
    }

    // Drop DBstatus
    my_hv_delete(PERL_OBJECT_THIS_ hv, HV_dbstatus);

    return dbproc;
}


void dispose_rpc_list(CPERLarg_ struct RpcInfo *ptr)
// This procedure frees the memory allocated by rpcparam.
{
    struct RpcInfo *next;

    for(; ptr; ptr = next)
    {
        next = ptr->next;
        switch (ptr->type)
        {
           case SQLCHAR:
           case SQLVARCHAR:
           case SQLTEXT:
             Safefree(ptr->u.c);
             break;
           case SQLBINARY:
           case SQLVARBINARY:
           case SQLIMAGE:
             Safefree(ptr->u.b);
             break;
           default:
             break;
        }
        Safefree(ptr);
    }
}


static int err_handler (DBPROCESS  *db,
                        int         severity,
                        int         dberr,
                        int         oserr,
                        const char *dberrstr,
                        const char *oserrstr)
{

#ifdef PERL_OBJECT
        CPerlObj *pPerl = err_callback.pPerl;
#endif

    if(err_callback.sub)        /* a perl error handler has been installed */
    {
        dSP;
        SV *rv, *rv_save;
        SV *sv;
        HV *hv;
        int retval, count;

        ENTER;
        SAVETMPS;
        PUSHMARK(sp);

        if(db && !DBDEAD(db))
        {
            // Let's see if we have a Perl handle saved.
            rv = rv_save = (SV *) dbgetuserdata(db);
            if (rv) {
               // We have. Push a *copy* of it on the stack.
               XPUSHs(sv_mortalcopy(rv));
            }
            else {
               // We don't, we need to build a temporary one.
               hv = (HV*)sv_2mortal((SV*)newHV());
               sv = newSViv((IV)db);
               my_hv_store(PERL_OBJECT_THIS_ hv, HV_dbproc, sv);
               rv = newRV((SV*)hv);
               XPUSHs(sv_2mortal(rv));
            }
        }
        else {
            XPUSHs(&PL_sv_undef);
        }


        XPUSHs(sv_2mortal (newSViv (severity)));
        XPUSHs(sv_2mortal (newSViv (dberr)));
        XPUSHs(sv_2mortal (newSViv (oserr)));
        if (dberrstr && *dberrstr)
            XPUSHs(sv_2mortal (newSVpv ((char *) dberrstr, 0)));
        else
            XPUSHs(&PL_sv_undef);
        if (oserrstr && *oserrstr)
            XPUSHs(sv_2mortal (newSVpv ((char *) oserrstr, 0)));
        else
            XPUSHs(&PL_sv_undef);

        PUTBACK;

        if ((count = perl_call_sv(err_callback.sub, G_SCALAR)) != 1)
           croak("An error handler can't return a LIST.");
        SPAGAIN;
        retval = POPi;

        // Restore the saved rv-value, which might have been over-written if the
        // handler called DB-lib.
        if (db && !DBDEAD(db)) {
           dbsetuserdata(db, (LPVOID) rv_save);
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }

    if ((db == NULL) || (DBDEAD(db))) {
        if (dberrstr) {
            fprintf(stderr,"DB-Library error %d:\n\t%s\n", dberr, dberrstr);
        }
        return(INT_EXIT);
    }
    else {
        fprintf(stderr,"DB-Library error: %d\n\t%s\n", dberr, dberrstr);

        if (oserr != DBNOERR)
            fprintf(stderr,"Operating-system error:\n\t%s\n", oserrstr);

        return(INT_CANCEL);
    }
}

static int msg_handler (DBPROCESS   *db,
                        DBINT        msgno,
                        int          msgstate,
                        int          severity,
                        const char  *msgtext,
                        const char  *srvname,
                        const char  *procname,
                        DBUSMALLINT  line)
{

#ifdef PERL_OBJECT
        CPerlObj *pPerl = msg_callback.pPerl;
#endif

    if (msg_callback.sub)        /* a perl error handler has been installed */
    {
        dSP;
        SV * rv, *rv_save;
        SV * sv;
        HV * hv;
        int retval, count;

        PUSHMARK(sp);
        ENTER;
        SAVETMPS;

        if(db && !DBDEAD(db))
        {
            // Let's see if we have a Perl handle saved.
            rv = rv_save = (SV *) dbgetuserdata(db);
            if (rv) {
               // We have. Push a *copy* of it on the stack.
               XPUSHs(sv_mortalcopy(rv));
            }
            else {
               // We don't, we need to build a temporary one.
               hv = (HV*)sv_2mortal((SV*)newHV());
               sv = newSViv((IV)db);
               my_hv_store(PERL_OBJECT_THIS_ hv, HV_dbproc, sv);
               rv = newRV((SV*)hv);
               XPUSHs(sv_2mortal(rv));
            }
        }
        else {
            XPUSHs(&PL_sv_undef);
        }


        XPUSHs(sv_2mortal (newSViv (msgno)));
        XPUSHs(sv_2mortal (newSViv (msgstate)));
        XPUSHs(sv_2mortal (newSViv (severity)));
        if (msgtext && *msgtext)
            XPUSHs(sv_2mortal (newSVpv ((char *) msgtext, 0)));
        else
            XPUSHs(&PL_sv_undef);
        if (srvname && *srvname)
            XPUSHs(sv_2mortal (newSVpv ((char *) srvname, 0)));
        else
            XPUSHs(&PL_sv_undef);
        if (procname && *procname)
            XPUSHs(sv_2mortal (newSVpv ((char *) procname, 0)));
        else
            XPUSHs(&PL_sv_undef);
        XPUSHs(sv_2mortal (newSViv (line)));

        PUTBACK;
        if((count = perl_call_sv(msg_callback.sub, G_SCALAR)) != 1)
            croak("A msg handler cannot return a LIST");
        SPAGAIN;
        retval = POPi;

        // Restore the saved rv-value, which might have been over-written if the
        // handler called DB-lib.
        if (db && !DBDEAD(db)) {
           dbsetuserdata(db, (LPVOID) rv_save);
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        return retval;
    }

    /* Don't print any message if severity == 0 */
    if (!severity)
        return 0;

    fprintf (stderr,"Msg %ld, Level %d, State %d\n",
             msgno, severity, msgstate);
    if (srvname != NULL && (int)strlen(srvname) > 0)
        fprintf (stderr,"Server '%s', ", srvname);
    if (procname != NULL && (int)strlen(procname) > 0)
        fprintf (stderr,"Procedure '%s', ", procname);
    if (line > 0)
        fprintf (stderr,"Line %d", line);

    fprintf(stderr,"\n\t%s\n", msgtext);

    return(0);
}


// This routines turns a SQL date into a string according to the dateFormat
// and msecFormat strings. This is an excercise of letting other people
// doing the work for you.
static int date_to_string(      CPERLarg_
                                DBPROCESS  *dbproc,
                                LPCBYTE    data,
                                char       *buff,
                          const int        type,
                          const int        datalen,
                          const options    opts,
                          const int        buffsize)
{
    DBDATETIME datetime;
    DBDATEREC  cracked_date;
    struct tm  tm_date;
    size_t     len;
    int        stat;

    // Convert into a datetime, we might have a small one.
    stat = dbconvert(dbproc, type, data, datalen, SQLDATETIME,
                     (LPCBYTE) &datetime, -1);

    // Crack the date into a record
    stat = dbdatecrack(dbproc, &cracked_date, &datetime);
    if (stat != SUCCEED) {
    // Dbdatecrack don't signal failed conversions (which could occur if
    // non-date values were bulk-copied into a datetime column), so we call
    // the error handler ourselves.
       err_handler(dbproc, EXCONVERSION, SQLECSYN, DBNOERR,
                  "Conversion of datetime column failed", NULL);
       return stat;
    }

    // Move over the data into tm_date
    tm_date.tm_hour  = cracked_date.hour;
    tm_date.tm_isdst = 0; // Seriously, we don't know.
    tm_date.tm_mday  = cracked_date.day;
    tm_date.tm_min   = cracked_date.minute;
    tm_date.tm_mon   = cracked_date.month - 1;
    tm_date.tm_sec   = cracked_date.second;
    tm_date.tm_wday  = cracked_date.weekday % 7;
    tm_date.tm_yday  = cracked_date.dayofyear - 1;
    tm_date.tm_year  = cracked_date.year - 1900;

    // Convert the beast
    len = strftime(buff, buffsize, opts.dateFormat, &tm_date);
    if (len <= 0) {
       dbcancel(dbproc);
       croak("strftime failed for dateFormat '%s'.", opts.dateFormat);
       return FAIL;
    }

    // If we have an format for the milliseconds, and we're have a big date,
    // add the milliseconds.
    if (type == SQLDATETIME && opts.msecFormat && *opts.msecFormat) {
       len = _snprintf(&buff[len], buffsize - len, opts.msecFormat,
                       cracked_date.millisecond);
       if (len <= 0) {
          dbcancel(dbproc);
          croak("_snprintf failed for msecFormat '%s'.", opts.msecFormat);
          return FAIL;
       }
    }

    return SUCCEED;
}


// convert_data gets the data from the buffer from SQL Server (data), and
// puts it as a string or a numeric value in buff. This routine performs
// some work that is common to dbnextrow and dbretdata.
static void convert_data (      CPERLarg_
                                DBPROCESS   *dbproc,
                                LPCBYTE     data,
                          const int         type,
                          const int         len,
                          const options     opts,
                                SV*         &colvalue)
{
   int stat;

   if (! data && ! len) {
   // This is a NULL value. They can be returned in two ways.
      colvalue = (opts.dbNullIsUndef ? newSVsv(&PL_sv_undef) :
                                       newSVpv("NULL", 0));
      return;
   }

   switch(type)
   {
     case SQLDATETIME:
     case SQLDATETIM4:
        {
           char  buff[256];
           if (! opts.dateFormat || ! *opts.dateFormat) {
              // If no date format defined, do it with dbconvert.
              stat = dbconvert(dbproc, type, data, len, SQLCHAR, (BYTE *)buff, -1);
           }
           else {
              stat = date_to_string(PERL_OBJECT_THIS_ dbproc, data, buff, type,
                                    len, opts, 256);
           }
           if (stat == -1) {
              buff[0] = '\0';
           }
           colvalue = newSVpv(buff, 0);
        }
        break;
     case SQLTEXT:
     case SQLIMAGE:
     case SQLCHAR:
        colvalue = newSVpv((char *)data, len);
        break;
     case SQLINT1:
     case SQLBIT:
     case SQLINT2:
     case SQLINT4:
        int intval;
        switch (type) {
           case SQLINT1:
           case SQLBIT:  intval = *(DBTINYINT *)data;
                         break;
           case SQLINT2: intval = *(DBSMALLINT *)data;
                         break;
           case SQLINT4: intval = *(DBINT *)data;
                         break;
        }
        if (opts.dbKeepNumeric) {
           colvalue = newSViv(intval);
        }
        else {
           char  buff[30];
           sprintf(buff, "%d", intval);
           colvalue = newSVpv(buff, 0);
        }
        break;
     case SQLFLT8:
     case SQLFLT4:
     case SQLDECIMAL:      // Actually, decimal/numeric seems to come as FLT8.
     case SQLNUMERIC:
     case SQLMONEY:
     case SQLMONEY4:
        double  fltval;
        switch (type) {
           case SQLFLT8:    fltval = *(DBFLT8 *)data;
                            break;
           case SQLFLT4:    fltval = *(DBREAL *)data;
                            break;
           case SQLDECIMAL:
           case SQLNUMERIC:
           case SQLMONEY:
           case SQLMONEY4:  stat = dbconvert(dbproc, type, data, len, SQLFLT8,
                                             (unsigned char*)&fltval, -1);
                            break;
        }
        if (opts.dbKeepNumeric) {
           colvalue = newSVnv(fltval);
        }
        else {
           char buff[50];
           sprintf(buff, "%.6f", fltval);
           colvalue = newSVpv(buff, 0);
        }
        break;
     case SQLBINARY:
     case SQLVARBINARY:
        // Convert binary to string hex-digits.
        {
           char  *buff;
           New(902, buff, 2 * len + 3, char);
           if (opts.dbBin0x) {
              strcpy(buff, "0x");
              stat = dbconvert(dbproc, type, data, len, SQLCHAR,
                               (BYTE *)&buff[2], -1);
           }
           else {
              stat = dbconvert(dbproc, type, data, len, SQLCHAR,
                               (BYTE *)buff, -1);
           }
           colvalue = newSVpv(buff, 0);
           Safefree(buff);
        }
        break;
     default:
        // Some type we didn't predict. Just send back the bytes.
        colvalue = newSVpv((char *) data, len);
        break;
   }
}


// This procedures gets the options from the dbprocess structure, into a
// local struct
static void get_mssqlperloptions (CPERLarg_
                                  HV       *hv,
                                  options  &opts)
{
    SV  **svp;

    opts.dbKeepNumeric = 0;
    opts.dbBin0x       = 0;
    opts.dbNullIsUndef = 0;
    opts.dateFormat    = NULL;
    opts.msecFormat    = NULL;

    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_nullundef))
          opts.dbNullIsUndef = SvIV(*svp);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_keepnum))
         opts.dbKeepNumeric = SvIV(*svp);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_bin0x))
             opts.dbBin0x = SvIV(*svp);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_dateformat))
         opts.dateFormat = SvPV(*svp, PL_na);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_msecformat))
         opts.msecFormat = SvPV(*svp, PL_na);
}





static void initialize (CPERLarg)
{
    if(!login)
    {
        SV *sv;

        if(dbinit() == FAIL)
            croak("Can't initialize dblibrary...");
        dberrhandle(err_handler);
        dbmsghandle(msg_handler);
#ifdef PERL_OBJECT
        err_callback.pPerl = PERL_OBJECT_THIS;
        msg_callback.pPerl = PERL_OBJECT_THIS;
#endif

        login = dblogin();
        DBSETLUSER(login, NULL);
        DBSETLPWD(login, NULL);

        if (sv = perl_get_sv("0", FALSE))
        {
            char scriptname[2048];
            char *p;
            strcpy(scriptname, SvPV(sv, PL_na));

            // Strip out any directory parts, look for both kinds of slahses to be sure.
            if (p = strrchr(scriptname, '/'))
               ++p;
            else if (p = strrchr(scriptname, '\\'))
               ++p;
            else if (p = strrchr(scriptname, ':'))
                ++p;
            else
                p = scriptname;

            // The script name must not be longer than MAXNAME - 1
            if ((int)strlen(p) > MAXNAME - 1)
                p[MAXNAME - 1] = 0;
            DBSETLAPP(login, p);
        }
        if ((sv = perl_get_sv("MSSQL::DBlib::Version", TRUE)))
        {
            char buff[256];
            sprintf(buff, "This is MSSQL::DBlib, version %s\n\nCopyright (c) 1991-1995 Michael Peppler\nCopyright (c) 1996 Christian Mallwitz, Intershop GmbH\nCopyright (c) 1997-1999 Erland Sommarskog\n",
                    XS_VERSION);
            sv_setnv(sv, atof(XS_VERSION));
            sv_setpv(sv, buff);
            SvNOK_on(sv);
        }
    }
}


static int not_here (CPERLarg_ char *s)
{
    croak("MSSQL::DBlib::%s not implemented on this architecture", s);
    return -1;
}

static SV* set_up_hv(CPERLarg_ char* pack, DBPROCESS* dbproc)
{
    SV *rv;
    SV *sv;
    HV *hv;
    HV *stash;

    sv = newSViv((IV)dbproc);
    hv = (HV*)sv_2mortal((SV*)newHV());
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_dbproc, sv);
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_keepnum, newSViv(1));
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_nullundef, newSViv(1));
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_dateformat, newSVpv("", 0));
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_msecformat, newSVpv(".%3.3d", 0));
    rv = newRV((SV*)hv);
    stash = gv_stashpv(pack, TRUE);
    rv = sv_2mortal(sv_bless(rv, stash));

    return rv;
}

MODULE = MSSQL::DBlib           PACKAGE = MSSQL::DBlib

BOOT:
initialize(PERL_OBJECT_THIS);


void
dblogin(pack="MSSQL::DBlib", sv_user=NULL, sv_pwd=NULL, sv_server=NULL, sv_appname=NULL)
        char *  pack
        SV *  sv_user
        SV *  sv_pwd
        SV *  sv_server
        SV *  sv_appname
  CODE:
{
    DBPROCESS *dbproc;
    char *user    = NULL;
    char *pwd     = NULL;
    char *server  = NULL;
    char *appname = NULL;

    if (sv_user    && SvOK(sv_user))    user    = (char *) SvPV(sv_user, PL_na);
    if (sv_pwd     && SvOK(sv_pwd))     pwd     = (char *) SvPV(sv_pwd, PL_na);
    if (sv_server  && SvOK(sv_server))  server  = (char *) SvPV(sv_server, PL_na);
    if (sv_appname && SvOK(sv_appname)) appname = (char *) SvPV(sv_appname, PL_na);

    if (user && *user)
       DBSETLUSER(login, user);

    if(pwd && *pwd)
       DBSETLPWD(login, pwd);

    if(server && !*server)
       server = NULL;

    if(appname && *appname)
       DBSETLAPP(login, appname);

    if(!(dbproc = dbopen(login, server)))
    {
        ST(0) = sv_newmortal();
    }
    else
    {
        ST(0) = set_up_hv(PERL_OBJECT_THIS_ pack, dbproc);
    }
}

void
dbopen(pack="MSSQL::DBlib", sv_server=NULL, sv_appname=NULL)
        char *  pack
        SV *  sv_server
        SV *  sv_appname
  CODE:
{
    DBPROCESS *dbproc;
    char *  server  = NULL;
    char *  appname = NULL;

    if (sv_server  && SvOK(sv_server))  server  = (char *) SvPV(sv_server, PL_na);
    if (sv_appname && SvOK(sv_appname)) appname = (char *) SvPV(sv_appname, PL_na);

    if(server && !*server)
        server = NULL;

    if(appname && *appname)
        DBSETLAPP(login, appname);

    if(!(dbproc = dbopen(login, server)))
    {
        ST(0) = sv_newmortal();
    }
    else
    {
        ST(0) = set_up_hv(PERL_OBJECT_THIS_ pack, dbproc);
    }
}

int
dbuse(dbp,db)
        SV *    dbp
        char *  db
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbuse(dbproc, db);
}
 OUTPUT:
RETVAL

void
dbclose(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    HV *hv;

    if(!dbproc)                 /* it's already been closed! */
        return;

    dbclose(dbproc);
    hv = (HV *)SvRV(dbp);
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_dbproc, (SV*)newSViv(0));
}

int
dbcmd(dbp,cmd)
        SV *    dbp
        char *  cmd
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbcmd(dbproc, cmd);
}
 OUTPUT:
RETVAL

int
dbsqlexec(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbsqlexec(dbproc);
}
 OUTPUT:
RETVAL


int
dbsqlsend(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbsqlsend(dbproc);
}
 OUTPUT:
RETVAL

int
dbdataready(dbp)
       SV*   dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbdataready(dbproc);
}
  OUTPUT:
RETVAL

int
dbsqlok(dbp)
      SV* dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbsqlok(dbproc);

    // If there is a parameter list from RPC, we delete it now.
    HV *hv;
    SV **svp;
    struct RpcInfo *ptr = NULL;

    hv = (HV *)SvRV(dbp);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_rpcinfo)) {
       ptr = (struct RpcInfo *)SvIV(*svp);
       if (ptr) {
          dispose_rpc_list(PERL_OBJECT_THIS_ ptr);
          my_hv_delete(PERL_OBJECT_THIS_ hv, HV_rpcinfo);
       }
    }
}
OUTPUT:
   RETVAL

int
dbresults(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbresults(dbproc);
}
 OUTPUT:
RETVAL

int
dbcancel(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbcancel(dbproc);
}
 OUTPUT:
RETVAL

int
dbcanquery(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbcanquery(dbproc);
}
 OUTPUT:
RETVAL

void
dbfreebuf(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    dbfreebuf(dbproc);
}

int
dbsetopt(dbp, option, c_val=NULL)
        SV *    dbp
        int     option
        char *  c_val
  CODE:
{
    DBPROCESS *dbproc = NULL;
    dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    RETVAL = dbsetopt(dbproc, option, c_val);
}
 OUTPUT:
RETVAL

int
dbclropt(dbp, option, c_val=NULL)
        SV *    dbp
        int     option
        char *  c_val
  CODE:
{
    DBPROCESS *dbproc = NULL;
    if(dbp != &PL_sv_undef)
    RETVAL = dbclropt(dbproc, option, c_val);
}
 OUTPUT:
RETVAL

int
dbisopt(dbp, option, c_val=NULL)
        SV *    dbp
        int     option
        char *  c_val
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbisopt(dbproc, option, c_val);
}
 OUTPUT:
RETVAL

void
dbclrbuf(dbp, n)
     SV * dbp
     int  n
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    dbclrbuf(dbproc, n);
}


int
DBCURROW(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = DBCURROW(dbproc);
}
 OUTPUT:
RETVAL

int
DBCURCMD(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = DBCURCMD(dbproc);
}
 OUTPUT:
RETVAL

int
DBMORECMDS(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = DBMORECMDS(dbproc);
}
 OUTPUT:
RETVAL

int
DBCMDROW(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = DBCMDROW(dbproc);
}
 OUTPUT:
RETVAL

int
DBROWS(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = DBROWS(dbproc);
}
 OUTPUT:
RETVAL

int
DBCOUNT(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = DBCOUNT(dbproc);
}
 OUTPUT:
RETVAL

int
dbnumcols(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbnumcols(dbproc);
}
 OUTPUT:
RETVAL

int
dbcoltype(dbp, colid)
        SV *    dbp
        int     colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbcoltype(dbproc, colid);
}
 OUTPUT:
RETVAL

int
dbcollen(dbp, colid)
        SV *    dbp
        int     colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbcollen(dbproc, colid);
}
 OUTPUT:
RETVAL

char *
dbcolname(dbp, colid)
        SV *    dbp
        int     colid
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = (char *) dbcolname(dbproc, colid);
}
 OUTPUT:
RETVAL


int
dbnextrow2 (dbp, outref, doAssoc=0)
        SV *    dbp
        SV *    outref
        int     doAssoc
CODE:
{
    int       retval;
    int       ComputeId = 0;
    LPBYTE    data;
    int       col;
    int       type;
    int       numcols = 0;
    int       len;
    char      *colname;
    char      cname[64];
    options   opts;
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    HV        *hv = (HV*) SvRV(dbp);
    HV        *rethash;
    AV        *retlist;
    SV        *colvalue;

    get_mssqlperloptions(PERL_OBJECT_THIS_ hv, opts);

    retval = dbnextrow(dbproc);
    RETVAL = retval;

    // Get number of columns.
    if (retval == REG_ROW) {
       numcols = dbnumcols(dbproc);
    }
    else if(retval > 0) {
       ComputeId = retval;
       numcols = dbnumalts(dbproc, retval);
    }

    // Set up structure for storing the result.
    if (retval == NO_MORE_ROWS || retval == FAIL || retval == BUF_FULL) {
       sv_setsv(outref, &PL_sv_undef);
       numcols = 0;
    }
    else if (doAssoc) {
       rethash = newHV();
       sv_setsv(outref, newRV_noinc((SV*) rethash));
    }
    else {
       retlist = newAV();
       av_extend(retlist, numcols);
       sv_setsv(outref, newRV_noinc((SV*) retlist));
    }


    for (col = 1; col <= numcols; ++col) {
       colname = NULL;
       if (! ComputeId) {
          type    = dbcoltype(dbproc, col);
          len     = dbdatlen(dbproc, col);
          data    = (BYTE *) dbdata(dbproc, col);
          colname = (char *) dbcolname(dbproc, col);
       }
       else {
          int colid = dbaltcolid(dbproc, ComputeId, col);
          type      = dbalttype(dbproc, ComputeId, col);
          len       = dbadlen(dbproc, ComputeId, col);
          data      = (BYTE *)dbadata(dbproc, ComputeId, col);
          if (colid > 0) {
             colname = (char *) dbcolname(dbproc, colid);
          }
       }

       if (! colname || ! colname[0]) {
           sprintf(cname, "Col %d", col);
           colname = cname;
       }

       convert_data(PERL_OBJECT_THIS_ dbproc, data, type, len, opts, colvalue);

       if (doAssoc) {
          if (PL_dowarn && hv_exists(rethash, colname, strlen(colname))) {
             warn("Column name '%s' appears twice or more in result set", colname);
          }
          hv_store(rethash, colname, strlen(colname), colvalue, 0);
       }
       else {
          av_store(retlist, col - 1, colvalue);
       }
    }

    // Save ComputeID or delete it, if it's not there.
    if (ComputeId) {
       my_hv_store(PERL_OBJECT_THIS_ hv, HV_compute_id, (SV*)newSViv(ComputeId));
    }
    else {
       my_hv_delete(PERL_OBJECT_THIS_ hv, HV_compute_id);
    }
}
OUTPUT:
   RETVAL
   outref


SV*
dbretdata2 (dbp, doAssoc=0)
        SV *    dbp
        int     doAssoc
CODE:
{
    LPBYTE    data;
    int       par;
    int       type;
    int       numpars = 0;
    int       len;
    char      *parname;
    char      pname[64];
    options   opts;
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    HV        *hv = (HV *)SvRV(dbp);
    HV        *rethash;
    AV        *retlist;
    SV        *parvalue;

    get_mssqlperloptions(PERL_OBJECT_THIS_ hv, opts);

    // Get number of parameters.
    numpars = dbnumrets(dbproc);

    // Set up structure for storing the result.
    if (doAssoc) {
       rethash = newHV();
       RETVAL = newRV((SV*) rethash);
    }
    else {
       retlist = newAV();
       av_extend(retlist, numpars - 1);
       RETVAL = newRV((SV*) retlist);
    }


    for (par = 1; par <= numpars; ++par)  {
       parname = NULL;
       type    = dbrettype(dbproc, par);
       len     = dbretlen(dbproc, par);
       data    = (BYTE *) dbretdata(dbproc, par);
       parname = (char *) dbretname(dbproc, par);
       if (! parname || ! parname[0]) {
           sprintf(pname, "Par %d", par);
           parname = pname;
       }

       convert_data(PERL_OBJECT_THIS_ dbproc, data, type, len, opts, parvalue);

       if (doAssoc) {
          hv_store(rethash, parname, strlen(parname), parvalue, 0);
       }
       else {
          av_store(retlist, par - 1, parvalue);
       }
    }
}
OUTPUT:
   RETVAL

void
dbstrcpy(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    int retval, len;
    char *buff;


    ST(0) = sv_newmortal();
    if(dbproc && (len = dbstrlen(dbproc)))
    {
        New(902, buff, len+1, char);
        retval = dbstrcpy(dbproc, 0, -1, buff);
        sv_setpv(ST(0), buff);
        Safefree(buff);
    }
    else
        ST(0) = &PL_sv_undef;
}


char *
dbprtype(token)
        int     token
CODE:
{
    RETVAL = (char *) dbprtype(token);
}
 OUTPUT:
RETVAL


void
DESTROY(dbp)
        SV *    dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp, 0);
    SV   **svp;
    char *p;
    BYTE **colPtr;
    int  skip;
    HV   *hv = (HV *) SvRV(dbp);


    // First check the clone flag. If this is set, just leave it.
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_cloneflag)) {
       skip = SvIV(*svp);
    }
    else {
       skip = 0;
    }

    if (! skip) {
        // Get all pointers we've stashed into the hash, and free the memory.
        if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_bcpcolinfo)) {
           if (p = (char *) SvIV(*svp)) {
              Safefree(p);
           }
        }
        if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_rpcinfo)) {
           if (p = (char *) SvIV(*svp)) {
              dispose_rpc_list(PERL_OBJECT_THIS_ (struct RpcInfo*) p);
           }
        }

        if(dbproc && ! dbdead(dbproc)) {
           dbclose(dbproc);
        }
    }
}

int
dbwritetext(dbp, colname, dbp2, colnum, text, log=0)
        SV *    dbp
        char *  colname
        SV *    dbp2
        int     colnum
        SV *    text
        int     log
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    DBPROCESS *dbproc2 = getDBPROC(PERL_OBJECT_THIS_ dbp2);
    char *ptr;
    STRLEN len;

    ptr = SvPV(text, len);

    RETVAL = dbwritetext(dbproc, colname, dbtxptr(dbproc2, colnum),
                         DBTXPLEN, dbtxtimestamp(dbproc2, colnum), (BOOL)log,
                         len, (BYTE *)ptr);
}
 OUTPUT:
RETVAL


void
dberrhandle(err_handle)
            SV * err_handle
CODE:
{
    char *name;
    SV   *ret = NULL;

    if (err_callback.sub)
       ret = newSVsv(err_callback.sub);

    if (! SvOK(err_handle))
       err_callback.sub = NULL;
    else {
       if (! SvROK(err_handle)) {
          name = SvPV(err_handle, PL_na);
          err_handle = newRV((SV*) perl_get_cv(name, FALSE));
          if (! err_handle) {
             croak("Can't find specified error handler '%s'", name);
             // OK, we found an error handler, but was it pure luck?
          }
          else if (PL_dowarn && ! strstr(name, "::")) {
             warn("Error handler '%s' given as a unqualified name. This could fail next time you try.", name);
          }
       }

       if (err_callback.sub == (SV*) NULL) {
          err_callback.sub = newSVsv(err_handle);
       }
       else {
          sv_setsv(err_callback.sub, err_handle);
       }
    }

    if (ret)
       ST(0) = sv_2mortal(ret);
    else
       ST(0) = sv_newmortal();
}

void
dbmsghandle(msg_handle)
        SV * msg_handle
CODE:
{
    char *name;
    SV   *ret = NULL;

    if (msg_callback.sub) {
       ret = newSVsv(msg_callback.sub);
    }

    if (! SvOK(msg_handle)) {
       msg_callback.sub = NULL;
    }
    else {
       if (! SvROK(msg_handle)) {
          name = SvPV(msg_handle, PL_na);
          msg_handle = newRV((SV*) perl_get_cv(name, FALSE));
          if (! msg_handle) {
             croak("Can't find specified message handler '%s'", name);
             // OK, we found an message handler, but was it pure luck?
          }
          else if (PL_dowarn && ! strstr(name, "::")) {
             warn("Message handler '%s' given as a unqualified name. This could fail next time you try.", name);
          }
       }

       if (msg_callback.sub == (SV*) NULL) {
          msg_callback.sub = newSVsv(msg_handle);
       }
       else {
          sv_setsv(msg_callback.sub, msg_handle);
       }
    }

    if (ret)
       ST(0) = sv_2mortal(ret);
    else
       ST(0) = sv_newmortal();
}


int
DBSETLAPP(app)
    char * app
  CODE:
{
    RETVAL = DBSETLAPP(login, app);
}
 OUTPUT:
RETVAL


int
DBSETLHOST(cough)
    char * cough
  CODE:
{
    RETVAL = DBSETLHOST(login, cough);
}
 OUTPUT:
RETVAL


int
DBSETLFALLBACK(onoff)
    char * onoff
  CODE:
{
    RETVAL = DBSETLHOST(login, onoff);
}
 OUTPUT:
RETVAL


int
DBSETLNATLANG(language)
        char *  language
  CODE:
{
    RETVAL = DBSETLNATLANG(login, language);
}
 OUTPUT:
RETVAL


int
DBSETLPACKET(pack_size)
    unsigned short pack_size
  CODE:
{
    RETVAL = DBSETLPACKET(login, pack_size);
}
 OUTPUT:
RETVAL


int
DBSETLPWD(pwd)
    char * pwd
  CODE:
{
    RETVAL = DBSETLPWD(login, pwd);
}
 OUTPUT:
RETVAL

int
DBSETLSECURE()
  CODE:
{
    RETVAL = DBSETLSECURE(login);
}
 OUTPUT:
RETVAL


int
DBSETLTIME(seconds)
    unsigned long seconds
  CODE:
{
    RETVAL = DBSETLTIME(login, seconds);
}
 OUTPUT:
RETVAL

int
DBSETLUSER(user)
    char * user
  CODE:
{
    RETVAL = DBSETLUSER(login, user);
}
 OUTPUT:
RETVAL


int
DBSETLVERSION(version)
      int version
  CODE:
{
    RETVAL = DBSETLVERSION(login, version);
}
 OUTPUT:
RETVAL


int
DBGETTIME()

int
dbsettime(seconds)
        int     seconds

int
dbsetlogintime(seconds)
        int     seconds

void
dbexit()

int
dbrpcparam(dbp, sv_parname, status, type, maxlen, datalen, sv_value)
        SV *    dbp
        SV *    sv_parname
        int     status
        int     type
        int     maxlen
        int     datalen
        SV *    sv_value
  CODE:
{
#if !defined(max)
#define max(a, b)       ((a) > (b) ? (a) : (b))
#endif
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    HV *hv;
    SV **svp, *sv;
    struct RpcInfo *head = NULL, *ptr = NULL;
    char buff[256];
    int  len;
    char * parname = NULL;
    char * value   = "";

    if (SvOK(sv_parname)) {
       parname = (char *) SvPV(sv_parname, PL_na);
       // If no parameter name was given, we still have a pointer to an empty string. Make that NULL.
       if (strlen(parname) == 0) {
          parname = NULL;
       }
    }
    if (SvOK(sv_value)) {
       value = (char *) SvPV(sv_value, PL_na);
    }

    hv = (HV *)SvRV(dbp);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_rpcinfo))
        head = (struct RpcInfo *)SvIV(*svp);

    New(902, ptr, 1, struct RpcInfo);
    switch(type)
    {
      case SQLBIT:
      case SQLINT1:
      case SQLINT2:
      case SQLINT4:
      case SQLINTN:
         ptr->type = SQLINT4;
         ptr->u.i = atoi(value);
         ptr->value = &ptr->u.i;
         break;
      case SQLFLT8:
      case SQLMONEY:
      case SQLFLT4:
      case SQLFLTN:
      case SQLMONEY4:
      case SQLMONEYN:
      case SQLNUMERIC:    // These are actually numericn and decimaln in systypes.
      case SQLDECIMAL:
      case 63:            // These are the real thing.
      case 55:
         ptr->type = SQLFLT8;
         ptr->u.f = atof(value);
         ptr->value = &ptr->u.f;
         break;
      case SQLCHAR:
      case SQLVARCHAR:
      case SQLTEXT:
      case 36:
         if (type == 36) type = SQLVARCHAR;
         ptr->type = type;
         ptr->size = max(maxlen, datalen);
         New(902, ptr->u.c, ptr->size+1, char);
         strcpy(ptr->u.c, value);
         ptr->value = ptr->u.c;
         break;
      case SQLDATETIME:
      case SQLDATETIM4:
      case SQLDATETIMN:
         ptr->type = SQLDATETIME;
         len = dbconvert(dbproc, SQLCHAR, (unsigned char*) value, datalen, SQLDATETIME,
                   (unsigned char *) &(ptr->u.d), -1);
         ptr->value = &(ptr->u.d);
         break;
      case SQLBINARY:
      case SQLVARBINARY:
      case SQLIMAGE:
         ptr->type = type;
         ptr->size = max(maxlen, datalen);
         New(902, ptr->u.b, ptr->size+1, DBBINARY);
         len = dbconvert(dbproc, SQLCHAR, (unsigned char*) value, datalen, type,
                   ptr->u.b, -1);
         ptr->value = ptr->u.b;
         if (value[0] != '\0' && value[1] == 'x') {
            datalen -= 2;
         }
         datalen = datalen / 2;
         break;
      default:
         sprintf(buff, "Invalid type value (%d) for dbrpcparam()", type);
         croak(buff);
    }
    ptr->next = head;
    head = ptr;
    sv = newSViv((IV)head);
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_rpcinfo, sv);


    RETVAL = dbrpcparam(dbproc, parname, status, ptr->type, maxlen, datalen, (unsigned char *)ptr->value);
}
  OUTPUT:
RETVAL


int
dbrpcsend(dbp, wait = 1)
        SV *    dbp
        int     wait
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    HV *hv;
    SV **svp;
    struct RpcInfo *ptr = NULL;

    hv = (HV *)SvRV(dbp);
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_rpcinfo))
        ptr = (struct RpcInfo *)SvIV(*svp);

    RETVAL = dbrpcsend(dbproc);

    if (wait) {
       /* temporay solution: call dbsqlok() directly after dbrpcsend() */
       if(RETVAL != FAIL)
           RETVAL = dbsqlok(dbproc);
       /* clean-up the rpcParam list
          according to the DBlib docs, it should be safe to this here. */
       if (ptr) {
          dispose_rpc_list(PERL_OBJECT_THIS_ ptr);
          my_hv_delete(PERL_OBJECT_THIS_ hv, HV_rpcinfo);
       }
    }
}
  OUTPUT:
RETVAL

int
dbhasretstat(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbhasretstat(dbproc);
}
 OUTPUT:
RETVAL

int
dbretstatus(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbretstatus(dbproc);
}
 OUTPUT:
RETVAL



int
BCP_SETL(state)
        int     state
  CODE:
{
    RETVAL = BCP_SETL(login, state);
}
 OUTPUT:
RETVAL

int
bcp_init(dbp, tblname, sv_datafile, sv_errfile, dir)
        SV *    dbp
        char *  tblname
        SV   *  sv_datafile
        SV   *  sv_errfile
        int     dir
  CODE:
{
    char * datafile = NULL;
    char * errfile  = NULL;

    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    if (SvOK(sv_datafile)) {
       datafile = (char *) SvPV(sv_datafile, PL_na);
    }
    if (SvOK(sv_errfile)) {
       errfile = (char *) SvPV(sv_errfile, PL_na);
    }

    RETVAL = bcp_init(dbproc, tblname, datafile, errfile, dir);
}
 OUTPUT:
RETVAL

int
bcp_meminit(dbp,numcols)
        SV *    dbp
        int     numcols
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    int j;
    int stat;
    BYTE **colPtr;
    BYTE dummy;
    SV   *sv;
    SV   **svp;
    HV   *hv = (HV *) SvRV(dbp);

    stat = SUCCEED;
    for(j = 1; j <= numcols && stat == SUCCEED; ++j) {
        stat = bcp_bind(dbproc, &dummy, 0, -1, (BYTE *)"", 1, SQLCHAR, j);
    }

    // Make sure we free the pointer when bcp_meminit() is called repeatedly.
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_bcpcolinfo)) {
       if (colPtr = (BYTE**) SvIV(*svp)) {
          Safefree(colPtr);
       }
    }

    New (902, colPtr, numcols, BYTE *);
    sv = newSViv( (IV) colPtr);
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_bcpcolinfo, sv);
    my_hv_store(PERL_OBJECT_THIS_ hv, HV_bcpnumcols, newSViv(numcols));

    RETVAL = stat;
}
 OUTPUT:
RETVAL

int
bcp_sendrow(dbp, ...)
        SV *    dbp
  CODE:
{
    SV *sv;
    SV **svp;
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    BYTE **colPtr;
    HV  *hv = (HV *) SvRV(dbp);
    int j, stat;
    int defcols;
    int actualcols = items - 1;

    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_bcpnumcols))
       defcols = SvIV(*svp);
    if (PL_dowarn && defcols < actualcols) {
       warn ("bcp_sendrow called with %d columns, but bcp_meminit was called with %d.",
              actualcols, defcols);
    }

    svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_bcpcolinfo);
    if (! svp) {
        croak("MSSQL::DBlib::bcp_meminit hasn't been called before bcp_sendrow.");
    }
    if (! (colPtr = (BYTE**) SvIV(*svp))) {
        croak("MSSQL::DBlib::bcp_meminit hasn't been called before bcp_sendrow.");
    }


    stat = SUCCEED;
    for(j = 1; j <= actualcols; ++j)
    {
        sv = ST(j);
        if(SvOK(sv)) {
            stat = bcp_collen(dbproc, -1, j);
            colPtr[j-1] = (BYTE *)SvPV(sv, PL_na);
        }
        else {   /* it's a null data value */
            stat = bcp_collen(dbproc, 0, j);
            colPtr[j-1] = (BYTE *) "";
        }
        if (stat == SUCCEED)
           stat = bcp_colptr(dbproc, colPtr[j-1], j);
    }
    if (stat == SUCCEED)
       stat = bcp_sendrow(dbproc);

    RETVAL = stat;
}
 OUTPUT:
RETVAL

int
bcp_batch(dbp)
        SV *    dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = bcp_batch(dbproc);
}
 OUTPUT:
RETVAL

int
bcp_done(dbp)
        SV *    dbp
CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    HV   *hv = (HV *) SvRV(dbp);
    SV   **svp;
    BYTE **colPtr;

    RETVAL = bcp_done(dbproc);

    // We don't this array any more.
    if (svp = my_hv_fetch(PERL_OBJECT_THIS_ hv, HV_bcpcolinfo)) {
       if (colPtr = (BYTE**) SvIV(*svp)) {
          Safefree(colPtr);
       }
    }
    my_hv_delete(PERL_OBJECT_THIS_ hv, HV_bcpcolinfo);
    my_hv_delete(PERL_OBJECT_THIS_ hv, HV_bcpnumcols);
}
 OUTPUT:
RETVAL

int
bcp_control(dbp,field,value)
        SV *    dbp
        int     field
        int     value
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = bcp_control(dbproc, field, value);
}
 OUTPUT:
RETVAL

int
bcp_columns(dbp,colcount)
        SV *    dbp
        int     colcount
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = bcp_columns(dbproc, colcount);
}
 OUTPUT:
RETVAL

int
bcp_colfmt(dbp, host_col, host_type, host_prefixlen, host_collen, host_term, host_termlen, table_col)
        SV *    dbp
        int     host_col
        int     host_type
        int     host_prefixlen
        int     host_collen
        char *  host_term
        int     host_termlen
        int     table_col
        int     precision
        int     scale
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    if(host_term && !*host_term)
        host_term = NULL;

    RETVAL = bcp_colfmt(dbproc, host_col, host_type, host_prefixlen,
                        host_collen, (BYTE *)host_term, host_termlen,
                        table_col);
}
 OUTPUT:
RETVAL


int
bcp_collen(dbp, varlen, table_column)
        SV *    dbp
        int     varlen
        int     table_column
  CODE:
// Note: while bcp_collen is included here, it is on purpose left undocumented.
// Why Michael Peppler has included it, I don't know, but appears to be super-
// fluous, given how bcp_sendrow is implemented.
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = bcp_collen(dbproc, varlen, table_column);
}
 OUTPUT:
RETVAL

void
bcp_exec(dbp)
        SV *    dbp
  PPCODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);
    DBINT rows;
    int j;

    j = bcp_exec(dbproc, &rows);

    XPUSHs(sv_2mortal(newSVnv(j)));
    XPUSHs(sv_2mortal(newSViv(rows)));
}

int
bcp_readfmt(dbp, filename)
        SV *    dbp
        char *  filename
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = bcp_readfmt(dbproc, filename);
}
 OUTPUT:
RETVAL

int
bcp_writefmt(dbp, filename)
        SV *    dbp
        char *  filename
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = bcp_writefmt(dbproc, filename);
}
 OUTPUT:
RETVAL


int
dbrpcinit(dbp, rpcname, opt)
        SV *    dbp
        char *  rpcname
        int     opt
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = dbrpcinit(dbproc, rpcname, opt);
}
  OUTPUT:
RETVAL


int
dbrpwset(srvname, pwd)
        char *  srvname
        char *  pwd
  CODE:
{
// Note: this routine is undocumented in Microsoft docs. It does compile, thhough.
// It was left out from the export list of MSSQL::DBlib 1.000, and with 1.005
// it was removed from the docs as well.
    if(!srvname || strlen(srvname) == 0)
        srvname = NULL;
    RETVAL = dbrpwset(login, srvname, pwd, strlen(pwd));
}
  OUTPUT:
RETVAL

void
dbrpwclr()
  CODE:
{
    dbrpwclr(login);
}


int
DBDEAD(dbp)
      SV *    dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = (DBBOOL)DBDEAD(dbproc);
}
  OUTPUT:
RETVAL


void
open_commit(pack="MSSQL::DBlib", sv_user=NULL, sv_pwd=NULL, sv_server=NULL, sv_appname=NULL)
        char *  pack
        SV *  sv_user
        SV *  sv_pwd
        SV *  sv_server
        SV *  sv_appname
  CODE:
{
    DBPROCESS *dbproc;
    char *  user    = NULL;
    char *  pwd     = NULL;
    char *  server  = NULL;
    char *  appname = NULL;

    if (sv_user    && SvOK(sv_user))    user    = (char *) SvPV(sv_user, PL_na);
    if (sv_pwd     && SvOK(sv_pwd))     pwd     = (char *) SvPV(sv_pwd, PL_na);
    if (sv_server  && SvOK(sv_server))  server  = (char *) SvPV(sv_server, PL_na);
    if (sv_appname && SvOK(sv_appname)) appname = (char *) SvPV(sv_appname, PL_na);

    if(user && *user)
       DBSETLUSER(login, user);

    if(pwd && *pwd)
       DBSETLPWD(login, pwd);

    if(server && !*server)
       server = NULL;

    if(appname && *appname)
       DBSETLAPP(login, appname);

    if(!(dbproc = open_commit(login, server)))
    {
        ST(0) = sv_newmortal();
    }
    else
    {
        ST(0) = set_up_hv(PERL_OBJECT_THIS_ pack, dbproc);
    }
}

int
start_xact(dbp, app_name, xact_name, site_count)
        SV *    dbp
        char *  app_name
        char *  xact_name
        int     site_count
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = start_xact(dbproc, app_name, xact_name, site_count);
}
  OUTPUT:
RETVAL

int
stat_xact(dbp, id)
        SV *    dbp
        int     id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = stat_xact(dbproc, id);
}
  OUTPUT:
RETVAL

int
commit_xact(dbp, id)
        SV *    dbp
        int     id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = commit_xact(dbproc, id);
}
  OUTPUT:
RETVAL

void
close_commit(dbp)
        SV *    dbp
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    close_commit(dbproc);
}


int
abort_xact(dbp, id)
        SV *    dbp
        int     id
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = abort_xact(dbproc, id);
}
  OUTPUT:
RETVAL

void
build_xact_string(xact_name, service_name, commid)
        char *  xact_name
        char *  service_name
        int     commid
  PPCODE:
{
    char *buff;

    New (902, buff, 15 + strlen(xact_name) + strlen(service_name), char);

    build_xact_string(xact_name, service_name, commid, buff);

    XPUSHs(sv_2mortal(newSVpv(buff, 0)));

    Safefree(buff);
}

int
remove_xact(dbp, id, site_count)
        SV *    dbp
        int     id
        int     site_count
  CODE:
{
    DBPROCESS *dbproc = getDBPROC(PERL_OBJECT_THIS_ dbp);

    RETVAL = remove_xact(dbproc, id, site_count);
}
  OUTPUT:
RETVAL

