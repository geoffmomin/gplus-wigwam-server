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

# Model class representing Listings of Wigwams by Users.  A Listing has a
# start date and an end date, and belongs to only one Wigwam and one User.  The
# User to which a Listing belongs is determined by the Wigwam.
#
# Author:: samstern@google.com (Sam Stern)
class Listing < ActiveRecord::Base
  include Event
  include StartAndEndDates
  include ApplicationHelper
  attr_accessible :end_date, :start_date, :wigwam_id

  before_save :make_viable!
  after_create :social_share

  belongs_to :wigwam
  delegate :user_id, to: :wigwam
  delegate :user, to: :wigwam

  # Trim the listing in order to remove conflicts with other
  # listings and rentals.  Return false (a.k.a do not save)
  # if this is not possible or the listing is redundant
  def make_viable!
    old_listings = self.wigwam.listings
    old_listings.each do |old|
      overlaps = get_overlaps(old)
      # Start of this interval is within old interval
      self.start_date = old.end_date if overlaps[:start_within]
      # End of this interval is within old interval
      self.end_date = old.start_date if overlaps[:end_within]
      # This interval contains an entire old interval
      old.delete if overlaps[:contains]
      # This interval is contained in an old interval, don't save
      return false if overlaps[:contained]
    end
  end

end
