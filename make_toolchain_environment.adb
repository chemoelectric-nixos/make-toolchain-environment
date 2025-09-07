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
with gnat.regpat;

with command_line;
with quasi_copying;

procedure make_toolchain_environment is

  use command_line;
  use quasi_copying;

  package cmdln renames ada.command_line;
  package re renames gnat.regpat;

  c_io_error : exception;

  re_for_progname : constant re.pattern_matcher :=
                             re.compile ("/[^/]*$");

  re_for_absolute_path : constant re.pattern_matcher :=
                                  re.compile ("^/.*");

  function path_name_is_absolute (path_name : in string)
  return boolean is
  begin
    return re.match (re_for_absolute_path, path_name);
  end path_name_is_absolute;

  progname : string := cmdln.command_name;

  procedure put_progname is
    use ada.text_io;
    i : constant natural := re.match (re_for_progname, progname, 1) + 1;
  begin
    put (progname (i .. progname'last));
  end put_progname;

  procedure start_with_progname is
    use ada.text_io;
  begin
    put_progname;
    put (": ");
  end start_with_progname;

------------------  procedure dispatch (args : arg_functions) is
------------------    function operation
------------------    return string is
------------------    begin
------------------      return arg (1);
------------------    end operation;
------------------  begin
------------------    if argcount < 1 then
------------------      usage_error;
------------------    elsif operation = "symlinks+" then
------------------      require_correct_dirs (do_symlinks'access, argcount, arg, true);
------------------    elsif operation = "symlinks-" then
------------------      require_correct_dirs (do_symlinks'access, argcount, arg, false);
------------------    elsif operation = "libraries+" then
------------------      require_correct_dirs (do_libraries'access, argcount, arg, true);
------------------    elsif operation = "libraries-" then
------------------      require_correct_dirs (do_libraries'access, argcount, arg, false);
------------------    else
------------------      usage_error;    
------------------    end if;
------------------  end dispatch;

  procedure suggest_help is
    use ada.text_io;
  begin
    put ("try """);
    put_progname;
    put (" --help"" for more information.");
    new_line;
  end suggest_help;

  procedure check_args is

    use ada.directories;
    use ada.text_io;
    use command_line;

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

    function source_dirs_are_all_absolute
    return boolean is
      all_absolute : boolean := true;
    begin
      for i in source_dir_range loop
        if not path_name_is_absolute (source_dir (i)) then
          all_absolute := false;
          put ("""");
          put (source_dir (i));
          put (""" must be an absolute path.");
          new_line;
        end if;
      end loop;
      return all_absolute;
    end source_dirs_are_all_absolute;

  begin
    if argcnt < 1 then
      cmdln.set_exit_status (cmdln.failure);
      start_with_progname;
      put ("you must specify some directories.");
      new_line;
      suggest_help;
    elsif not exists (environ_dir) or else
        kind (environ_dir) /= directory then
      cmdln.set_exit_status (cmdln.failure);
      start_with_progname;
      put ("""");
      put (environ_dir);
      put (""" is not a directory.");
      new_line;
      suggest_help;
    elsif not source_dirs_are_all_absolute then
      cmdln.set_exit_status (cmdln.failure);
      suggest_help;
    end if;
  end check_args;

begin
  cmdln.set_exit_status (cmdln.success);
  interpret_the_command_line;
  if not bail_out then
    check_args;
-----    dispatch;
  end if;
end make_toolchain_environment;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
