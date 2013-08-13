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

# Class to encapsulate all of the Google functionality of the app.  See the
# Provider superclass for method explanations.
#
# Author:: samstern@google.com
class GoogleProvider < Provider

  # Share an Rental or Listing as an App Activity.  For a Rental, the activity
  # is a ReserveActivity.  For a Listing, the activity is an AddActivity.  The
  # object shared is the Wigwam linked to the event.
  # Params:
  # +event+:: the Rental or Listing to share.
  def graph_share_event!(event)
    action = event.action_type(:gplus)

    moment = {
      type: "http://schemas.google.com/#{action}",
      target: {
        url: event.wigwam_url
      }
    }

    if event.instance_of?(Rental)
      moment[:result] = { type: 'http://schemas.google.com/Reservation' }
    end

    client = get_gapi_client(event.user.active_connection)
    plus = client.discovered_api('plus')

    result = client.execute!(
      api_method: plus.moments.insert,
      parameters: {
        collection: 'vault',
        userId: 'me',
        debug: 'false'
      },
      headers: {
        'Content-Type' => 'application/json; charset=utf-8'
      },
      body: ActiveSupport::JSON.encode(moment)
    )
  end

  # Create an event on the user's Google Calendar representing a party at a
  # Wigwam.  The party will take place all day on the date of the user's next
  # rental at that Wigwam.  The location of the party will be the Wigwam's
  # address.
  # Params:
  # +wigwam+:: the Wigwam to share.
  # +connection+:: the Connection for the current user, normally
  #   current_user.active_connection.
  def create_calendar_event!(wigwam, connection)
    client = get_gapi_client(connection)
    cal = client.discovered_api('calendar', 'v3')

    rental = connection.user.rental_for(wigwam)

    event = {
      summary: "Party at #{wigwam.name}",
      location: wigwam.full_address,
      start: {
        dateTime: rental.start_date.to_date.rfc3339
      },
      :end => {
        dateTime: rental.end_date.to_date.rfc3339
      }
    }

    result = client.execute!(
      api_method: cal.events.insert,
      parameters: {
        calendarId: 'primary'
      },
      body: ActiveSupport::JSON.encode(event),
      headers: {
        'Content-Type' => 'application/json'
      }
    )

    return result.data.htmlLink
  end

  # Create a User object, and associated Connection, from authorization
  # information sent from the mobile client.
  # Params:
  # +params+:: the parameters hash from the request, passed from a Controller.
  def user_from_hybrid_auth(params)
    client = get_gapi_client

    params[:redirect_uri] ||= 'postmessage'
    client.authorization.redirect_uri = params['redirect_uri']
    client.authorization.code = params['code']
    client.authorization.fetch_access_token!

    # Verify the id_token before proceeding
    verify_token(client.authorization.id_token)

    token_decoded = decode_id_token(client.authorization.id_token)
    user_email = token_decoded['email']

    plus = client.discovered_api('plus')
    me_result = client.execute(
      api_method: plus.people.get,
      parameters: { userId: 'me' }
    )

    user = User.where(email: user_email).first_or_initialize.tap do |u|
      u.save!
    end

    user.connections.where(provider: 'gplus').first_or_initialize.tap do |c|
      c.uid = me_result.data['id']
      c.name = me_result.data['displayName']
      c.oauth_token = client.authorization.access_token
      c.refresh_token ||= client.authorization.refresh_token
      c.oauth_expires_at = Time.now() + client.authorization.expires_in
      c.save!
    end

    client.authorization.update_token!

    return user
  end

  # Disconnect the User completely from Google+.  This involves revoking the
  # access_token, deleting all information retrieved from Google+ APIs, and then
  # deleting the access_token and refresh_token.
  # Params:
  # +user+:: the User to disconnect.
  def disconnect(user)
    conn = user.connection_for(:gplus)
    unless conn.nil?
      token = conn.oauth_token

      # Revoke the token
      base = 'https://accounts.google.com/o/oauth2/revoke?token='
      url = URI.parse("#{base}#{token}")
      revoke_info = get_request(url)
      if revoke_info.code != 200
        Rails.logger.error("Token revoke fail, code: #{revoke_info.code}")
      end

      # Delete the connection (and therefore the data)
      conn.destroy
    end
  end

end
