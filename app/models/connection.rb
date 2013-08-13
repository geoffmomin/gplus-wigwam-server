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

# Model class representing social Connection for a User.  A connection has a
# provider (gplus or facebook), oauth information, and belongs to a User.
#
# Author:: samstern@google.com (Sam Stern)
class Connection < ActiveRecord::Base

  attr_accessible :user_id, :provider, :uid, :oauth_token, :oauth_expires_at,
                  :name

  belongs_to :user

  # Create a connection from an OmniAuth hash object.  If there is a
  # user in the database whose email matches the new connection, link it to
  # that user.  Otherwise create a new user to link to the connection.
  # Params:
  # +auth+:: a hash in the OmniAuth format.
  #   see: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  def self.from_omniauth(auth)
    # Extract the unique identifier information from the OminAuth Hash
    auth_params = auth.slice(:provider, :uid)
    # Find or create a connection based on that information
    where(auth_params).first_or_initialize.tap do |conn|
      # This info changes every time in order to make sure it's
      # always up to date, even if they change something on the provider end
      conn.provider = auth[:provider]
      conn.uid = auth[:uid]
      conn.name = auth[:info][:name]
      conn.oauth_token = auth[:credentials][:token]
      conn.oauth_expires_at = Time.at(auth[:credentials][:expires_at].to_i)
      # If the connection has no linked user, try to find a user by email.
      # If no such user exists, create a new user to link to the connection.
      if auth[:info][:email].nil?
        user = User.create
        conn.user_id = user.id
      else
        user_params = auth[:info].slice(:email)
        User.where(user_params).first_or_initialize.tap do |user|
          conn.user_id = user.id if conn.user_id.nil?
          user.save!
        end
      end
      # Finally, save the connection
      conn.save!
    end
  end

  # Returns the number of seconds until the connection expires.
  def expires_in
    oauth_expires_at - DateTime.now()
  end

end
