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

typedef union {
  struct {short   buflen,          /* Length of output buffer */
                  itmcode;         /* Item code */
          void    *buffer;         /* Buffer address */
          long    itemflags;       /* Item flags */
        } BufferItem;  /* Layout of buffer $PROCESS_SCAN item-list elements */
                
  struct {short   buflen,          /* Length of output buffer */
                  itmcode;         /* Item code */
          long    itemvalue;       /* Value for this item */ 
          long    itemflags;       /* flags for this item */
        } LiteralItem;  /* Layout of literal $PROCESS_SCAN item-list */
                        /* elements */
  struct {short   buflen,          /* Length of output buffer */
                  itmcode;         /* Item code */
          void    *buffer;         /* Buffer address */
          void    *retlen;         /* Return length address */
        } TradItem;  /* Layout of 'traditional' item-list elements */
} ITMLST;

struct ProcInfoID {
  char *ProcListName; /* Pointer to the item name */
  int  PSCANValue;      /* Value to use in the process_scan item list */
  int  PSCANType;     /* What type of entry */
};

#define IS_STRING 1
#define IS_LONGWORD 2
#define IS_ENUM 3

struct ProcInfoID ProcList[] =
{
  {"ACCOUNT", PSCAN$_ACCOUNT, IS_STRING},
  {"CURPRIV", PSCAN$_CURPRIV, IS_LONGWORD},
  {"GRP", PSCAN$_GRP, IS_LONGWORD},
  {"HW_NAME", PSCAN$_HW_NAME, IS_STRING},
  {"JOBPRCCNT", PSCAN$_JOBPRCCNT, IS_LONGWORD},
  {"JOBTYPE", PSCAN$_JOBTYPE, IS_ENUM},
  {"MASTER_PID", PSCAN$_MASTER_PID, IS_LONGWORD},
  {"MEM", PSCAN$_MEM, IS_LONGWORD},
  {"MODE", PSCAN$_MODE, IS_ENUM},
  {"NODE_CSID", PSCAN$_NODE_CSID, IS_LONGWORD},
  {"NODENAME", PSCAN$_NODENAME, IS_STRING},
  {"OWNER", PSCAN$_OWNER, IS_LONGWORD},
  {"PRCCNT", PSCAN$_PRCCNT, IS_LONGWORD},
  {"PRCNAM", PSCAN$_PRCNAM, IS_STRING},
  {"PRI", PSCAN$_PRI, IS_LONGWORD},
  {"PRIB", PSCAN$_PRIB, IS_LONGWORD},
  {"STATE", PSCAN$_STATE, IS_ENUM},
  {"STS", PSCAN$_STS, IS_LONGWORD},
  {"TERMINAL", PSCAN$_TERMINAL, IS_STRING},
  {"UIC", PSCAN$_UIC, IS_LONGWORD},
  {"USERNAME", PSCAN$_USERNAME, IS_STRING},
  {NULL, 0, 0}
};

/* Macro to fill in a $PROCESS_SCAN literal item list entry */
#define init_bufitemlist(ile, length, code, bufaddr, flags) \
{ \
    (ile)->BufferItem.buflen = (length); \
    (ile)->BufferItem.itmcode = (code); \
    (ile)->BufferItem.buffer = (bufaddr); \
    (ile)->BufferItem.itemflags = (flags) ;}

/* Macro to fill in a process_scan literal item list entry */
#define init_lititemlist(ile, code, itemval, flags) \
{ \
    (ile)->LiteralItem.buflen = 0; \
    (ile)->LiteralItem.itmcode = (code); \
    (ile)->LiteralItem.itemvalue = (itemval); \
    (ile)->LiteralItem.itemflags = (flags) ;}

/* Macro to fill in a 'traditional' item-list entry */
#define init_itemlist(ile, length, code, bufaddr, retlen_addr) \
{ \
    (ile)->TradItem.buflen = (length); \
    (ile)->TradItem.itmcode = (code); \
    (ile)->TradItem.buffer = (bufaddr); \
    (ile)->TradItem.retlen = (retlen_addr) ;}

int
get_item_type(char *ItemName)
{
  int i;
  for(i=0; ProcList[i].ProcListName; i++) {
    if (!strcmp(ItemName, ProcList[i].ProcListName))
      return ProcList[i].PSCANType;
  }
}

int
de_enum(int PSCANVal, char *EnumName)
{
  int ReturnVal = 0;
  switch(PSCANVal) {
  case PSCAN$_JOBTYPE:
    if (!strcmp(EnumName, "LOCAL"))
      ReturnVal = JPI$K_LOCAL;
    else if (!strcmp(EnumName, "DIALUP"))
      ReturnVal = JPI$K_DIALUP;
    else if (!strcmp(EnumName, "REMOTE"))
      ReturnVal = JPI$K_REMOTE;
    else if (!strcmp(EnumName, "BATCH"))
      ReturnVal = JPI$K_BATCH;
    else if (!strcmp(EnumName, "NETWORK"))
      ReturnVal = JPI$K_NETWORK;
    else if (!strcmp(EnumName, "DETACHED"))
      ReturnVal = JPI$K_DETACHED;
    break;
  case PSCAN$_MODE:
    if (!strcmp(EnumName, "INTERACTIVE"))
      ReturnVal = JPI$K_INTERACTIVE;
    else if (!strcmp(EnumName, "BATCH"))
      ReturnVal = JPI$K_BATCH;
    else if (!strcmp(EnumName, "NETWORK"))
      ReturnVal = JPI$K_NETWORK;
    else if (!strcmp(EnumName, "OTHER"))
      ReturnVal = JPI$K_OTHER;
    break;
  case PSCAN$_STATE:
    if (!strcmp(EnumName, "CEF"))
      ReturnVal = SCH$C_CEF;
    else if (!strcmp(EnumName, "COM"))
      ReturnVal = SCH$C_COM;
    else if (!strcmp(EnumName, "COMO"))
      ReturnVal = SCH$C_COMO;
    else if (!strcmp(EnumName, "CUR"))
      ReturnVal = SCH$C_CUR;
    else if (!strcmp(EnumName, "COLPG"))
      ReturnVal = SCH$C_COLPG;
    else if (!strcmp(EnumName, "FPG"))
      ReturnVal = SCH$C_FPG;
    else if (!strcmp(EnumName, "HIB"))
      ReturnVal = SCH$C_HIB;
    else if (!strcmp(EnumName, "HIBO"))
      ReturnVal = SCH$C_HIBO;
    else if (!strcmp(EnumName, "LEF"))
      ReturnVal = SCH$C_LEF;
    else if (!strcmp(EnumName, "LEFO"))
      ReturnVal = SCH$C_LEFO;
    else if (!strcmp(EnumName, "MWAIT"))
      ReturnVal = SCH$C_MWAIT;
    else if (!strcmp(EnumName, "PFW"))
      ReturnVal = SCH$C_PFW;
    else if (!strcmp(EnumName, "SUSP"))
      ReturnVal = SCH$C_SUSP;
    else if (!strcmp(EnumName, "SUSPO"))
      ReturnVal = SCH$C_SUSPO;
    break;
  }

  return ReturnVal;
}

int
get_item_pscan_val(char *ItemName)
{
  int i;
  for(i=0; ProcList[i].ProcListName; i++) {
    if (!strcmp(ItemName, ProcList[i].ProcListName))
      return ProcList[i].PSCANValue;
  }
}

int
get_comparison_bits(char *Comparison)
{
  int ReturnVal = 0;

  if (!strcmp(Comparison, "gt"))
    ReturnVal = PSCAN$M_GTR;
  else if (!strcmp(Comparison, "lt"))
    ReturnVal = PSCAN$M_LSS;
  else if (!strcmp(Comparison, "eq"))
    ReturnVal = PSCAN$M_EQL;
  else if (!strcmp(Comparison, "le"))
    ReturnVal = PSCAN$M_LEQ;
  else if (!strcmp(Comparison, "ge"))
    ReturnVal = PSCAN$M_GEQ;
  else if (!strcmp(Comparison, "ne"))
    ReturnVal = PSCAN$M_NEQ;
  else if (!strcmp(Comparison, "pre"))
    ReturnVal = PSCAN$M_PREFIX_MATCH;
  else if (!strcmp(Comparison, "*"))
    ReturnVal = PSCAN$M_WILDCARD;
  
  return ReturnVal;
}

int
get_modifier_bits(char *Modifier)
{
  int ReturnVal = 0;

  if (!strcmp(Modifier, "|"))
    ReturnVal = PSCAN$M_OR;
  else if (!strcmp(Modifier, "&&"))
    ReturnVal = PSCAN$M_BIT_ALL;
  else if (!strcmp(Modifier, "||"))
    ReturnVal = PSCAN$M_BIT_ANY;
  else if (!strcmp(Modifier, "I"))
    ReturnVal = PSCAN$M_CASE_BLIND;
  
  return ReturnVal;
}


MODULE = VMS::Process		PACKAGE = VMS::Process		

void
process_list(...)
   PPCODE:
{
  /* variables */
  ITMLST ProcScanItemList[99]; /* Yes, this should be a pointer and the */
                               /* memory should be dynamically */
                               /* allocated. When I try, wacky things */
                               /* happen, so we fall back to this hack */
  int status;
  unsigned int ProcessContext = 0;

  /* First, zero out as much of the array as we're using */
  Zero(&ProcScanItemList, items == 0 ? 2 : items, ITMLST);
  
  /* Did they pass us anything? */
  if (items == 0) {

    /* Fill in the item list. Right now we just return all the processes on */
    /* all nodes we can access */
    init_lititemlist(&ProcScanItemList[0], PSCAN$_NODE_CSID, 0, PSCAN$M_NEQ);
  } else {

    int ItemType;
    int ItemPScanVal;
    char *TempStringPointer;
    SV *NameSV, *ValueSV, *ComparisonSV, *ModifierSV, *RealSV;
    SV *NameConstSV, *ValueConstSV, *ComparisonConstSV, *ModifierConstSV;
    int i, FlagsVal;

    /* We can use these a lot, so create 'em only once */
    NameConstSV = sv_2mortal(newSVpv("NAME", 0));
    ValueConstSV = sv_2mortal(newSVpv("VALUE", 0));
    ComparisonConstSV = sv_2mortal(newSVpv("COMPARISON", 0));
    ModifierConstSV = sv_2mortal(newSVpv("MODIFIER", 0));
      
    for(i=0; i < items; i++) {
      /* The array we get is one of hash RVs, not HVs. Need to deref the */
      /* RV into something we can use */
      RealSV = SvRV(ST(i));
      
      /* Quick check to make sure we've got the required things */
      if (!hv_exists_ent((HV *)RealSV, NameConstSV, 0)) {
        croak("Missing NAME in hash");
        XSRETURN_UNDEF;
      }

      if (!hv_exists_ent((HV *)RealSV, ValueConstSV, 0)) {
        croak("Missing VALUE in hash");
        XSRETURN_UNDEF;
      }

      NameSV = *hv_fetch((HV *)RealSV, "NAME", 4, 0);
      ValueSV = *hv_fetch((HV *)RealSV, "VALUE", 5, 0);
      ItemType = get_item_type(SvPV(NameSV, na));
      ItemPScanVal = get_item_pscan_val(SvPV(NameSV, na));
      FlagsVal = 0; /* By default we have no flags */
      /* If we've got a comparison op, get its flags and see what we get */
      if (hv_exists_ent((HV *)RealSV, ComparisonConstSV, 0)) {
        ComparisonSV = *hv_fetch((HV *)RealSV, "COMPARISON", 10, 0);
        FlagsVal = FlagsVal | get_comparison_bits(SvPV(ComparisonSV, na));
      }
      /* If we've got a modifier op, get its flags and see what we get */
      if (hv_exists_ent((HV *)RealSV, ModifierConstSV, 0)) {
        ComparisonSV = *hv_fetch((HV *)RealSV, "MODIFIER", 8, 0);
        FlagsVal = FlagsVal | get_modifier_bits(SvPV(ModifierSV, na));
      }
      switch(ItemType) {
      case IS_STRING:
        TempStringPointer = SvPV(ValueSV, na);
        init_bufitemlist(&ProcScanItemList[i], strlen(TempStringPointer),
                         ItemPScanVal, TempStringPointer, FlagsVal);
        break;
      case IS_LONGWORD:
        init_lititemlist(&ProcScanItemList[i], ItemPScanVal, SvIV(ValueSV),
                         FlagsVal);
        break;
      case IS_ENUM:
        TempStringPointer = SvPV(ValueSV, na);
        init_lititemlist(&ProcScanItemList[i], ItemPScanVal,
                         de_enum(ItemPScanVal, TempStringPointer),
                         FlagsVal);
      }
    }
  }

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

void
process_list_names()
   PPCODE:
   {
     int i;
     for (i=0; ProcList[i].ProcListName; i++) {
       XPUSHs(sv_2mortal(newSVpv(ProcList[i].ProcListName, 0)));
     }
   }

