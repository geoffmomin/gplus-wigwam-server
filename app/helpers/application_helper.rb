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

# Provides methods that should be globally available to all controllers and
# views, generally dealing with authorization logic.
#
# Author:: samstern@google.com (Sam Stern)
module ApplicationHelper
  require 'google/api_client'
  require 'base64'
  require 'json'

  AUTH_URI = 'https://accounts.google.com/o/oauth2/auth'
  TOKEN_URI = 'https://accounts.google.com/o/oauth2/token'

  # Maintain one reusable Google API Client per thread,
  # clearing the authorization credentials each time
  def new_gapi_client
    client = (Thread.current[:client] ||= Google::APIClient.new)
    client.authorization.clear_credentials! unless client.authorization.nil?
    return client
  end

  # Create an authorization object for the gapi_client.
  # Params:
  # +conn+:: a Connection object representing the user's active session.
  def gapi_authorization(conn = nil)
    auth = Signet::OAuth2::Client.new(
      authorization_uri: AUTH_URI,
      token_credential_uri: TOKEN_URI,
      client_id: ENV['GPLUS_APP_ID'],
      client_secret: ENV['GPLUS_APP_SECRET'],
      redirect_uri: ENV['GPLUS_REDIRECT'],
      scope: 'https://www.googleapis.com/auth/plus.login ' +
        'https://www.googleapis.com/auth/userinfo.email ' +
        'https://www.googleapis.com/auth/calendar'
    )

    # Set the access token, refresh token, and expiration from the existing
    # connection.
    unless conn.nil?
      auth.access_token = conn.oauth_token
      auth.refresh_token = conn.refresh_token
      auth.expires_in = conn.expires_in.to_i
    end

    return auth
  end

  # Return a gapi_client that the application can use to access Google APIs.
  # Params:
  # +conn+:: a Connection object representing the user's active session.
  def get_gapi_client(conn = nil)
    # Get a clear client
    client = new_gapi_client
    client.authorization = gapi_authorization(conn)
    return client
  end

  # Decode a Google id_token that is returned as part of the authorization flow.
  # the token is separated into three sections separated by a '.', the middle
  # section containing user information.  Each section is a JSON String encoded
  # with Base64.  The error handling adds '==' as padding due to a small bug in
  # the Base64 class that can happen with tokens of a certain length.
  # Params:
  # +token+:: the id_token string to decode.
  def decode_id_token(token)
    token_pieces = token.split('.')
    begin
      return token_parsed = JSON.parse(Base64.decode64(token_pieces[1]))
    rescue
      return token_parsed = JSON.parse(Base64.decode64(token_pieces[1] + '=='))
    end
  end

  # Verify an id_token with Google, confirm that it is issued for the
  # correct application and that it is valid.
  # Params:
  # +token+:: the id_token string to verify
  def verify_token(id_token)

    token_info = nil
    begin
      base = 'https://www.googleapis.com/oauth2/v1/tokeninfo?id_token='
      url = URI.parse("#{base}#{id_token}")

      token_info = JSON.parse(get_request(url).body)
    rescue => e
      raise ArgumentError.new('Failed to read token data from Google')
    end

    # Check for error in response
    error = token_info['error']
    raise ArgumentError.new(error) unless error.nil?

    # Check that both the local client_id and the returned client_id match
    # this regex.  Then check that they have the same prefix.
    id_regex = /^(\d+)([-]?)(.*)$/
    local_match = ENV['GPLUS_APP_ID'] =~ id_regex
    remote_match = token_info['issued_to'] =~ id_regex

    local_group = ENV['GPLUS_APP_ID'].scan(id_regex)[0][0]
    remote_group = token_info['issued_to'].scan(id_regex)[0][0]

    if !local_match || !remote_match || !(local_group.eql?(remote_group))
      raise ArgumentError.new("Token's client ID does not match app's.")
    end

    return token_info
  end

  # Makes a get request over HTTPS to a given URI object.  Returns the
  # server response.
  # Params:
  # +url+:: the URI to which a request should be made.
  def get_request(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(url.request_uri)
    response = http.request(request)

    return response
  end

  # Return the current User object, based on the user_id stored in the session.
  # returns nil if no User is currently authenticated.
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  # Return the active Connection object of the current User.  This is determined
  # by the most recent Connection object associated witht the User.
  def current_conn
    @current_conn ||= current_user.active_connection if session[:user_id]
  end

  # Determine if a valid User Session exists.  Returns true if there is a
  # user_id stored in the session and if the oauth_token associated with that
  # user is not expired.  False otherwise.
  def signed_in?
    # Check if user session exists
    if !(session[:user_id].nil?)
      # Check if oauth token is expired
      current_conn.oauth_expires_at > DateTime.now
    else
      false
    end
  end

  # Returns true if there is a valid session active for the given provider,
  # false otherwise.
  # Params:
  # +provider+:: the String (or symbol) of the provider.  Ex: gplus or facebook.
  def signed_into?(provider)
    if signed_in?
      provider.to_sym.eql?(current_conn.provider.to_sym)
    else
      false
    end
  end

end
