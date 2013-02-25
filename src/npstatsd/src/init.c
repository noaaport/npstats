/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <assert.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <pthread.h>
#include "globals.h"
#include "defaults.h"
#include "err.h"
#include "util.h"
#include "strsplit.h"
#include "pid.h"
#include "pw.h"
#include "efile.h"
#include "exec.h"
#include "conf.h"
#include "manager.h"
#include "httpd.h"
#include "init.h"

void init_globals(void){

  /*
   * defaults
   */
  g.defconfigfile = CONFIGFILE;
  g.configfile = NULL;
  g.option_C = 0;
  g.option_F = 0;

  g.user = NPSTATS_USER;
  g.group = NPSTATS_GROUP;
  g.home = NPSTATS_HOME;
  g.umask = DEFAULT_UMASK;

  g.pidfile = NPSTATS_PIDFILE;
  g.pidfile_mode = NPSTATS_PIDFILE_MODE;

  g.startscript = NPSTATS_STARTSCRIPT;
  g.stopscript =  NPSTATS_STOPSCRIPT;
  g.scheduler = NPSTATS_SCHEDULER;

  g.collector_manager_enable = NPSTATS_COLLECTOR_MANAGER_ENABLE;
  g.collector_manager = NPSTATS_COLLECTOR_MANAGER;
  g.collector_poll_period_secs = NPSTATS_COLLECTOR_POLL_PERIOD_SECS;
  g.collector_report_period_secs = NPSTATS_COLLECTOR_REPORT_PERIOD_SECS;

  g.qrunner_enable = NPSTATS_QRUNNER_ENABLE;
  g.qrunner = NPSTATS_QRUNNER;
  g.qrunner_period_secs = NPSTATS_QRUNNER_PERIOD_SECS;

  g.httpd_enable = NPSTATS_HTTPD_ENABLE;
  g.httpd = NPSTATS_HTTPD;

  /*
   * variables
   */
  g.f_debug = 0;
  g.f_verbose = 0;
  g.f_lock = 0;
  g.f_ndaemon = 0;
}

void cleanup(void){

  httpd_close();
  collector_manager_close();

  release_confoptions();
  cleanup_files();

  log_info("Stopped.");

  (void)exec_stopscript();
}

void cleanup_files(void){

  if(g.f_lock == 1){
    if(remove_pidfile(g.pidfile) != 0)
      log_err("Could not remove pidfile.");

    g.f_lock = 0;
  }
}
  
int init_daemon(void){

  int status = 0;
  int nochdir = 0;

  /*
   * If g.home is set, then drop_privs() will have already set
   * the root directory to the normal user's home directory.
   */
  if(valid_str(g.home))
    nochdir = 1;

  if(g.option_F == 0)
    status = daemon(nochdir, 0);

  if(status != 0)
    return(status);

  umask(g.umask);
  openlog(SYSLOG_IDENT, SYSLOG_OPTS, SYSLOG_FACILITY);
  set_log_daemon();

  return(status);
}

int init_lock(void){
  /*
   * This has to be done after daemon() so that the lock file  contains the
   * daemon's pid, not the starting program's.
   */
  int status = 0;

  if(create_pidfile(g.pidfile, g.pidfile_mode) != 0){
    log_err2("Could not create", g.pidfile);
    status = 1;
  }else
    g.f_lock = 1;

  return(status);
}

int init_directories(void){

  int status = 0;

  /*
  status = e_dir_exists(g.spooldir);
  */

  return(status);
}

int drop_privs(void){

  struct strsplit_st *strp = NULL;
  int ngroups = 0;
  char **groups = NULL;
  char *user = NULL;
  char *home = NULL;
  int status = 0;

  if(valid_str(g.group)){
    strp = strsplit_create(g.group, ",", 0);
    if(strp == NULL){
      log_err("Error from strsplit_create() in drop_privs()");
      return(-1);
    }

    groups = strp->argv;
    ngroups = strp->argc;
  }

  if(valid_str(g.user))
    user = g.user;

  if(valid_str(g.home))
    home = g.home;

  status = change_privs(ngroups, groups, user, home);

  if(strp != NULL)
    strsplit_delete(strp);

  if(status == -1)
    log_err2("Cannot change user", g.user);
  else if(status == -2)
    log_err2("Cannot set group(s)", g.group);
  else if(status == -3)
    log_err2("Cannot chdir to", g.home);

  if(status != 0)
    return(-1);

  return(status);
}
