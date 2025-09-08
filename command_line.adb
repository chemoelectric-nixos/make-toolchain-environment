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
with ada.containers.vectors;
with ada.strings.unbounded;
with ada.text_io;
with gnat.command_line;
with gnat.strings;

with dist_version;

package body command_line is

  use ada.command_line;
  use ada.strings.unbounded;
  use ada.text_io;
  use gnat.command_line;

  subtype argument is ada.strings.unbounded.unbounded_string;
  package argument_vectors is new
    ada.containers.vectors (index_type => positive,
                            element_type => argument);

  showing_version : aliased boolean;
  libraries_val   : aliased boolean;
  regexp_val      : aliased gnat.strings.string_access;
  verbose_val     : aliased boolean;
  arg_vector      : argument_vectors.vector;

  procedure prepare_command_line_configuration
            (config : in out command_line_configuration) is
  begin
    define_switch (config => config,
                   switch => "-l",
                   long_switch => "--libraries",
                   output => libraries_val'access,
                   help => "for shared libraries use linker " &
                           "scripts instead of symlinks");
    define_switch (config => config,
                   switch => "-e:",
                   long_switch => "--regexp=",
                   output => regexp_val'access,
                   help => "same as --libraries, but using the " &
                           "given regular expression",
                   argument => "'PATTERN'");
    define_switch (config => config,
                   switch => "-v",
                   long_switch => "--verbose",
                   output => verbose_val'access,
                   help => "when something unusual happens, " &
                           "display a message");
    define_switch (config => config,
                   switch => "-h",
                   long_switch => "--help",
                   help => "display this help, then exit");
    define_switch (config => config,
                   output => showing_version'access,
                   long_switch => "--version",
                   help => "output version information, then exit");
  end prepare_command_line_configuration;

  procedure show_version is
  begin
    put (dist_version.progname);
    put (" ");
    put (dist_version.version);
    new_line;
    put ("Copyright (C) 2025 Barry Schwartz");
    new_line;
    put ("License GPLv3+: GNU GPL version 3 or later " &
         "<https://gnu.org/licenses/gpl.html>.");
    new_line;
    put ("This is free software: you are free to change and " &
         "redistribute it.");
    new_line;
    put ("There is NO WARRANTY, to the extent permitted by law.");
    new_line (2);
    put ("Written by Barry Schwartz.");
    new_line;
  end show_version;

  function arg_count
  return natural is
  begin
    return natural (arg_vector.length);
  end arg_count;

  function arg_string (number : in positive)
  return string is
  begin
    return to_string (arg_vector (number));
  end arg_string;

  procedure collect_arguments is
    eoa : boolean := false;
  begin
    while not eoa loop
      declare
        s : constant string := get_argument (end_of_arguments => eoa);
      begin
        if not eoa then
          arg_vector.append (to_unbounded_string (s));
        end if;
      end;
    end loop;
  end collect_arguments;

  procedure interpret_the_command_line is
    use gnat.strings;
    config : command_line_configuration;
  begin
    bail_out := false;
    prepare_command_line_configuration (config);
    getopt (config);
    if showing_version then
       bail_out := true;
       show_version;
    else
      if regexp_val /= null then
        declare
          regexp_str : string := regexp_val.all;
        begin
          regexp := to_unbounded_string (regexp_str);
          libraries := true;
        end;
      else
        regexp := to_unbounded_string (default_regexp);
        libraries := libraries_val;
      end if;
      verbose := verbose_val;
      collect_arguments;
    end if;
  exception
    when exit_from_command_line =>
      bail_out := true;
      new_line;
      put ("You may use the short name ""mte"" instead of " &
           """make-toolchain-environment"".");
      new_line (2);
      put ("The arguments are a list of directories, the last " &
           "of which is where part");
      new_line;
      put ("of an ""environment"" is to be constructed. All the other " &
           "directories must");
      new_line;
      put ("be absolute paths.");
      new_line;
    when others =>
      bail_out := true;
      set_exit_status (failure);
  end interpret_the_command_line;

end command_line;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
