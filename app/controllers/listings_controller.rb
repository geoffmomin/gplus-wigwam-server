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

# Handles request for creating and destroying Listings in the database.
# Provides the following endpoints:
#
#   POST /listings/
#   DELETE /listings/:id
#
# Author:: samstern@google.com (Sam Stern)
#
class ListingsController < ApplicationController

  # Handles the following endpoint:
  #   POST /listings/
  # Creates a new Listing based on the posted HTTP parameters.  Redirects to the
  # URL for the Listing's wigwam, which is at /wigwam/:id.
  def create
    @listing = Listing.new(params[:listing])
    if @listing.save
      flash[:success] = 'Availability added'
    else
      flash[:error] = 'Sorry, something went wrong'
    end
    redirect_to @listing.wigwam
  end

  # Handles the following endpoint:
  #   DELETE /listings/
  # Deletes a Listing object based on the posted id parameter.  Redirects to the
  # URL for the Listing's wigwam, which is at /wigwam/:id.
  def destroy
    @listing = Listing.find(params[:id])
    @wigwam = @listing.wigwam
    @listing.destroy
    redirect_to @wigwam
  end

end
