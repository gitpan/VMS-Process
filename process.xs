/* VMS::Process - Get a list of processes, or manage processes
 *
 * Version: 0.01
 * Author:  Dan Sugalski <sugalsd@lbcc.cc.or.us>
 * Revised: 18-Sep-1997
 *
 *
 * Revision History:
 *
 * 0.1  18-Sep-1997 Dan Sugalski <sugalsd@lbcc.cc.or.us>
 *      Snagged base code from VMS::ProcInfo.XS
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#include <starlet.h>
#include <descrip.h>
#include <prvdef.h>
#include <jpidef.h>
#include <uaidef.h>
#include <ssdef.h>
#include <stsdef.h>
#include <statedef.h>
#include <prcdef.h>
#include <pcbdef.h>
#include <pscandef.h>
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

typedef struct {short   buflen,          /* Length of output buffer */
                        itmcode;         /* Item code */
                void    *buffer;         /* Buffer address */
                void    *retlen;         /* Return length address */
                } ITMLST;  /* Layout of item-list elements */
                
typedef struct {short   buflen,          /* Length of output buffer */
                        itmcode;         /* Item code */
                void    *buffer;         /* Buffer address */
                long    itemflags;       /* flags for this item */
                } PITMLST;  /* Layout of item-list elements */
                
/* Macro to fill in an item list entry */
#define init_itemlist(ile, length, code, bufaddr, retlen_addr) \
{ \
    (ile)->buflen = (length); \
    (ile)->itmcode = (code); \
    (ile)->buffer = (bufaddr); \
    (ile)->retlen = (retlen_addr) ;}

/* Macro to fill in a process_scan item list entry */
#define init_pitemlist(ile, length, code, bufaddr, flags) \
{ \
    (ile)->buflen = (length); \
    (ile)->itmcode = (code); \
    (ile)->buffer = (bufaddr); \
    (ile)->itemflags = (flags) ;}


MODULE = VMS::Process		PACKAGE = VMS::Process		

void
process_list()
   PPCODE:
{
  /* variables */
  PITMLST ProcScanItemList[2];
  int status;
  unsigned int ProcessContext = 0;

  /* Zero out the item list */
  Zero(&ProcScanItemList[0], 2, PITMLST);

  /* Fill in the item list. Right now we just return all the processes on */
  /* all nodes we can access */
  init_pitemlist(&ProcScanItemList[0], 0, PSCAN$_NODE_CSID, 0,
                 PSCAN$M_NEQ);

  /* Call $PROCESS_SCAN to initialize out process context */
  status = sys$process_scan(&ProcessContext, &ProcScanItemList[0]);
  if (status == SS$_NORMAL) {
    /* Built the process context up OK. Allocate and build the item list */
    /* for $GEPJPI, then go loop */
    ITMLST ProcItemList[2];
    long fetchedpid;
    short pidlength;
    
    Zero(&ProcItemList[0], 2, ITMLST);
    init_itemlist(&ProcItemList[0], 4, JPI$_PID, &fetchedpid, &pidlength);
    
    status = sys$getjpiw(0, &ProcessContext, NULL, &ProcItemList, NULL,
                         NULL, 0);
    
    /* Loop as long as we think we've got more processes to scan */
    while (status != SS$_NOMOREPROC) {
      /* Did the fetch actually succeed? */
      if (status & STS$M_SUCCESS) {
        /* Guess it did. Push the pid on the stack and go get another */
        XPUSHs(sv_2mortal(newSViv(fetchedpid)));
        status = sys$getjpiw(0, &ProcessContext, NULL, &ProcItemList, NULL,
                             NULL, 0);
      } else {
        /* Something went wrong. Mark the error and exit out undef'd */
        /* immediately */
        SETERRNO(EVMSERR, status);
        XSRETURN_UNDEF;
      }
    }
  } else {
    SETERRNO(EVMSERR, status);
    ST(0) = &sv_undef;
  }
}

void
suspend_process(pid)
     int pid;
   CODE:
{
  int status;
  status = sys$suspnd(&pid, NULL, NULL);
  if (status != SS$_NORMAL) {
    SETERRNO(EVMSERR, status);
    ST(0) = &sv_no;
  } else {
    ST(0) = &sv_yes;
  }
}

void
release_process(pid)
     int pid;
   CODE:
{
  int status;
  status = sys$resume(&pid, NULL);
  if (status != SS$_NORMAL) {
    SETERRNO(EVMSERR, status);
    ST(0) = &sv_no;
  } else {
    ST(0) = &sv_yes;
  }
}

void
kill_process(pid)
     int pid;
   CODE:
{
  int status;
  status = sys$delprc(&pid, NULL);
  if (status != SS$_NORMAL) {
    SETERRNO(EVMSERR, status);
    ST(0) = &sv_no;
  } else {
    ST(0) = &sv_yes;
  }
}

void
change_priority(pid, newpriority)
     int pid;
     int newpriority;
   CODE:
{
  int status;
  unsigned int OldPriority;
  status = sys$setpri(&pid, NULL, newpriority, &OldPriority, NULL, NULL);
  if (status != SS$_NORMAL) {
    SETERRNO(EVMSERR, status);
    ST(0) = &sv_no;
  } else {
    ST(0) = &sv_yes;
  }
}
