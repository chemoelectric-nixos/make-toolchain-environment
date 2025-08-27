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
with interfaces.c;
with interfaces.c.strings;
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

  procedure make_symlink_no_clobber (source_name : in string;
                                     target_name : in string) is
    use ada.directories;
    use interfaces.c;
    use interfaces.c.strings;

    procedure symlink (source_p : in chars_ptr;
                       target_p : in chars_ptr);
    pragma import (c, symlink, "symlink");

    source_ptr : chars_ptr;
    target_ptr : chars_ptr;

  begin
    if not exists (target_name) then
      source_ptr := new_string (source_name);
      target_ptr := new_string (target_name);
      symlink (source_ptr, target_ptr);
      free (source_ptr);
      free (target_ptr);
    end if;
  end make_symlink_no_clobber;

  procedure start_with_progname is
    use ada.text_io;
  begin
    put (progname);
    put (": ");
  end start_with_progname;

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

  function simple_name_is_significant (name : string)
  return boolean is
  begin
    return (name /= "." and then name /= "..");
  end simple_name_is_significant;

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
          if simple_name_is_significant (simple_name (f)) then
put(simple_name(f));new_line;
put(full_name(f));new_line;
make_symlink_no_clobber (full_name (f), environ_dir & "/" & simple_name (f));
          end if;
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
    use ada.directories;
    use ada.text_io;

    function environ_dir
    return string is
    begin
      return arg (argcount);
    end environ_dir;

  begin
    if argcount < 2 then
      start_with_progname;
      put ("You must specify some directories.");
      new_line;
      usage_error;
    elsif not exists (environ_dir) or else
        kind (environ_dir) /= directory then
      start_with_progname;
      put (environ_dir);
      put (" is not a directory.");
      new_line;
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
