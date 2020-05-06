# Copyright (C) 2018 Don Kelly <karfai@gmail.com>
# Copyright (C) 2018 Hayk Pilosyan <hayk.pilos@gmail.com>

# This file is part of Interlibr, a functional component of an
# Internet of Rules (IoR).

# ACKNOWLEDGEMENTS
# Funds: Xalgorithms Foundation
# Collaborators: Don Kelly, Joseph Potvin and Bill Olders.

# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public
# License along with this program. If not, see
# <http://www.gnu.org/licenses/>.

require 'multi_json'
require_relative 'lib/xa/rules/parse/content'

include XA::Rules::Parse::Content

def run
    input_file = ARGV[0]
    output_file = (ARGV[1] != nil) ? ARGV[1] : "#{input_file}.json"

    if input_file.end_with?(".rule")
        IO.write(output_file, MultiJson.dump(parse_rule(IO.read(input_file)), pretty: true))
    elsif input_file.end_with?(".table")
        IO.write(output_file, MultiJson.dump(parse_table(IO.read(input_file)), pretty: true))
    else
        raise 'File type not *.rule or *.table'
    end
end

if ARGV[0] == nil
    raise 'Please provide a .rule or .table file to parse'
else
    run
end