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

WigwamServer::Application.routes.draw do

  # Creates routes:
  #   GET / - display the home page
  match '/' => 'application#index', :as => 'root'

  # Creates routes:
  #   GET /index.* - display the home page
  match '/index.:format' => 'application#index'

  # Creates routes:
  #   GET,POST /auth/:provider/callback - callback for OAuth2 flow.
  match '/auth/:provider/callback' => 'sessions#create'

  # Creates routes:
  #   GET /auth/:provider/signout - destroy the current session.
  match '/auth/:provider/signout' => 'sessions#destroy'

  # Creates routes:
  #   POST /auth/:provider/hybrid - initiate authorization from mobile.
  match '/auth/:provider/hybrid' => 'sessions#hybrid'

  # Creates routes:
  #   GET /facebooks/friends - list the user's Facebook friends.
  match '/facebooks/friends' => 'facebooks#friends'

  # Creates routes:
  #   GET /wigwams/ - list all wigwams.
  #   GET,POST /wigwams/:id - show a specific wigwam by id.
  #   GET /wigwams/:id/availability - get the listings for a wigwam by id.
  #   POST /wigwams/:id/share - share a wigwam.
  #   POST /wigwams/:id/party - create a calendar at a wigwam.
  resources :wigwams do
    member do
      post 'show'
      get  'availability'
      post 'share'
      post 'party'
    end
  end

  # Creates routes:
  #   POST /listings/ - create a new listing
  #   DELETE /listings/:id - delete a listing by id
  resources :listings, only: [:create, :destroy]

  # Creates routes:
  #   POST /rentals/ - create a new rental
  #   GET /rentals/new - show the rental creation form
  resources :rentals, only: [:create, :new]

end
