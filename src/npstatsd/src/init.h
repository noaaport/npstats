/*
 * Copyright (c) 2009 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#ifndef INIT_H
#define INIT_H

void init_globals(void);
void cleanup(void);
void cleanup_files(void);
int init_daemon(void);
int init_lock(void);
int init_directories(void);
int drop_privs(void);

#endif
