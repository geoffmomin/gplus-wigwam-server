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

# Handles requests dealing with authorization, such as creating and destroying
# Sessions as well as authorizing from a mobile device.  Provides the following
# endpoints:
#
#   POST /auth/:provider/callback
#   GET /auth/:provider/signout
#   POST /auth/:provider/hybrid
#
# Author:: samstern@google.com (Sam Stern)
#
class SessionsController < ApplicationController

  # Handles the following endpoint:
  #   POST /auth/:provider/callback
  # Creates a new Session based on the posted HTTP parameters.  Uses OmniAuth.
  def create
    # TODO(samstern): Flash welcome back, or something else to
    # let the user know if they got a new account or if they were linked

    # OmniAuth will put the auth Hash in this variable.
    auth = env['omniauth.auth']
    conn = Connection.from_omniauth(auth)
    session[:user_id] = conn.user_id
    # TODO(samstern): server-side login with app activities and offline
    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { render json: [conn, auth[:info]] }
    end
  end

  # Handles the following endpoint:
  #   POST /auth/:provider/hybrid
  # Creates a new Session based on the information posted from the mobile
  # device.  Delegates to a Provider object in order to initiate the correct
  # authorization flow.
  def hybrid
    provider = Provider.get(params[:provider])
    user = provider.user_from_hybrid_auth(params)

    session[:user_id] = user.id

    respond_to do |format|
      format.json { render json: user, methods: [:name] }
    end
  end

  # Handles the following endpoint:
  #   GET /auth/:provider/signout
  # Destroys the current Session and redirects to the application root.
  def destroy
    # Disconnect from provider
    provider = Provider.get(current_conn.provider)
    provider.disconnect(current_user)

    # Destroy the session
    session[:user_id] = nil
    redirect_to root_url
  end

end
