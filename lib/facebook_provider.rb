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

# Class to encapsulate all of the Facebook functionality of the app.  See the
# Provider superclass for method explanations.
#
# Author:: samstern@google.com
class FacebookProvider < Provider

  # Share a Wigwam on the Open Graph.
  # Params:
  # +wigwam+:: the Wigwam to share.
  # +friends+:: friends to tag in the share.
  # +connection+:: the Connection object representing the current user's
  #   credential.
  def graph_share_wigwam!(wigwam, friends, connection)
    me = FbGraph::User.me(connection.oauth_token)

    # Convert hash of index => id to comma separated list of ids (if not nil)
    tags = friends.nil? ? '' : friends.values.reduce { |a, e| "#{a},#{e}" }

    # Share on OpenGraph
    me.og_action!(
      "#{ENV['FB_NS']}:share",
      wigwam: wigwam.full_url,
      tags: tags
    )
  end

  # Share a Wigwam on the user's Facebook feed.
  # Params:
  # +wigwam+:: the Wigwam to share
  # +connection+:: the Connection object representing the current user's
  #   credential.
  def feed_share_wigwam!(wigwam, connection)
    me = FbGraph::User.me(connection.oauth_token)

    # Share in News Feed
    me.feed!(
      message: 'Check out this wigwam!',
      picture: wigwam.src,
      link: wigwam.full_url,
      name: wigwam.name,
      caption: wigwam.description
    )
  end

  # Share an Rental or Listing as an Open Graph action.  For a Rental, the
  # action is a namespace:rent.  For a Listing, the action is namespace:list.
  # The object shared is the Wigwam linked to the event.
  # Params:
  # +event+:: the Rental or Listing to share.
  def graph_share_event!(event)
    action = event.action_type(:facebook)

    # Post OpenGraph action with start_time and end_time
    app = FbGraph::Application.new(ENV['FB_APP_ID'])
    me = FbGraph::User.me(event.user.active_connection.oauth_token)

    begin
      action = me.og_action!(
        action,
        wigwam: event.wigwam_url,
        start_date: event.start_date.to_i,
        end_date: event.end_date.to_i
      )
    rescue => e
      Rails.logger.info(e)
      # This means posting to FB Failed.
      return true
    end
    return true
  end

  # Create a Facebook events on the user's Evetns representing a party at a
  # Wigwam.  The party will take place all day on the date of the user's next
  # rental at that Wigwam.  The location of the party will be the Wigwam's
  # address.
  # Params:
  # +wigwam+:: the Wigwam to share.
  # +connection+:: the Connection for the current user, normally
  #   current_user.active_connection.
  def create_calendar_event!(wigwam, connection)
    user = FbGraph::User.me(connection.oauth_token)
    rental = connection.user.rental_for(wigwam)
    event = user.event!(
      name: "Party at #{wigwam.name}",
      start_time: rental.start_date,
      end_time: rental.end_date
    )
    return "https://www.facebook.com/events/#{event.identifier}"
  end

  # Create a User object, and associated Connection, from authorization
  # information sent from the mobile client.
  # Params:
  # +params+:: the parameters hash from the request, passed from a Controller.
  def user_from_hybrid_auth(params)
    me = FbGraph::User.me(params[:access_token]).fetch

    user = User.where(email: me.email).first_or_initialize.tap do |u|
      u.save!
    end

    conn_params = { uid: me.identifier, provider: 'facebook' }
    conn = Connection.where(conn_params).first_or_initialize.tap do |c|
      c.user_id = user.id
      c.name = me.name
      c.oauth_token = params['access_token']
      c.oauth_expires_at = params['expires_at']
      c.save!
    end

    return user
  end

  # Disconnect the User completely from Facebook. This involves deleting the
  # connection and all information gathered from Facebook.
  # Params:
  # +user+:: the User to disconnect.
  def disconnect(user)
    conn = user.connection_for(:gplus)
    conn.desroy unless conn.nil?
  end

end
