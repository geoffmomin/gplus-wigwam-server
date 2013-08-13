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

# Model class representing Rentals of Wigwams by Users.  A Rental has a
# start date and an end date, and belongs to only one Wigwam and one User.
#
# Author:: samstern@google.com (Sam Stern)
class Rental < ActiveRecord::Base
  include Event
  include StartAndEndDates
  include ApplicationHelper

  attr_accessible :end_date, :start_date, :user_id, :wigwam_id

  belongs_to :wigwam
  belongs_to :user

  before_save :is_viable?
  after_create :social_share #, :notify_owner

  # Determine if a rental falls in a date range where the
  # desired wigwam is available and does not conflict with any
  # pre-existing listings
  def is_viable?
    viable = false
    # Must be contained in a listing
    self.wigwam.listings.each do |listing|
      overlaps = self.get_overlaps(listing)
      viable = true if overlaps[:contained]
    end
    # Can't overlap another rental
    self.wigwam.rentals.each do |rental|
      viable = false if self.overlaps?(rental)
    end
    return viable
  end

end
