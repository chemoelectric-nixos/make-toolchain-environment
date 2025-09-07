#
# Copyright © 2025 Barry Schwartz
#
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License, as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received copies of the GNU General Public License
# along with this program. If not, see
# <https://www.gnu.org/licenses/>.
#

.DELETE_ON_ERROR:
.NOTPARALLEL:		       # Parallel building won’t help, anyway.

ACLOCAL_AMFLAGS = -I m4 --install
AUTOMAKE_OPTIONS =
AUTOMAKE_OPTIONS += foreign

EXTRA_DIST =
MOSTLYCLEANFILES =
CLEANFILES =
DISTCLEANFILES =
BUILT_SOURCES =
AM_GNATMAKEFLAGS =
AM_LDFLAGS =
LDADD =
bin_PROGRAMS =
bin_SCRIPTS =
man_MANS =

EXTRA_DIST += COPYING
EXTRA_DIST += INSTALL
EXTRA_DIST += README
EXTRA_DIST += AUTHORS

DISTCLEANFILES += Makefile
DISTCLEANFILES += GNUmakefile

PROGNAME = make-toolchain-environment
bin_PROGRAMS += $(PROGNAME)
make_toolchain_environment_SOURCES =

bin_SCRIPTS += mte
DISTCLEANFILES += mte

AM_GNATMAKEFLAGS += -I${builddir}
GNATMAKEFLAGS_TOTAL = $(AM_GNATMAKEFLAGS) $(GNATMAKEFLAGS) $(XGNATMAKEFLAGS)
LDFLAGS_TOTAL = $(AM_LDFLAGS) $(LDFLAGS) $(XLDFLAGS)

EXTRA_DIST += make_toolchain_environment.adb
EXTRA_DIST += command_line.adb
EXTRA_DIST += command_line.ads
EXTRA_DIST += quasi_copying.adb
EXTRA_DIST += quasi_copying.ads
EXTRA_DIST += notification.adb
EXTRA_DIST += notification.ads
make_toolchain_environment_SOURCES += c_code.c
AM_LDFLAGS += c_code.$(OBJEXT)

# The following rule produces more files than just the GNU Make
# target, but gnatmake manages those files.
make-toolchain-environment$(EXEEXT): make_toolchain_environment.adb \
					command_line.adb command_line.ads \
					quasi_copying.adb quasi_copying.ads \
					notification.adb notification.ads \
					dist_version.ads \
					c_code.$(OBJEXT)
	$(GNATMAKE) -o $(@) $(GNATMAKEFLAGS_TOTAL) $(<) -largs $(LDFLAGS_TOTAL)

# Allow ‘mte’ as a shorthand for ‘make-toolchain-environment’.
mte: $(srcdir)/Makefile.am
	( echo '#!'$(SHELL); \
	  echo 'SCRIPT_DIR="$$(dirname `readlink -f "$$0"`)"'; \
	  echo 'exec "$${SCRIPT_DIR}"/$(PROGNAME)$(EXEEXT) "$$@"' ) \
		> $(@) && chmod 755 $(@)

dist_version.ads: $(srcdir)/Makefile.am
	( echo 'package dist_version is'; \
	  echo '  progname : constant string := "$(PROGNAME)";'; \
	  echo '  version  : constant string := "$(VERSION)";'; \
	  echo 'end dist_version;' ) > $(@)

MOSTLYCLEANFILES += *.ali
MOSTLYCLEANFILES += b~make_toolchain_environment.{adb,ads}
CLEANFILES += dist_version.ads

man_MANS += $(PROGNAME).1
CLEANFILES += $(PROGNAME).1

$(PROGNAME).1: $(PROGNAME)$(EXEEXT)
	$(HELP2MAN) -o $(@) --section=1 --no-info $(builddir)/$(PROGNAME)$(EXEEXT)

install-data-hook:
	(cd $(DESTDIR)/$(man1dir) && $(LN_S) $(PROGNAME).1 mte.1)

uninstall-hook:
	(cd $(DESTDIR)/$(man1dir) && rm -f mte.1)

# local variables:
# coding: utf-8
# end:
