# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Define a common set of methods for any object with attributes start_date and
# end_date.  Can detect overlaps with other objects, etc.
#
# Author:: samstern@google.com
module StartAndEndDates

  # Format date for display (start or end)
  # Params:
  # +date+:: the Date to format.
  def date_to_string(date)
    format = '%B %d, %Y'
    if date.eql? :start
      start_date.strftime(format)
    elsif date.eql? :end
      end_date.strftime(format)
    else
      'N/A'
    end
  end

  # Return a hash that determines how this interval overlaps
  # with another interval.
  # Params:
  # +other+:: the other interval to check.
  def get_overlaps(other)
    starts_before = start_date <= other.start_date
    ends_before = end_date <= other.end_date
    starts_during = (!starts_before && (start_date <= other.end_date))
    ends_during = (ends_before && (end_date >= other.start_date))

    start_within = (starts_during && !ends_before)

    # Four cases:
    # 1) This interval starts within the other interval
    # 2) This interval ends within the other interval
    # 3) This interval entirely contains the other interval
    # 4) This interval is entirely contained by the other (1 && 2)
    { start_within: starts_during,
      end_within: ends_during,
      contains: (starts_before && !ends_before),
      contained: (starts_during && ends_during) }
  end

  # Boolean method.  Determine if this interval overlaps
  # with another interval.
  # Params:
  # +other+:: the other interval to check.
  def overlaps?(other)
    overlaps = get_overlaps(other)
    # Check if any of the overlap cases are true
    has_overlap = false
    overlaps.each_value { |x| has_overlap ||= x }
    return has_overlap
  end

end
