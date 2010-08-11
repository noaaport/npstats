#
# $Id$
#
CONF_SITE_DIR =	/usr/local/etc/npstats/site
HTML_SITE_DIR = /var/npstats/www/htdocs/pub

CONF_SITE_FILES = \
	httpd.conf \
	qrunner.conf \
	spooler.conf

HTML_SITE_FILES = \
	header-iemwin.html \
	index-iemwin.tml        

all:

install:
	install ${CONF_SITE_FILES} ${CONF_SITE_DIR}
	install ${HTML_SITE_FILES} ${HTML_SITE_DIR}

clean:
	rm -f *~
