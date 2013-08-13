/*
 * Copyright 2013 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * This file contains the implementation of the authentication logic
 * managing Google+ and Facebook together.
 *
 * author: samstern@google.com (Sam Stern)
 */

/**
 * Track the authorization states of both Facebook and Google.
 */
var AuthStates = {
  google: null,
  facebook: null
};

/**
 * Listen for authorization events, respond by storing the data and calling
 * chooseAuthProvider().
 */
$(document).ready(function() {
  $(document).bind('auth-event', function(e, provider, data) {
    // Record the data in AuthStates.
    if(provider === "google") {
      AuthStates.google = data;
    } else if (provider === "facebook") {
      AuthStates.facebook = data;
    }
    // Choose the appropriate authorization provider.
    chooseAuthProvider();
  });
});


/**
 * Log in with Google+ or Facebook, depending on which is available.
 */
function chooseAuthProvider() {
  // Make sure we've heard from both of them
  if (AuthStates.google && AuthStates.facebook) {
    if (AuthStates.google['access_token']) {
      // Sign-In with Google+.
      GPLUS_API.personalize();
    } else if (AuthStates.facebook.authResponse) {
      // Login with Facebook.
      FB_API.personalize(AuthStates.facebook);
      FB_API.loadUserPicture();
    } else {
      // Show the Sign-In and Login buttons, because neither provider is
      // currently authorized.
      FB_API.showButton();
      GPLUS_API.showButton();
    }
  }
}
