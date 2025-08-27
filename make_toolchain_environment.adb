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
with ada.text_io;
with ada.wide_wide_text_io;
with gnat.regpat;
with posix;
with posix.files;

procedure make_toolchain_environment is

  package cmdln renames ada.command_line;
  package re renames gnat.regpat;

  re_for_shared_library : constant re.pattern_matcher :=
                            re.compile ("^lib.+\.so(\.[0-9]+)*$");

  magic_bytes_count_for_elf : constant integer range 4 .. 4 := 4;
  magic_bytes_for_elf : constant array (0 .. 3) of natural :=
                          ( 16#7f#, 16#45#, 16#4c#, 16#46# );

  progname : constant string := cmdln.command_name;

  procedure usage_error is
    procedure inform_about_usage is
      use ada.wide_wide_text_io;
      package tio renames ada.text_io;
    begin
      put ("Usage: ");
      tio.put (progname);
      put (" symlinks dir1 dir2 ... dirN environDir");
      new_line;
    end inform_about_usage;
  begin
    inform_about_usage;
    cmdln.set_exit_status (cmdln.failure);
  end usage_error;

  procedure dispatch (argcount : in natural;
                      arg      : access function (number : in positive)
                                    return string) is
  begin
    usage_error;
  end dispatch;

begin
  cmdln.set_exit_status (cmdln.success);
	dispatch (cmdln.argument_count, cmdln.argument'access);
end make_toolchain_environment;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
