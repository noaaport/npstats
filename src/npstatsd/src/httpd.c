/*
 * Copyright (c) 2005-2007 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include "err.h"
#include "util.h"
#include "globals.h"

static FILE *ghttpd_fp = NULL;

int httpd_open(void){

  if(g.httpd_enable == 0)
    return(0);

  if(valid_str(g.httpd) == 0){
    log_errx("No httpd defined.");
    return(1);
  }

  ghttpd_fp = popen(g.httpd, "w");
  if(ghttpd_fp != NULL){
    if(fprintf(ghttpd_fp, "%s\n", "init") < 0){
      (void)pclose(ghttpd_fp);
      ghttpd_fp = NULL;
    }
  }

  if(ghttpd_fp == NULL){
    log_err("Could not start httpd server.");
    return(-1);
  }else
    log_info("Started httpd.");

  return(0);
}

void httpd_close(void){

  if(ghttpd_fp == NULL)
    return;

  if(pclose(ghttpd_fp) == -1)
    log_err("Error closing httpd server.");
  else
    log_info("Stoped httpd.");

  ghttpd_fp = NULL;
}
