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

pragma ada_2022;
pragma wide_character_encoding (utf8);
pragma assertion_policy (check);

with ada.command_line;
with posix, posix.files;
with gnat.regpat;

procedure make_toolchain_environment is

  use posix, posix.files;
  package cmdln renames ada.command_line;
  package re renames gnat.regpat;

  re_for_shared_library : constant re.pattern_matcher :=
                            re.compile ("^lib.+\.so(\.[0-9]+)*$");

  magic_bytes_count_for_elf : constant integer := 4;
  magic_bytes_for_elf : constant array (0 .. 3) of integer :=
                          ( 16#7f#, 16#45#, 16#4c#, 16#46# );

  progname : string := "<program name>";

  procedure dispatch (argcount : in natural;
                      arg      : access function (number : in positive)
                                    return string) is
  begin
    null;
  end dispatch;

begin
  cmdln.set_exit_status (cmdln.success);
  progname := cmdln.command_name;
	dispatch (cmdln.argument_count, cmdln.argument'access);
end make_toolchain_environment;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
