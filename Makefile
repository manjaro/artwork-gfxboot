BINDIR      := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )

BASED_ON     = $(shell perl -ne 'print if s/^based_on=//' config)

PRODUCT = $(shell perl -ne 'print if s/^product=//' config)

ifeq ($(BASED_ON),)
PREPARED     = 1
else
PREPARED     = $(shell [ -f .prepared ] && echo 1)
endif

ADDDIR       = ../../bin/adddir
BFLAGS       = -O -v -L ../..

SUBDIRS      = fonts help po src

THEME        = $(shell basename `pwd`)

DEFAULT_LANG =

.PHONY: all clean distclean themes $(SUBDIRS)

ifeq ($(PREPARED), 1)

  all: bootlogo

else

  all:
	$(ADDDIR) ../$(BASED_ON) .
	make clean
	touch .prepared
	make

endif

themes: all

%/.ready: %
	make -C $*

src/main.bin: src
	make -C src

bootlogo: src/main.bin src/gfxboot.cfg help/.ready po/.ready fonts/.ready
	@rm -rf isolinux
	@mkdir isolinux
	perl -p -e 's/^(layout=.*)/$$1,install/' src/gfxboot.cfg >isolinux/gfxboot.cfg
	perl -pi -e 's/^(theme=).*/$$1$(THEME)/' isolinux/gfxboot.cfg
	perl -pi -e 's/^(product=).*/$$1$(PRODUCT)/' isolinux/gfxboot.cfg
	cp -rL data/* fonts/*.fnt po/*.tr isolinux
	cp -rL help/*.hlp isolinux
	cp src/main.bin isolinux/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >isolinux/lang
endif
	@sh -c 'cd isolinux; chmod +t * ; chmod -t init languages'
	@sh -c 'cd isolinux; echo * | sed -e "s/ /\n/g" | cpio --quiet -o >../bootlogo'
	mv bootlogo isolinux

clean:
	@for i in $(SUBDIRS) ; do [ ! -f $$i/Makefile ] ||  make -C $$i clean || break ; done
	rm -rf isolinux *~

distclean: clean
ifneq ($(BASED_ON),)
	rm -f .prepared
	rm -f `find -type l \! -wholename ./Makefile`
	## rmdir `find -depth -type d \! -name . \! -name .svn \! -wholename './.svn/*' \! -wholename './*/.svn/*'` 2>/dev/null || true
endif

	