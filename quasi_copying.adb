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

with ada.directories;
with ada.exceptions;
with ada.sequential_io;
with ada.text_io;
with interfaces.c;
with interfaces.c.strings;
with gnat.regpat;
with notification;

package body quasi_copying is

  package re renames gnat.regpat;

  package character_io is new ada.sequential_io (character);
  package char_io renames character_io;

  c_io_error : exception;

  re_for_shared_library : constant re.pattern_matcher :=
--             re.compile ("^.*(?<!plugins)/lib.+\.so(\.[0-9]+){0,3}$");
             re.compile ("^.*/lib.+\.so(\.[0-9]+){0,3}$");

  magic_bytes_count_for_ELF : constant integer range 4 .. 4 := 4;
  subtype magic_bytes_range_for_ELF is
     integer range 1 .. magic_bytes_count_for_ELF;
  magic_bytes_for_ELF : constant array (magic_bytes_range_for_ELF)
                            of character := ( character'val (16#7f#),
                                              character'val (16#45#),
                                              character'val (16#4c#),
                                              character'val (16#46#) );

  function path_name_is_shared_library (path_name : in string)
  return boolean is
  begin
    return re.match (re_for_shared_library, path_name);
  end path_name_is_shared_library;

  function file_seems_to_be_ELF (file : char_io.file_type)
  return boolean is
    seems_ELF : boolean := true;
    i         : integer := 1;
    c         : character;
  begin
    while seems_ELF and i <= magic_bytes_count_for_ELF loop
      if char_io.end_of_file (file) then
        seems_ELF := false;
      else
        char_io.read (file => file, item => c);
        if c /= magic_bytes_for_ELF (i) then
          seems_ELF := false;
        end if;
      end if;
      i := i + 1;
    end loop;
    return seems_ELF;
  end file_seems_to_be_ELF;

  function file_seems_to_be_ELF (file_name : in string)
  return boolean is
    use ada.directories;
    use char_io;
    file      : file_type;
    seems_ELF : boolean;
  begin
    if exists (file_name) then
      open (file => file, mode => in_file, name => file_name);
      seems_ELF := file_seems_to_be_ELF (file);
      close (file => file);
    else
      seems_ELF := false;
    end if;
    return seems_ELF;
  end file_seems_to_be_ELF;

  procedure make_symlink_no_clobber (source_name : in string;
                                     target_name : in string;
                                     warn        : boolean) is
    use ada.directories;
    use interfaces.c;
    use interfaces.c.strings;
    use notification;

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

  procedure make_linker_script_for_shared_library (source_name : in string;
                                                   target_name : in string;
                                                   warn : boolean) is
    use ada.text_io;
    file : file_type;
  begin
    create (file => file, mode => out_file, name => target_name);
    put (file => file, item => "GROUP ( ");
    put (file => file, item => source_name);
    put (file => file, item => " )");
    new_line (file => file);
    close (file => file);
  end make_linker_script_for_shared_library;

  procedure make_linker_script_or_symlink (source_name : in string;
                                           target_name : in string;
                                           warn        : boolean) is
    use ada.directories;
    use notification;
  begin
    if exists (target_name) then
      perhaps_notify (warn, "Not overwriting " & target_name);
    elsif path_name_is_shared_library (source_name)
          and then file_seems_to_be_ELF (source_name) then
      make_linker_script_for_shared_library (source_name => source_name,
                                             target_name => target_name,
                                             warn => warn);
    else
      make_symlink_no_clobber (source_name => source_name,
                               target_name => target_name,
                               warn => warn);
    end if;
  end make_linker_script_or_symlink;

  function simple_name_is_significant (name : in string)
  return boolean is
  begin
    return (name /= "." and then name /= "..");
  end simple_name_is_significant;

  procedure create_directory_forgivingly (new_directory : in string;
                                          warn          : in boolean) is
    use ada.directories;
    use notification;
  begin
    create_directory (new_directory => new_directory);
  exception
    when use_error =>
      perhaps_notify (warn, "Cannot create directory " & new_directory);
  end create_directory_forgivingly;

  type quasi_copier is access procedure (source_name : in string;
                                         target_name : in string;
                                         warn        : in boolean);

  procedure do_quasi_copying (quasi_copy  : quasi_copier;
                              source_dir  : in string;
                              environ_dir : in string;
                              warn        : in boolean) is
    use ada.directories;
    use notification;
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
              if exists (env_dir) then
                perhaps_notify (warn, "Not overwriting " & env_dir);
              else
                create_directory_forgivingly (new_directory => env_dir,
                                              warn => warn);
              end if;
              if exists (env_dir) then
                do_quasi_copying (quasi_copy => quasi_copy,
                                  source_dir => src_dir,
                                  environ_dir => env_dir,
                                  warn => warn);
              end if;
            end;
          when others =>
            quasi_copy (source_name => full_name (f),
                        target_name => environ_dir & "/" & simple_name (f),
                        warn => warn);
        end case;
      end if;
    end loop;
    end_search (handle);
  end do_quasi_copying;

  procedure do_quasi_copying (quasi_copy : quasi_copier;
                              args       : arg_functions;
                              warn       : in boolean) is

    use ada.directories;
    use notification;

    argcnt : constant natural := args.arg_count.all;

    subtype source_dir_range is integer range 1 .. argcnt - 1;

    function source_dir (n : in source_dir_range)
    return string is
    begin
      return args.arg_string (n);
    end source_dir;

    function environ_dir
    return string is
    begin
      return args.arg_string (argcnt);
    end environ_dir;

  begin
    for i in source_dir_range loop
      if not exists (source_dir (i)) then
        perhaps_notify (warn, source_dir (i) & " does not exist.");
      elsif kind (source_dir (i)) /= directory then
        perhaps_notify (warn, source_dir (i) & " is not a directory.");
      else
        do_quasi_copying (quasi_copy => quasi_copy,
                          source_dir => source_dir (i),
                          environ_dir => environ_dir,
                          warn => warn);
      end if;
    end loop;
  end do_quasi_copying;

  procedure do_symlinks (args : arg_functions;
                         warn : in boolean) is
  begin
    do_quasi_copying (make_symlink_no_clobber'access, args, warn);
  end do_symlinks;

  procedure do_libraries (args : arg_functions;
                          warn : in boolean) is
  begin
    do_quasi_copying (make_linker_script_or_symlink'access, args, warn);
  end do_libraries;

end quasi_copying;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
