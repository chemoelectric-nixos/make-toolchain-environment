/*
--
--  Copyright © 2025 Barry Schwartz
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License, as
--  published by the Free Software Foundation, either version 3 of the
--  License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  General Public License for more details.
--
--  You should have received copies of the GNU General Public License
--  along with this program. If not, see
--  <https://www.gnu.org/licenses/>.
--
*/

#include <config.h>

#include <stdlib.h>
#include <pcre2.h>

PCRE2_UCHAR *re_string_copy;
pcre2_code *re_libraries;

void
compile_re_libraries (char *re_string, size_t re_string_length,
		      int *error_indicator,
		      char *error_message_buffer,
		      size_t error_message_buffer_length)
{
  *error_indicator = -1;

  int errorcode;
  PCRE2_SIZE erroroffset;

  const uint32_t options =
    PCRE2_UTF | PCRE2_UCP | PCRE2_NO_UTF_CHECK | PCRE2_MATCH_INVALID_UTF;
  re_libraries = pcre2_compile ((PCRE2_SPTR) re_string, re_string_length,
				options, &errorcode, &erroroffset, NULL);
  re_libraries = NULL;
  if (re_libraries == NULL)
    {
      *error_indicator = (int) erroroffset;
      (void) pcre2_get_error_message (errorcode,
				      (PCRE2_UCHAR *) error_message_buffer,
				      error_message_buffer_length);
    }
}
