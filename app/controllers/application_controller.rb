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

# Base class for controllers throughout the application.  Abstracts some global
# logic such as error handling.  Handles the following requests:
#
#   GET /
#
# Author:: samstern@google.com (Sam Stern)
#
class ApplicationController < ActionController::Base
  include ApplicationHelper
  protect_from_forgery

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # Rescue from ArgumentError with status code 401 and a JSON message.
  rescue_from ArgumentError do |e|
    render json: e.inspect, status: 401
  end

  before_filter :set_base_url

  # Keep track of the application's base url so that
  # absolute links can be formed for sharing
  @base_url = ''
  def self.base_url
    @base_url
  end

  # Setter for @base_url
  def self.base_url=(url)
    @base_url = url
  end

  # Set the base url based on the current request
  def set_base_url
    ApplicationController.base_url =
      "#{request.protocol}#{request.host}:#{request.port}"
  end

  # Handles the following endpoint:
  #   GET /
  # Renders the home page of the application, including the last ten listings
  # and rentals recorded.
  def index
    @listings = Listing.last_ten
    @rentals = Rental.last_ten
  end

  # Respond with the message 'Record Not Found' and a 404 Status Code when a
  # non-existent record is requested.
  def record_not_found
    render json: 'Record not found.', status: 404
  end

end
