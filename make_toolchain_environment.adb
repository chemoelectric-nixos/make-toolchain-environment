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
with ada.strings.unbounded;
with ada.text_io;
with interfaces.c;
with gnat.regpat;

with command_line;
with quasi_copying;

procedure make_toolchain_environment is

  use command_line;
  use quasi_copying;

  package cmdln renames ada.command_line;
  package re renames gnat.regpat;

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

  procedure suggest_help is
    use ada.text_io;
  begin
    put ("try """);
    put_progname;
    put (" --help"" for more information.");
    new_line;
  end suggest_help;

  procedure compile_regexp is
    use ada.strings.unbounded;
    use ada.text_io;
    use interfaces.c;

    procedure compile_re_libraries
                (re_string                   : in out char_array;
                 re_string_length            : in size_t;
                 error_indicator             : out int;
                 error_message_buffer        : in out char_array;
                 error_message_buffer_length : in size_t);
    pragma import (c, compile_re_libraries, "compile_re_libraries");

    regexp_str       : constant string := to_string (regexp);
    regexp_len       : constant integer := length (regexp);
    pattern_len      : size_t := size_t (regexp_len);
    pattern          : char_array (1 .. pattern_len);
    error_msg_buflen : size_t := size_t (1000);
    error_msg        : char_array (1 .. error_msg_buflen);
    error_indicator  : int;
  begin
    to_c (item => regexp_str, target => pattern,
          count => pattern_len, append_nul => false);
    compile_re_libraries (pattern, pattern_len,
                          error_indicator,
                          error_msg, error_msg_buflen);
    if 0 <= error_indicator then
      bail_out := true;
      cmdln.set_exit_status (cmdln.failure);
      start_with_progname;
      put (to_ada (error_msg));
      put (" at position");
      put (error_indicator'image);
      new_line;
      suggest_help;
    end if;
  end compile_regexp;

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
      bail_out := true;
      cmdln.set_exit_status (cmdln.failure);
      start_with_progname;
      put ("you must specify some directories.");
      new_line;
      suggest_help;
    elsif not source_dirs_are_all_absolute then
      bail_out := true;
      cmdln.set_exit_status (cmdln.failure);
      suggest_help;
    elsif not exists (environ_dir) or else
        kind (environ_dir) /= directory then
      bail_out := true;
      cmdln.set_exit_status (cmdln.failure);
      start_with_progname;
      put ("""");
      put (environ_dir);
      put (""" is not a directory.");
      new_line;
      suggest_help;
    end if;
  end check_args;

  procedure dispatch is
  begin
    if command_line.libraries then
      quasi_copying.do_libraries (command_line.args,
                                  command_line.verbose);
    else
      quasi_copying.do_symlinks (command_line.args,
                                 command_line.verbose);
    end if;
  end dispatch;

begin
  cmdln.set_exit_status (cmdln.success);
  interpret_the_command_line;
  if libraries and not bail_out then
    compile_regexp;
  end if;
  if not bail_out then
    check_args;
  end if;
  if not bail_out then
    dispatch;
  end if;
end make_toolchain_environment;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
