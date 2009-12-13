/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#include <assert.h>
#include <stdlib.h>
#include <unistd.h>
#include <tcl.h>
#include "globals.h"
#include "defaults.h"
#include "err.h"
#include "conf.h"
#include "init.h"
#include "exec.h"
#include "signal.h"
#include "per.h"
#include "manager.h"
#include "httpd.h"

static int parse_args(int argc, char **argv);
static int loop(void);

int main(int argc, char **argv){

  int status = 0;

  init_globals();
  atexit(cleanup);

  /*
   * PROBLEM
   * We used to call init_signals() only after init_daemon(). But in
   * that case, when started with -F or -D -D, the signals are
   * not caught in Linunx and OSX (they are caught in FreeBSD). nbspd and
   * npemwind die, but leave the pid file and the web server.
   * [It seems that the signals are not blocked in the main thread as
   * the code in signal.c should ensure.]
   * Adding this call here
   *
   * status = init_signals();
   *
   * makes OSX and Linux respond well when the daemon is run in the foreground.
   * If the call is made after the tcl configure(), the problem repeats;
   * it has to be before the configure() function.
   *
   * The problem is that in FreeBSD-7.1, when init_signals() is called here,
   * then no threads are spawned afterwards.
   *
   * The solution was to split init_signals() in two parts, one that
   * block the signals and the other spawns the thread. I don't fully
   * understand what in tcl is causing this (Fri Mar 13 11:43:09 AST 2009).
   */
  status = init_signals_block();

  if(status == 0){
    /*
     * This will configure it with the default configuration file,
     * if it exists.
     *
     * First initialize the tcl library once and for all. It was not
     * necessary to call this in unix, but cygwin needs it or EvalFile
     * seg faults.
     */
    Tcl_FindExecutable(argv[0]);
    status = configure();
  }

  if(status == 0)
    status = parse_args(argc, argv);

  if(status == 0){
    if(g.configfile != NULL){
      /*
       * This will reconfigure it with the user-supplied config file
       */
      status = configure();
    }
  }

  /*
   * if [-C] was given, print the configuration and exit.
   */
  if(status == 0){
    if(g.option_C == 1){
      print_confoptions();
      return(0);
    }
  }

  if(status == 0)
    status = validate_configuration();

  if(status == 0)
    status = init_directories();

  /*
   * The last configuration step, just before becoming a daemon.
   */
  if(status == 0)
    status = exec_startscript();

  if((status == 0) && (g.f_ndaemon == 0))
    status = init_daemon();

  set_log_verbose(g.f_verbose);
  set_log_debug(g.f_debug);

  if(status == 0)
    status = init_signals_thread();

  /*
   * This has to be done after daemon() so that the lock file contains the
   * daemon's pid, not the starting program's.
   */
  if(status == 0)
    status = init_lock();

  if(status == 0)
    init_periodic();

  /*
   * Launch all the threads.
   *
   * if(status == 0)
   *   status = spawn_workers();
   */

  /*
   * Open the collector manager.
   */
  if(status == 0)
    status = collector_manager_open();

  /*
   * The https server if it is enabled.
   */
  if(status == 0)
    status = httpd_open();

  if(status == 0)
    status = drop_privs();

  /*
   * If there are initialization errors, ask all threads to quit.
   */
  if(status != 0)
    set_quit_flag();

  while(get_quit_flag() == 0){
    status = loop();
  }

  if(status != 0)
    status = EXIT_FAILURE;

  return(status);
}

static int loop(void){

  int status = 0;

  /*
   * This is the main loop, which we use for monitoring or periodic
   * activities outside of all threads.
   */
  sleep(NPSTATS_MAINLOOP_SLEEP_SECS);
  periodic();
 
  return(status);
}

static int parse_args(int argc, char **argv){

  int status = 0;
  int c;
#ifdef DEBUG
  char *optstr = "c:CDFV";
  char *usage = "npstats [-c configfile] [-C] [-D] [-D] [-F] "
    "[-V] [-V] [-V]";
#else
  char *optstr = "c:CF";
  char *usage = "npstats [-c configfile] [-C] [-F]";
#endif

  while( (status == 0) && ((c = getopt(argc,argv,optstr)) != -1) ){
    switch(c){
    case 'c':
      g.configfile = optarg;
      break;
    case 'C':
      g.option_C = 1;
      break;
    case 'F':
      g.option_F = 1;	/* daemon() not called. Added for launchd in OSX */
      break;
#ifdef DEBUG
    case 'D':
      ++g.f_debug;
      if(g.f_debug == 2){
	g.f_ndaemon = 1;
      }
      break;
    case 'V':
      ++g.f_verbose;
      break;
#endif
    default:
      status = 1;
      errx(1, usage);
      break;
    }
  }

  /*
   * Check conflicts.
   */

  return(status);
}
