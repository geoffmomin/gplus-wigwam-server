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

# A Superclass/Interface for all social providers, such as FacebookProvider and
# GoogleProvider. Abstracts social actions away from controller/helpers.
#
# Author:: samstern@google.com
class Provider
  include ApplicationHelper

  def initialize
  end

  # Return the Provider subclass specified by the string.
  # Params:
  # +provider+:: the String name of the Provider to return, always gplus or
  #   facebook.
  def self.get(provider)
    # Normalize
    provider = provider.to_sym
    if provider.eql?(:facebook)
      return FacebookProvider.new
    elsif provider.eql?(:gplus)
      return GoogleProvider.new
    end
  end

  # Share a Wigwam on the graph of the Provider
  # Params:
  # +wigwam+:: the Wigwam to share
  # +friends+:: friends to tag in the share.
  # +connection+:: the Connection object representing the current user's
  #   credential.
  def graph_share_wigwam!(wigwam, friends, connection)
    raise IncompleteProviderError.new('graph share wigwam')
  end

  # Share a Wigwam on the feed of the Provider
  # Params:
  # +wigwam+:: the Wigwam to share.
  # +connection+:: the Connection object representing the current user's
  #   credential.
  def feed_share_wigwam!(wigwam, connection)
    raise IncompleteProviderError.new('feed share wigwam')
  end

  # Share an event on the graph of the Provider.
  # Params:
  # +event+:: the object to share, can be any object that extends Event.
  def graph_share_event!(event)
    raise IncompleteProviderError.new('graph share event')
  end

  # Create a calendar event with the Provider.
  # Params:
  # +wigwam+:: the Wigwam object to share.
  # +connection+:: the Connection object representing the current user's
  #   credentials.
  def create_calendar_event!(wigwam, connection)
    raise IncompleteProviderError.new('calendar')
  end

  # Create a User object from authorization information sent from the client.
  # Params:
  # +params+:: the HTTP params hash sent with the request, unmodified.
  def user_from_hybrid_auth(params)
    raise IncompleteProviderError.new('hybrid auth')
  end

  # Fully disconnect a User from the app, following all required guidelines.
  # Params:
  # +user+:: the User to disconnect.
  def disconnect(user)
    raise IncompleteProviderError.new('disconnect')
  end

  # Error class to raise when Provider method is called but not
  # implemented.  This makes the provider a sort of "interface"
  # that will raise errors when not fully implemented.
  #
  # Author:: samstern@google.com
  class IncompleteProviderError < StandardError

    attr_accessor :msg

    def initialize(msg)
      @msg = msg
    end

    def to_s
      "Provider is missing feature: #{@msg}"
    end

  end

end
