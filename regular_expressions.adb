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

with ada.strings;
with ada.strings.unbounded;
with interfaces.c;

package body regular_expressions is

  use ada.strings.unbounded;
  use interfaces.c;

  procedure re_compile (re_string            : in string;
                        error_indicator      : out integer;
                        error_message_buffer : out unbounded_string;
                        re                   : out re_code) is
    re_length      : constant natural := re_string'length;
    pattern_length : size_t := size_t (re_length);
    pattern        : char_array (1 .. pattern_length);
    err_msg_buflen : size_t := size_t (1000);
    err_msg        : char_array (1 .. err_msg_buflen);
    err_indicator  : int;
  begin
    to_c (item => re_string, target => pattern,
          count => pattern_length, append_nul => false);
    re_compile (pattern, pattern_length, err_indicator,
                err_msg, err_msg_buflen, re);
    error_indicator := integer (err_indicator);
    if 0 <= error_indicator then
      declare
        str : constant string := to_ada (err_msg);
      begin
        error_message_buffer := to_unbounded_string (str);
      end;
    else
      error_message_buffer := to_unbounded_string ("");
    end if;
  end re_compile;

  function re_match (re   : in re_code;
                     item : in string)
  return integer is
    len : size_t := size_t (item'length);
    str : char_array (1 .. len);
    i   : int;
  begin
    to_c (item => item, target => str, count => len,
          append_nul => false);
    i := re_match (re, str, len);
    return integer (i);
  end re_match;

end regular_expressions;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
