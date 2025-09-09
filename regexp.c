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
#include <stdio.h>
#include <pcre2.h>

void
xalloc_die (void)
{
  printf ("memory exhausted\n");
  abort ();
}

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

  PCRE2_SPTR re_str = (PCRE2_SPTR) re_string;

  const uint32_t options = 0;
  re_libraries =
    pcre2_compile (re_str, re_string_length, options, &errorcode,
		   &erroroffset, NULL);
  if (re_libraries == NULL)
    {
      *error_indicator = (int) erroroffset;
      PCRE2_UCHAR *errmsg_buf = (PCRE2_UCHAR *) error_message_buffer;
      (void) pcre2_get_error_message (errorcode, errmsg_buf,
				      error_message_buffer_length);
    }
}

int
match_re_libraries (char *path_string, size_t path_string_length)
{
  PCRE2_SPTR path_str = (PCRE2_SPTR) path_string;
  pcre2_match_context *match_context =
    pcre2_match_context_create (NULL);
  pcre2_match_data *match_data = pcre2_match_data_create (1, NULL);
  if (match_data == NULL)
    xalloc_die ();
  uint32_t options = 0;
  int retval = pcre2_match (re_libraries, path_str, path_string_length,
			    0, options, match_data, match_context);
  pcre2_match_data_free (match_data);
  pcre2_match_context_free (match_context);
  return retval;
}
