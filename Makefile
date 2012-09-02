#directory i should grab the source from
SRCDIR?=.
#the directory i should dump .o to
OBJDIR?=.
#top level directory, where .config is
TOPDIR?=.
#antares directory where all the scripts are
ANTARES_DIR?=$(TOPDIR)
#temporary dir for autogenerated stuff and other such shit
TMPDIR?=tmp

ANTARES_DIR:=$(abspath $(ANTARES_DIR))
TMPDIR:=$(abspath $(TMPDIR))
TOPDIR:=$(abspath $(TOPDIR))

Kbuild:=Kconfig
obj:=$(OBJDIR)/kconfig
src:=$(SRCDIR)/kconfig
Kconfig:=$(SRCDIR)/kcnf
KVersion:=$(ANTARES_DIR)/version.kcnf

PHONY+=deftarget deploy build collectinfo clean
MAKEFLAGS:=-r

IMAGENAME=$(call unquote,$(CONFIG_IMAGE_DIR))/$(call unquote,$(CONFIG_IMAGE_FILENAME))

export SRCDIR ARCH TMPDIR IMAGENAME ARCH TOPDIR ANTARES_DIR

-include $(ANTARES_DIR)/.version
-include $(TOPDIR)/.config
-include $(TOPDIR)/include/config/auto.conf.cmd

.DEFAULT_GOAL := $(subst ",, $(CONFIG_MAKE_DEFTARGET))

include $(ANTARES_DIR)/make/host.mk
include $(TMPDIR)/arch.mk
include $(ANTARES_DIR)/make/Makefile.lib

ifeq ($(PROJECT_SHIPS_ARCH),y)
-include $(TOP_DIR)/arch/$(ARCH)/arch.mk
else
-include $(ANTARES_DIR)/src/arch/$(ARCH)/arch.mk
endif

ifeq ($(ANTARES_DIR),$(TOPDIR))
$(info $(tb_red))
$(info Please, do not run make in the antares directory)
$(info Use an out-of-tree project directory instead.)
$(info Have a look at the documentation on how to do that)
$(info $(col_rst))
$(error Cowardly refusing to go further)
endif



ifeq ($(CONFIG_TOOLCHAIN_GCC),y)
include $(ANTARES_DIR)/toolchains/gcc.mk
endif

include $(ANTARES_DIR)/make/Makefile.collect

-include src/arch/$(ARCH)/arch.mk

include $(ANTARES_DIR)/kconfig/kconfig.mk


.SUFFIXES:

clean-y:="$(TMPDIR)" "$(TOPDIR)/build" "$(TOPDIR)/include/generated" "$(CONFIG_IMAGE_DIR)"

clean:  
	-$(SILENT_CLEAN) rm -Rf $(clean-y)

mrproper: clean
	-$(SILENT_MRPROPER) rm -Rf $(TOPDIR)/kconfig 
	$(Q)rm -f $(TOPDIR)/antares
	$(Q)rm -Rf $(TOPDIR)/include/config
	$(Q)rm -f $(TOPDIR)/include/arch

distclean: mrproper

build:  collectinfo $(TOPDIR)/include/config/auto.conf collectinfo $(BUILDGOALS)

deploy: build
	$(Q)$(MAKE) -f $(ANTARES_DIR)/make/Makefile.deploy $(call unquote,$(CONFIG_DEPLOY_DEFTARGET))
	@echo "Your Antares firmware is now deployed"

deploy-%: build
	$(Q)$(MAKE) -f $(ANTARES_DIR)/make/Makefile.deploy $*
	@echo "Your Antares firmware is now deployed"
	$(Q)$(MAKE) -f $(ANTARES_DIR)/make/Makefile.deploy post

tags:
	$(SILENT_TAGS)etags `find $(TOPDIR) $(ANTARES_DIR)/ -name "*.c" -o -name "*.cpp" -o -name "*.h"|grep -v kconfig`


#Help needs a dedicated rule, so that it won't invoke build as it normally does
deploy-help:
	$(Q)$(MAKE) -f $(ANTARES_DIR)/make/Makefile.deploy help

.PHONY: $(PHONY)
