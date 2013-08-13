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

# Model class representing a Wigwam.  A Wigwam belongs to a User, and can have
# many Listings and Rentals.  When a Wigwam is destroyed, its Listings and
# Rentals are destroyed as well.
#
# Author:: samstern@google.com (Sam Stern)
class Wigwam < ActiveRecord::Base
  include GeoKit::Geocoders
  attr_accessible :city, :description, :name,
                  :price, :src, :state, :street,
                  :user_id, :zip, :lat, :lng
  belongs_to :user
  has_many :listings, dependent: :destroy
  has_many :rentals, dependent: :destroy

  before_save :geocode!

  # Return the full address of the Wigwam, formatted as a String.
  def full_address
    "#{street}, #{city}, #{state} #{zip}"
  end

  # Turn the given address into a latitude and longitude coordinate
  # by reverse geocoding with GeoKit.
  def geocode!
    res = MultiGeocoder.geocode(full_address)
    if res.success
      self.lat = res.lat
      self.lng = res.lng
    end
  end

  # Find wigwams in a given date range.  If one or both arguments
  # are nil, return the last <= 20 wigwams.
  # Params:
  # +from_date+:: Date String for the start of the range
  # +to_date+:: Date String for the end of the range.
  def self.find_in_range(from_date, to_date)
    if from_date && to_date
      listings = Listing.where('start_date <= ? AND end_date >= ?',
                               from_date,
                               to_date)
      wigwams = listings.map(&:wigwam).uniq
    else
      wigwams = Wigwam.find(:all, limit: 20)
    end
    return wigwams
  end

  # Create the initial listing for a wigwam upon creation so that it
  # may be rented.
  # Params:
  # +start_date+:: Date String for the start of the listing.
  # +end_date+:: Date String for the end of the listing.
  def create_initial_listing(start_date, end_date)
    listing = self.listings.build(start_date: start_date,
                                  end_date: end_date)
    listing.save
  end

  # Get the full URL for this Wigwam
  def full_url
    ApplicationController.base_url + "/wigwams/#{id}"
  end

end
