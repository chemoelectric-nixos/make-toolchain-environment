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
AUTOMAKE_OPTIONS += subdir-objects
#AUTOMAKE_OPTIONS += -Wno-portability

EXTRA_DIST =
MOSTLYCLEANFILES =
CLEANFILES =
DISTCLEANFILES =
BUILT_SOURCES =
AM_GNATMAKEFLAGS =
AM_LDFLAGS =
LDADD =
bin_PROGRAMS =

EXTRA_DIST += $(srcdir)/silent-rules.mk
EXTRA_DIST += COPYING
EXTRA_DIST += INSTALL
EXTRA_DIST += README
EXTRA_DIST += AUTHORS

DISTCLEANFILES += Makefile
DISTCLEANFILES += GNUmakefile

bin_PROGRAMS += make-toolchain-environment

GNATMAKEFLAGS_TOTAL = $(AM_GNATMAKEFLAGS) $(GNATMAKEFLAGS) $(XGNATMAKEFLAGS)
LDFLAGS_TOTAL = -largs $(AM_LDFLAGS) $(LDFLAGS) $(XLDFLAGS)

AM_LDFLAGS += EIO_value.$(OBJEXT)

# The following rule produces more files than just the GNU Make
# target, but gnatmake manages those files.
make-toolchain-environment$(EXEEXT): make_toolchain_environment.adb EIO_value.$(OBJEXT)
	$(GNATMAKE) -o $(@) $(GNATMAKEFLAGS_TOTAL) $(<) $(LDFLAGS_TOTAL)

MOSTLYCLEANFILES += make_toolchain_environment.{ali,$(OBJEXT)}
MOSTLYCLEANFILES += b~make_toolchain_environment.{adb,ads,ali,$(OBJEXT)}
MOSTLYCLEANFILES += EIO_value.{lo,$(OBJEXT)}

# local variables:
# coding: utf-8
# end:
