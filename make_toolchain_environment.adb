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
with ada.directories;
with ada.text_io;
with gnat.regpat;

procedure make_toolchain_environment is

  package cmdln renames ada.command_line;
  package re renames gnat.regpat;

  type cmdln_argfunc is
    access function (number : in positive) return string;

  re_for_shared_library : constant re.pattern_matcher :=
                            re.compile ("^lib.+\.so(\.[0-9]+){0,3}$");

  magic_bytes_count_for_elf : constant integer range 4 .. 4 := 4;
  magic_bytes_for_elf : constant array (0 .. 3) of natural :=
                          ( 16#7f#, 16#45#, 16#4c#, 16#46# );

  progname : constant string := cmdln.command_name;

  procedure inform_about_usage is
    use ada.text_io;
  begin
    put ("Usage: ");
    put (progname);
    put (" symlinks dir1 dir2 ... dirN environDir");
    new_line;
  end inform_about_usage;

  procedure usage_error is
  begin
    inform_about_usage;
    cmdln.set_exit_status (cmdln.failure);
  end usage_error;

  procedure do_symlinks (argcount : in positive;
                         arg      : cmdln_argfunc)
  with pre => (2 <= argcount) is

use ada.text_io;

    use ada.directories;

    subtype source_dir_range is integer range 2 .. argcount - 1;

    function source_dir (n : in source_dir_range)
    return string is
    begin
      return arg (n);
    end source_dir;

    function environ_dir
    return string is
    begin
      return arg (argcount);
    end environ_dir;

    i      : source_dir_range;
    handle : search_type;
    f      : directory_entry_type;

  begin
    for i in source_dir_range loop
      if exists (source_dir (i)) and then
           kind (source_dir (i)) = directory then
        start_search (handle, source_dir (i), "");
        while more_entries (handle) loop
          get_next_entry (handle, f);
put(simple_name(f));new_line;
put(full_name(f));new_line;
        end loop;
        end_search (handle);
      end if;
    end loop;
  end do_symlinks;

  procedure require_environ_dir (proc : access procedure
                                        (argcount : in positive;
                                         arg      : cmdln_argfunc);
                                 argcount : in natural;
                                 arg      : cmdln_argfunc) is
  begin
    if argcount < 2 then
      -- There are not enough arguments for there to be an environment
      -- directory.
      usage_error;
    else
      proc (argcount, arg);
    end if;
  end;

  procedure dispatch (argcount : in natural;
                      arg      : cmdln_argfunc) is
    function operation
    return string is
    begin
      return arg (1);
    end operation;
  begin
    if argcount < 1 then
      usage_error;
    elsif operation = "symlinks" then
      require_environ_dir (do_symlinks'access, argcount, arg);
--      do_symlinks (argcount, arg);
    else
      usage_error;    
    end if;
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
