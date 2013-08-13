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

# Handles request for creating Rentals in the database.
# Provides the following endpoints:
#
#   POST /rentals/
#   GET /rentals/new
#
# Author:: samstern@google.com (Sam Stern)
#
class RentalsController < ApplicationController

  # Handles the following endpoint:
  #   POST /rentals/
  # Creates a new Rental based on the posted HTTP parameters.  Redirects to the
  # URL for the Rental's wigwam, which is at /wigwam/:id.
  def create
    @rental = current_user.rentals.build(params[:rental])
    if @rental.save
      flash[:success] = 'Congrats! Rented this wigwam!'
    else
      flash[:error] = 'Sorry, that rental window is unavailable'
    end
    redirect_to @rental.wigwam
  end

  # Handles the following endpoint:
  #   GET /rentals/new
  # Renders the page for creating a new Rental.  Loads the list of Wigwams that
  # are eligible for the dates provided as URL parameters.
  def new
    # Find all wigwams which are listed in the selected date range
    @wigwams = Wigwam.find_in_range(params['from-date'], params['to-date'])
  end

end
