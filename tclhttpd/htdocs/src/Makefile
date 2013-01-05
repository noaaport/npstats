BUILDDIR =	pub

CSSDIR	=	css
IMGDIR =	images
INCDIR =	include
SUBDIRS =	${CSSDIR} ${IMGDIR} ${INCDIR}

SOURCES =	display_device_list.tml.body \
		display_device_status.tml.body \
		display_main_device.tml.body \
		index.tml.body \
		printconf.tml.body \
		quickguide.tml.body

OBJECTS = 	display_device_list.tml \
		display_device_status.tml \
		display_main_device.tml \
		index.tml \
		printconf.tml \
		quickguide.tml

NPSTATSDIR =	${BUILDDIR}/npstats
NPSTATSFILES =	printconf.tml quickguide.tml

STATUSDIR =	${BUILDDIR}/npstats/status
STATUSFILES =	display_device_list.tml \
		display_device_status.tml \
		display_main_device.tml
MAINFILES =	index.tml

TARGET =	${OBJECTS}

all: ${TARGET}

display_device_list.tml: display_device_list.tml.body
	./mk-tml.sh display_device_list > display_device_list.tml

display_device_status.tml: display_device_status.tml.body
	./mk-tml.sh display_device_status > display_device_status.tml

display_main_device.tml: display_main_device.tml.body
	./mk-tml.sh display_main_device > display_main_device.tml

index.tml: index.tml.body
	./mk-tml.sh index > index.tml

printconf.tml: printconf.tml.body
	./mk-tml.sh printconf > printconf.tml

quickguide.tml: quickguide.tml.body
	./mk-tml.sh quickguide > quickguide.tml

build: ${TARGET}
	rm -rf ${BUILDDIR}
	mkdir -p ${STATUSDIR} ${NPSTATSDIR}
	cp -r ${SUBDIRS} ${BUILDDIR}
	cp ${MAINFILES} ${BUILDDIR}
	cp ${NPSTATSFILES} ${NPSTATSDIR}
	cp ${STATUSFILES} ${STATUSDIR}

clean:
	rm -f *~ ${OBJECTS}
	rm -rf ${BUILDDIR}
