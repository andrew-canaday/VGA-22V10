.PHONY: \
	all \
	chip \
	clean \
	compile \
	download \
	help \
	info \
	upload \
	vars


# Hack to get the directory this makefile is in:
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
MKFILE_DIR := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
MKFILE_ABSDIR := $(abspath $(MKFILE_DIR))

GALETTE ?= galette

BUILDTMP ?= $(MKFILE_DIR)/build-tmp
UNIT ?= VGASync
PLD_FILE ?= $(MKFILE_DIR)/$(UNIT).pld
JED_FILE ?= $(MKFILE_DIR)/$(UNIT).jed
DEV_NAME ?= "ATF22V10C(UES)"

.DEFAULT_GOAL := all

#---------------------------------------------------------
# Ensure temp directories.
#
# In order to ensure temp dirs exit, we include a file
# that doesn't exist, with a target declared as PHONY
# (above), and then have the target create our tmp dirs.
#---------------------------------------
# -include ensure-tmp
# ensure-tmp:
# 	@mkdir -p $(BUILDTMP)

#---------------------------------------------------------
# Utility / usage:
#---------------------------------------------------------

vars: ## Print relevant environment vars
	@printf  "%-20.20s%s\n"  "MKFILE_PATH:"    "$(MKFILE_PATH)"
	@printf  "%-20.20s%s\n"  "MKFILE_DIR:"     "$(MKFILE_DIR)"
	@printf  "%-20.20s%s\n"  "MKFILE_ABSDIR:"  "$(MKFILE_ABSDIR)"
	@printf  "%-20.20s%s\n"  "BUILDTMP:"       "$(BUILDTMP)"
	@printf  "%-20.20s%s\n"  "UNIT:"           "$(UNIT)"
	@printf  "%-20.20s%s\n"  "PLD_FILE:"       "$(PLD_FILE)"
	@printf  "%-20.20s%s\n"  "JED_FILE:"       "$(JED_FILE)"

help: ## Print this makefile help menu
	@echo "TARGETS:"
	@grep '^[a-z_\-]\{1,\}:.*##' $(MAKEFILE_LIST) \
		| sed 's/^\([a-z_\-]\{1,\}\): *\(.*[^ ]\) *## *\(.*\)/\1:\t\3 (\2)/g' \
		| sed 's/^\([a-z_\-]\{1,\}\): *## *\(.*\)/\1:\t\2/g' \
		| awk '{$$1 = sprintf("%-$(help_spacing)s", $$1)} 1' \
		| sed 's/^/  /'

#---------------------------------------------------------
# Actual build stuff
#
#---------------------------------------

all: \
	VGASync.jed \
	counter800.jed \
	counter525.jed

# Don't actually append tests yet...checksum...
%.jed: %.pld
	$(GALETTE) $<
	@if [ -r '$*.test' ]; then printf 'Appending $*.test to $@\n' ; echo cat '$*.test' \>\> "$@" ; fi

compile: $(UNIT).pld $(UNIT).jed ## Build JED from PLD

chip: $(UNIT).jed ## Display an ASCII rendering of the current UNIT
	@cat $(UNIT).chp

upload: $(UNIT).jed ## Upload a JED file to a PLD
	minipro -p $(DEV_NAME) -w $(UNIT).jed

download: ## Download the JED data from a PLD
	minipro -p $(DEV_NAME) -r $(UNIT)-chip-` date +%s `.jed

read-hex: ## Read the PLD fuse data as raw hex
	minipro -p $(DEV_NAME) -f ihex -r $(UNIT)-chip.ihex

info: ## Print out device info for the current PLD
	minipro -d $(DEV_NAME)

clean: ## Clean build artifacts for the current UNIT
	rm -v \
		$(UNIT).chp \
		$(UNIT).fus \
		$(UNIT).jed \
		$(UNIT).pin 2>/dev/null || echo "Done"

clean-all: ## Clean build artifacts
	rm -v \
		*.chp \
		*.fus \
		*.jed \
		*.pin 2>/dev/null


