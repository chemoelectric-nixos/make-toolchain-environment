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

package quasi_copying is

  --
  -- FIXME: THIS IS A CLUMSY WAY TO PASS ARGUMENTS.
  -- FIXME: THIS IS A CLUMSY WAY TO PASS ARGUMENTS.
  -- FIXME: THIS IS A CLUMSY WAY TO PASS ARGUMENTS.
  -- FIXME: THIS IS A CLUMSY WAY TO PASS ARGUMENTS.
  -- FIXME: THIS IS A CLUMSY WAY TO PASS ARGUMENTS.
  -- FIXME: THIS IS A CLUMSY WAY TO PASS ARGUMENTS.
  --
  type cmdln_argfunc is
    access function (number : in positive) return string;

  procedure do_symlinks (argcount : in positive;
                         arg      : cmdln_argfunc;
                         warn     : in boolean);

  procedure do_libraries (argcount : in positive;
                          arg      : cmdln_argfunc;
                          warn     : in boolean);

end quasi_copying;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
