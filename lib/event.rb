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

# Methods for Events that are owned by Wigwams (Listings, Rentals) and belong to
# a User.  Helpers for retrieval and sharting.
#
# Author:: samstern@google.com
module Event

  # Methods that should be defined as class methods on classes that
  # include Event.
  module ClassMethods
    # Return the last ten objects of this type, ordered by id.
    # Eager-load the associated Wigwam object with each.
    def last_ten
      find(:all, order: 'id desc', limit: 10, include: :wigwam)
    end
  end

  # Add the ClassMethods to any class that includes Event.
  # Params:
  # +base+: the class including Event.
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Return the full url of the Wigwam to which this object belongs.  Useful
  # for social sharing.
  def wigwam_url
    ApplicationController.base_url + '/wigwams/' + wigwam_id.to_s
  end

  # Post an App Activity or an Open Graph post
  def social_share
    provider = user.active_connection.provider
    Provider.get(provider).graph_share_event!(self)
  end

  # Module for an Event that will be shared on Google+.
  module GPlusEvent
    # Get a string representing the type of this event when sharing to a social
    # graph.
    def action_type
      if instance_of? Rental
        'ReserveActivity'
      else
        'AddActivity'
      end
    end
  end

  # Module for an Event that will be shared on Facebook
  module FacebookEvent
    # Get a string representing the type of this event when sharing to a social
    # graph.
    def action_type
      if instance_of? Rental
        "#{ENV['FB_NS']}:rent"
      else
        "#{ENV['FB_NS']}:list"
      end
    end
  end

  # Get a string representing the type of this event when sharing to a social
  # graph.
  # Params:
  # +provider+:: symbol for the social provider, should be :gplus or :facebook
  def action_type(provider)
    # Dynamically include the action_type method for the correct provider, and
    # then call it.
    if provider.eql? :facebook
      self.class.send(:include, FacebookEvent)
      action_type
    elsif provider.eql? :gplus
      self.class.send(:include, GPlusEvent)
      action_type
    end
  end

end
