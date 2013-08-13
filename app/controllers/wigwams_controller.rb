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

# Handles request for creating, listing, displaying, and sharing Wigwams.
# Provides the following endpoints:
#
#   GET /wigwams/new
#   POST /wigwams/
#   GET /wigwams/
#   GET /wigwams/:id
#   GET /wigwams/:id/share
#   GET /wigwams/:id/party
#   GET /wigwams/:id/availability
#
# Author:: samstern@google.com (Sam Stern)
#
class WigwamsController < ApplicationController

  # Handles the following endpoint:
  #   GET /wigwams/new
  # Renders the page for creating a new Wigwam.
  def new
    @wigwam = Wigwam.new
  end

  # Handles the following endpoint:
  #   POST /wigwams/
  # Creates a new Wigwam based on the posted HTTP parameters.  Redirects to the
  # wigwam's show URL if it is successful, otherwise back to the new Wigwam
  # page.
  def create
    # TODO(samstern): Validate wigwams
    @wigwam = current_user.wigwams.build(params[:wigwam])
    if @wigwam.save!
      flash[:success] = 'Wahoo! Wigwam listed!'
      # Create a listing
      @wigwam.create_initial_listing(params[:listing_start],
                                     params[:listing_end])
      # Show the new Wigwam page
      redirect_to @wigwam
    else
      # TODO(samstern): Re-render form with errors
      flash[:error] = 'Sorry, something went wrong.'
      redirect_to new_wigwam_path
    end
  end

  # Handles the following endpoint:
  #   GET /wigwams
  # Lists the last 20 Wigwams in the database as a JSON array.
  def index
    @wigwams = Wigwam.find(:all, limit: 20)

    respond_to do |format|
      format.json { render json: @wigwams }
    end
  end

  # Handles the following endpoint:
  #   GET /wigwams/:id
  # Renders the page for the Wigwam specified by :id, including its Rental and
  # Listing history.  When the request asks for JSON, the Wigwam is rendered as
  # a JSON object.
  def show
    @wigwam = Wigwam.find(params[:id], include: :listings)
    @listings = @wigwam.listings.find(:all, order: :start_date)
    @rentals = @wigwam.rentals.find(:all, order: :start_date)
    @listing = Listing.new
    @rental = Rental.new

    respond_to do |format|
      format.html
      format.json { render json: @wigwam }
    end
  end

  # Handles the following endpoint:
  #   GET /wigwams/:id/share
  # Shares the Wigwam specified by :id on Facebook.
  def share
    @wigwam = Wigwam.find(params[:id])
    # Share the wigwam on Open Graph and Feed
    facebook = Provider.get('facebook')
    facebook.graph_share_wigwam!(@wigwam, params[:friends], current_conn)
    facebook.feed_share_wigwam!(@wigwam, current_conn)

    # Render success message
    @message = 'Share successful!'
    render status: 200, layout: false
  rescue => e
    Rails.logger.debug(e)

    @message = 'Share failed.'
    render status: 400, layout: false
  end

  # Handles the following endpoint:
  #   GET /wigwams/:id/party
  # Creates a calendar event for the Wigwam specified by :id on the appropriate
  # social network.
  def party
    @wigwam = Wigwam.find(params[:id])
    # Create a party at the wigwam
    provider = Provider.get(current_conn.provider)
    event_url = provider.create_calendar_event!(@wigwam, current_conn)

    @message = "Party created!  Event page at: #{event_url}"
    render status: 200, layout: false
  rescue => e
    Rails.logger.debug(e)

    @message = 'Party could not be created.'
    render status: 400, layout: false
  end

  # Handles the following endpoint:
  #   GET /wigwams/:id/availability
  # Returns the Listing history for the Wigwam specified by :id as a JSON array.
  def availability
    @wigwam = Wigwam.find(params[:id])
    @listings = @wigwam.listings.map do |x|
      { start_date: x.start_date, end_date: x.end_date }
    end

    respond_to do |format|
      format.json { render json: @listings }
    end
  end

end
