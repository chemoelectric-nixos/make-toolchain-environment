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

AC_PREREQ([2.72])
AC_INIT([Make Toolchain Environment],[2.0.0])
AC_CONFIG_HEADERS([config.h])

AC_CONFIG_SRCDIR([make_toolchain_environment.adb])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])
AC_CANONICAL_BUILD                 dnl On what platform are we compiling?
AC_CANONICAL_HOST                  dnl For what platform are we compiling?
AC_USE_SYSTEM_EXTENSIONS           dnl Define such macros as _GNU_SOURCE.

AM_INIT_AUTOMAKE([tar-pax no-dist-gzip dist-xz])
AM_MAINTAINER_MODE
LT_INIT

AC_PROG_CC
AC_PROG_CC_C_O
AX_CHECK_COMPILE_FLAG([-std=gnu23],
  [CFLAGS="${CFLAGS}${CFLAGS+ }-std=gnu23"],
  [],[],[AC_LANG_SOURCE([int main(){return 0;}])])
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_MKDIR_P
AC_PROG_AWK
AC_PROG_SED
AC_PROG_FGREP
AC_PROG_EGREP
AC_CHECK_PROGS([HELP2MAN],[help2man])
AC_CHECK_PROGS([GNATMAKE],[gnatmake])
PKG_PROG_PKG_CONFIG

if test -z "${HELP2MAN}"; then
   AC_MSG_ERROR([Please install help2man. It is needed to make the manpage.])
fi

AC_ARG_VAR([GNATMAKE],[GNU gnatmake command])
AC_ARG_VAR([GNATMAKEFLAGS],[GNU gnatmake flags [no default]])

AC_ARG_VAR([DEFAULT_REGEXP],
           [default PCRE2 regular expression for shared libraries])
if test "${ac_cv_env_DEFAULT_REGEXP_set}" != set; then
   DEFAULT_REGEXP='(?<!/bfd-plugins)/lib@<:@^/@:>@+\.so(\.@<:@0-9@:>@+){0,3}$'
fi

AC_ARG_VAR([ASSERTION_POLICY],
           [value of ‘pragma assertion_policy’ [default ‘check’]])
if test "${ac_cv_env_ASSERTION_POLICY_set}" != set; then
   ASSERTION_POLICY="check"
fi

PKG_CHECK_MODULES([PCRE2],[libpcre2-8],
	[AC_DEFINE([HAVE_PCRE2],[1],[Define if PCRE2 is found])],
        [AC_MSG_ERROR([PCRE2 is required but was not found.])])
GNATMAKEFLAGS="${GNATMAKEFLAGS}${GNATMAKEFLAGS+ }${PCRE2_CFLAGS}"
CPPFLAGS="${CPPFLAGS}${CPPFLAGS+ }${PCRE2_CFLAGS}"
LDFLAGS="${LDFLAGS}${LDFLAGS+ }${PCRE2_LIBS}"
AC_DEFINE([PCRE2_CODE_UNIT_WIDTH],[8],
          [Define to the PCRE2 code unit width.])

# You can use ‘@GNU@’ to make GNU Make constructs unbothersome to
# Automake. (By the way, you often can use ‘$(eval ...)’ as well, but
# @GNU@ here may be better.)
AC_SUBST([GNU],[])

# THE FOLLOWING MUST BE THE SAME NAME AS APPEARS IN bin_PROGRAMS.
AC_SUBST([PROGNAME],[make-toolchain-environment])

StM_REQUIRE_GNU_MAKE_IN_PATH
StM_CONFIG_MAKEFILES
AC_CONFIG_FILES([default_regular_expression.ads])
AC_CONFIG_FILES([dist_version.ads])
AC_CONFIG_FILES([gnat.adc])

AC_OUTPUT

# local variables:
# coding: utf-8
# end:
