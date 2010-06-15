/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#ifndef GLOBALS_H
#define GLOBALS_H

#include <sys/stat.h>

struct npstatsd_globals {
  char *defconfigfile;  /* the default */
  char *configfile;     /* user-specified (via -c) */
  int   option_C;       /* [-C] just print configuration and exit */
  int   option_F;	/* [-F] don't call daemon() */
  /*
   * configurable options 
   */
  char *user;
  char *group;
  char *home;
  mode_t umask;
  char *pidfile;
  char *startscript;
  char *stopscript;
  char *scheduler;
  int collector_manager_enable;
  char *collector_manager;
  int collector_poll_period_secs;
  int collector_report_period_secs;
  int qrunner_enable;
  char *qrunner;
  int qrunner_period_secs;
  int httpd_enable;
  char *httpd;
  /*
   * variables
   */
  int f_debug;
  int f_verbose;
  int f_lock;	/* pid file created or not */
  int f_ndaemon;
  /*
   * test
   */
  int report_test1_period_s;
  int report_test2_period_s;
} g;

#endif
