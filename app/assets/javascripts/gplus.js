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

/*
 * This file contains the implementation of the authentication logic for
 * Google+ and the DOM manipulations associated to changes in the Google+
 * session state.
 *
 * author: samstern@google.com (Sam Stern)
 */

var GPLUS_API = {

  authResult: null,

  /**
   * Record the result of an authorization attempt by storing the result
   * and firing an event.
   *
   * @param {Object} authResult the authorization result receieved.
   */
  recordAuthResult: function(authResult) {
    this.authResult = authResult;
    $(document).trigger('auth-event', ['google', authResult]);
  },

  /**
   * Display the Google+ Sign-In Button.
   */
  showButton: function() {
    $('#signinButton').css('display', 'inline');
  },

  /**
   * Hide the Google+ Sign-In Button.
   */
  hideButton: function() {
    $('#signinButton').css('display', 'none');
  },

  /**
   * Personalize the page with the user's Google+ profile information, such as
   * their name and public profile picture.
   */
  personalize: function() {
    this.hideButton();

    gapi.client.load('plus','v1',function() {
      var request = gapi.client.plus.people.get({
        'userId': 'me'
      });

      request.execute(function(userResult) {
        // Initiate the one-time-code flow on the server
        GPLUS_API.sendCodeToServer();

        // Display the user's info
        var profPic = $('<img class="user-picture" />')
          .attr('src', userResult.image.url);
        $('#user-info,#gplus-user-info').prepend(profPic);
      });
    });
  },

  /**
   * Revoke the user's access token and completely disconnect them from Google+.
   */
  disconnect: function() {
    // Construct the URL for the token revoke endpoint.
    var revokeUrl = 'https://accounts.google.com/o/oauth2/revoke?token=' +
        this.authResult.access_token;

    // Perform a synchronous GET request.
    $.ajax({
      type: 'GET',
      url: revokeUrl,
      async: false,
      contentType: 'application/json',
      dataType: 'jsonp',
      success: function(nullResponse) {
        // Redirect to the server-side logout page.
        window.location = '/auth/gplus/signout';
      },
      error: function(e) {
        console.log(e);
      }
    });
  },

  /**
   * Decode the user's email from the id_token in the authResult.
   *
   * @return {String} the user's email address.
   */
  getUserEmail: function() {
    var idToken = GPLUS_API.authResult.id_token;
    // Token comes with three sections, separated by periods
    var tokenSections = idToken.split('.');
    // Second section is the payload (first is header)
    var payload = tokenSections[1];
    // Decode from base64, and parse as JSON.
    var decoded = JSON.parse(atob(payload));
    return decoded.email;
  },

  /**
   * Send the `code` from the authResult to the server to initiation the one
   * time code flow.  When finished, display the user's name in the nav bar.
   */
  sendCodeToServer: function() {
    if (GPLUS_API.authResult['code']) {
      $.post(
        '/auth/gplus/hybrid.json',
        {
          code: GPLUS_API.authResult['code']
        },
        function(data) {
          GPLUS_API.hideButton();
          FB_API.hideButton();
          $('#user-name').text(data.name);
          $('#user-info').css('display', 'inline');
        });
    }
  }

};

/**
 * Register the click handler for the logout link.
 */
$(document).ready(function() {
  $('#logout-link').click(function() {
    GPLUS_API.disconnect();
  });
});

function signinCallback(authResult) {
  GPLUS_API.recordAuthResult(authResult);
}
