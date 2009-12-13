/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <assert.h>
#include <stdio.h>
#include "globals.h"
#include "err.h"
#include "pfilter.h"
#include "manager.h"

static struct pfilter_st *gmanager = NULL;

static int collector_manager_send(char *cmd);

int collector_manager_open(void){

  if(g.collector_manager_enable == 0)
    return(0);

  assert(gmanager == NULL);
  assert(g.collector_manager != NULL);

  gmanager = pfilter_open(g.collector_manager);
  if(gmanager == NULL){
    log_err2("Cannot open", g.collector_manager);
    return(-1);
  }

  log_info("Opened collector manager.");

  return(0);
}

void collector_manager_close(void){

  if(gmanager == NULL)
    return;

  pfilter_close(gmanager);
  gmanager = NULL;

  log_info("Closed collector manager.");
}

int collector_manager_poll(void){

  int status = 0;

  status = collector_manager_send("POLL");
  
  return(status);
}

int collector_manager_report(void){

  int status = 0;

  status = collector_manager_send("REPORT");

  return(status);
}

static int collector_manager_send(char *cmd){

  int status = 0;

  if(gmanager == NULL)
    status = collector_manager_open();
    
  if(gmanager == NULL)
    return(-1);

  if(pfilter_vprintf(gmanager->fp, "%s\n", cmd) < 0)
    status = -1;
    
  if(status == 0)
    status = pfilter_flush(gmanager);

  if(status != 0){
    collector_manager_close();
    log_err2("Error writing to", g.collector_manager);
  }else
    log_verbose(1, "Sent %s to collector manager.", cmd);
  
  return(status);
}
