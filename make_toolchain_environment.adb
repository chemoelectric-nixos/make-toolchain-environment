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

with ada.command_line;
with ada.directories;
with ada.exceptions;
with ada.sequential_io;
with ada.text_io;
with interfaces.c;
with interfaces.c.strings;
with gnat.command_line;
with gnat.regpat;

with command_line;
with quasi_copying;

procedure make_toolchain_environment is

  use command_line;
  use quasi_copying;

  package cmdln renames ada.command_line;
  package gcmdln renames gnat.command_line;
  package re renames gnat.regpat;

  c_io_error : exception;

  re_for_progname : constant re.pattern_matcher :=
                             re.compile ("/([^/]*)$");

  re_for_absolute_path : constant re.pattern_matcher :=
                                  re.compile ("^/.*");

  progname : string := cmdln.command_name;

  procedure put_progname is
    use ada.text_io;
    i : constant natural := re.match (re_for_progname, progname, 1) + 1;
  begin
    put (progname (i .. progname'last));
  end put_progname;

  function path_name_is_absolute (path_name : in string)
  return boolean is
  begin
    return re.match (re_for_absolute_path, path_name);
  end path_name_is_absolute;

  procedure start_with_progname is
    use ada.text_io;
  begin
    put_progname;
    put (": ");
  end start_with_progname;

  procedure inform_about_usage is
    use ada.text_io;
  begin
    put ("Usage: ");
    put_progname;
    put (" symlinks+ dir1 dir2 ... dirN environDir");
    new_line;
    put ("       ");
    put_progname;
    put (" symlinks- dir1 dir2 ... dirN environDir");
    new_line;
    put ("       ");
    put_progname;
    put (" libraries+ dir1 dir2 ... dirN environDir");
    new_line;
    put ("       ");
    put_progname;
    put (" libraries- dir1 dir2 ... dirN environDir");
    new_line;
  end inform_about_usage;

  procedure usage_error is
  begin
    inform_about_usage;
    cmdln.set_exit_status (cmdln.failure);
  end usage_error;

  type environ_dir_filler is access procedure (argcount : in positive;
                                               arg      : cmdln_argfunc;
                                               warn     : in boolean);

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
    elsif operation = "libraries+" then
      require_correct_dirs (do_libraries'access, argcount, arg, true);
    elsif operation = "libraries-" then
      require_correct_dirs (do_libraries'access, argcount, arg, false);
    else
      usage_error;    
    end if;
  end dispatch;

begin
----------  ada.text_io.put (regexp.all);
----------  ada.text_io.new_line;
----------  ada.text_io.put (cmdln.argument_count'image);ada.text_io.new_line;
----------  declare
----------    eoa : boolean := false;
----------  begin
----------    while not eoa loop
----------      declare
----------        s : constant string := gcmdln.get_argument (end_of_arguments => eoa);
----------      begin
----------        if not eoa then
----------          ada.text_io.put (s);
----------          ada.text_io.new_line;
----------        end if;
----------      end;
----------    end loop;
----------  end;

  cmdln.set_exit_status (cmdln.success);
  interpret_the_command_line;
  if not bail_out then
    dispatch (cmdln.argument_count, cmdln.argument'access);
  end if;
end make_toolchain_environment;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
