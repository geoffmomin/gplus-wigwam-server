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

# Model class representing Users on the app.  A User can own Wigwams, Rentals,
# Listings, and Connections.  When the User is destroyed, its Wigwams, Rentals,
# and Listings are also destroyed.
#
# Author:: samstern@google.com (Sam Stern)
class User < ActiveRecord::Base

  attr_accessible :email

  has_many :wigwams, dependent: :destroy
  has_many :rentals, dependent: :destroy
  has_many :listings, through: :wigwams
  has_many :connections, dependent: :destroy

  # Determine if the user owns any other object.
  # Params:
  # +object+:: the object to test, can be anything with a user_id accessor.
  def owns?(object)
    object.user_id == id
  end

  # Determine if this user has an upcoming (or current) rental of a Wigwam
  # Params:
  # +wigwam+:: the Wigwam object in question.
  def renting?(wigwam)
    matches = Rental.where(wigwam_id: wigwam.id, user_id: self.id)
    future_matches = matches.select { |x| x.end_date > DateTime.now }
    !future_matches.empty?
  end

  # Return the next rental for this user for a given wigwam.
  # Params:
  # +wigwam+:: the Wigwam in question.
  def rental_for(wigwam)
    return nil unless renting?(wigwam)
    possible = rentals.where(wigwam_id: wigwam.id)
    rental = possible.select { |x| x.end_date > DateTime.now }.first
    rental
  end

  # Find the Facebook friends of a user whose names match a given query either
  # fully or partially
  # Params:
  # +query+:: a string that will be substring-matched against friend names.
  def find_friends(query)
    # Fetch user's Facebook friends
    user = FbGraph::User.me(active_connection.oauth_token).fetch
    results = user.friends({ fields: 'id,name,picture' })
    # Filter down to important attributes
    results = results.map { |x| x.raw_attributes }
    # Only return search matches if there is a query parameter
    if !query.nil? && (query.is_a? String)
      results = results.select do |x|
        x[:name].downcase.include? query.downcase
      end
    end
    return results
  end

  # Returns the active Connection object for a user, determined by the
  # Connection that was most recently updated.
  def active_connection
    connections.first(order: 'updated_at desc', limit: 1)
  end

  # Return the user's name, based on the name they provided to the network
  # of their most recent connection.
  def name
    active_connection.name
  end

  # Return the User's connection for a specific provider.
  # Params:
  # +provider+:: the social provider (gplus, facebook, etc)
  def connection_for(provider)
    connections.where(provider: provider).first
  end

end
