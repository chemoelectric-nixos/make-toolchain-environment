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

package regular_expressions is

  use interfaces.c;
  use ada.strings.unbounded;

  type re_code is limited private;

  procedure re_compile (re_string            : in string;
                        error_indicator      : out integer;
                        error_message_buffer : out unbounded_string;
                        re                   : out re_code);

  function re_match (re   : in re_code;
                     item : in string)
  return integer
  with post => (item'first - 1 <= re_match'result and
                re_match'result <= item'last + 1);

private

  type re_code_internals is null record;
  type re_code is access re_code_internals;

  procedure re_compile (re_string                   : in char_array;
                        re_string_length            : in size_t;
                        error_indicator             : out int;
                        error_message_buffer        : out char_array;
                        error_message_buffer_length : in size_t;
                        re                          : out re_code)
  with import => true,
       convention => c,
       external_name => "re_compile";

  function re_match (re          : in re_code;
                     item        : in char_array;
                     item_length : in size_t)
  return int
  with import => true,
       convention => c,
       external_name => "re_match",
       post => (-1 <= re_match'result and
                re_match'result <= int (item_length));

end regular_expressions;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
