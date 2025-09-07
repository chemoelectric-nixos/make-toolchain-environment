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

with gnat.strings;

package command_line is

  -- This package may consume some heap space, but we do not bother to
  -- deallocate it.

  bail_out  : boolean;
  symlinks  : aliased boolean;
  libraries : aliased boolean;
  regexp    : aliased gnat.strings.string_access;
  verbose   : aliased boolean;

  function arg_count
  return natural;

  function arg_string (number : in positive)
  return string
  with pre => number <= arg_count;

  type arg_functions is
    record
      arg_count  : access function return natural;
      arg_string : access function (number : in positive)
                   return string;
    end record;

  args : constant arg_functions :=
                  ( arg_count => arg_count'access,
                    arg_string => arg_string'access );

  procedure interpret_the_command_line;

end command_line;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
