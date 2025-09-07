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
with ada.text_io;
with gnat.command_line;
with gnat.strings;

with dist_version;

package body command_line is

  use ada.command_line;
  use ada.text_io;
  use gnat.command_line;

  showing_version : aliased boolean;

  procedure prepare_command_line_configuration
            (config : in out command_line_configuration) is
  begin
    define_switch (config => config,
                   switch => "-l",
                   long_switch => "--libraries",
                   output => libraries'access,
                   help => "for shared libraries, use linker " &
                           "scripts instead of symlinks");
    define_switch (config => config,
                   switch => "-e:",
                   long_switch => "--regexp=",
                   output => regexp'access,
                   help => "specify a regular expression for " &
                           "--libraries (implies --libraries)");
    define_switch (config => config,
                   switch => "-v",
                   long_switch => "--verbose",
                   output => verbose'access,
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

  procedure interpret_the_command_line is
    config : command_line_configuration;
  begin
    bail_out := false;
    prepare_command_line_configuration (config);
    getopt (config);
    if showing_version then
       bail_out := true;
       show_version;
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
