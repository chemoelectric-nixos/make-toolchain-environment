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

with ada.text_io;

package body notification is

  procedure perhaps_notify (notify  : in boolean;
                            message : in string) is
    use ada.text_io;
  begin
    if notify then
      put (message);
      new_line;
    end if;
  end perhaps_notify;

end notification;

-- Local Variables:
-- mode: indented-text
-- indent-tabs-mode: nil;
-- tab-width: 2
-- comment-start: "-- "
-- coding: utf-8
-- End:
