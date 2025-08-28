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

  c_io_error : exception;

  re_for_absolute_path : constant re.pattern_matcher :=
                            re.compile ("^/.*");

  re_for_shared_library : constant re.pattern_matcher :=
                            re.compile ("^lib.+\.so(\.[0-9]+){0,3}$");

  magic_bytes_count_for_elf : constant integer range 4 .. 4 := 4;
  magic_bytes_for_elf : constant array (0 .. 3) of natural :=
                          ( 16#7f#, 16#45#, 16#4c#, 16#46# );

  progname : constant string := cmdln.command_name;

  procedure perhaps_notify (notify  : in boolean;
                            message : in string) is
    use ada.text_io;
  begin
    if notify then
      put (message);
      new_line;
    end if;
  end perhaps_notify;

  function path_name_is_absolute (path_name : in string)
  return boolean is
  begin
    return re.match (re_for_absolute_path, path_name);
  end path_name_is_absolute;

  procedure make_symlink_no_clobber (source_name : in string;
                                     target_name : in string;
                                     warn        : boolean) is
    use ada.directories;
    use interfaces.c;
    use interfaces.c.strings;

    function symlink (source_p : in chars_ptr;
                      target_p : in chars_ptr)
    return int;
    pragma import (c, symlink, "symlink");

    function EIO_value
    return int;
    pragma import (c, EIO_value, "EIO_value");

    source_ptr : chars_ptr;
    target_ptr : chars_ptr;
    retval     : int;

  begin
    if exists (target_name) then
      perhaps_notify (warn, "Not overwriting " & target_name);
    else
      source_ptr := new_string (source_name);
      target_ptr := new_string (target_name);
      retval := symlink (source_ptr, target_ptr);
      free (source_ptr);
      free (target_ptr);
      if retval /= 0 then
        if retval /= EIO_value then
          perhaps_notify (warn, "Not overwriting " & target_name);
        else
          raise c_io_error with
            ("I/O error creating symlink " & target_name);
        end if;
      end if;
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
    put (" symlinks+ dir1 dir2 ... dirN environDir");
    new_line;
    put ("       ");
    put (progname);
    put (" symlinks- dir1 dir2 ... dirN environDir");
    new_line;
  end inform_about_usage;

  procedure usage_error is
  begin
    inform_about_usage;
    cmdln.set_exit_status (cmdln.failure);
  end usage_error;

  function simple_name_is_significant (name : in string)
  return boolean is
  begin
    return (name /= "." and then name /= "..");
  end simple_name_is_significant;

  type environ_dir_filler is access procedure (argcount : in positive;
                                               arg      : cmdln_argfunc;
                                               warn     : in boolean);

  procedure do_symlinks (source_dir  : in string;
                         environ_dir : in string;
                         warn        : in boolean) is
    use ada.directories;
    handle : search_type;
    f      : directory_entry_type;
  begin
    start_search (handle, source_dir, "");
    while more_entries (handle) loop
      get_next_entry (handle, f);
      if simple_name_is_significant (simple_name (f)) then
        case kind (f) is
          when directory =>
            declare
              base_name : constant string := simple_name (f);
              src_dir   : constant string := source_dir & "/" & base_name;
              env_dir   : constant string := environ_dir & "/" & base_name;
            begin
              create_directory (env_dir);
              do_symlinks (source_dir => src_dir,
                           environ_dir => env_dir,
                           warn => warn);
            end;
          when others =>
            make_symlink_no_clobber
              (source_name => full_name (f),
               target_name => environ_dir & "/" & simple_name (f),
               warn => warn);
        end case;
      end if;
    end loop;
    end_search (handle);
  end do_symlinks;

  procedure do_symlinks (argcount : in positive;
                         arg      : cmdln_argfunc;
                         warn     : in boolean)
  with pre => (2 <= argcount) is

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

  begin
    for i in source_dir_range loop
      if not exists (source_dir (i)) then
        perhaps_notify (warn, source_dir (i) & " does not exist.");
      elsif kind (source_dir (i)) /= directory then
        perhaps_notify (warn, source_dir (i) & " is not a directory.");
      else
        do_symlinks (source_dir => source_dir (i),
                     environ_dir => environ_dir,
                     warn => warn);
      end if;
    end loop;
  end do_symlinks;

  procedure require_correct_dirs (proc     : environ_dir_filler;
                                  argcount : in natural;
                                  arg      : cmdln_argfunc;
                                  warn     : in boolean) is
    use ada.directories;
    use ada.text_io;

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

    function source_dirs_are_all_absolute
    return boolean is
      all_absolute : boolean := true;
    begin
      for i in source_dir_range loop
        if not path_name_is_absolute (source_dir (i)) then
          all_absolute := false;
          put ("The source directory ");
          put (source_dir (i));
          put (" must instead be an absolute path.");
          new_line;
        end if;
      end loop;
      return all_absolute;
    end source_dirs_are_all_absolute;

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
    elsif not source_dirs_are_all_absolute then
      usage_error;
    else
      proc (argcount, arg, warn);
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
    elsif operation = "symlinks+" then
      require_correct_dirs (do_symlinks'access, argcount, arg, true);
    elsif operation = "symlinks-" then
      require_correct_dirs (do_symlinks'access, argcount, arg, false);
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
