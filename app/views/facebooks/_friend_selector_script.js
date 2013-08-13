<%#
<!--

/*
 *
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

-->
%>

var friendsCount = 0;

/**
* General function to load autocomplete data over AJAX
* and format it for jQuery Autocomplete Plugin (jqac)
*
* @param {String} path The path to the JSON endpoint that will
* return the autucomplete data.
* @param {Object} params An object containing the parameters to be submitted
* with the request in the format { key1: value1, key2: value2 ... }.
* @param {Function} cont A function object from the JQAC library, cont is called
* on the results of the JSON request and causes the autocomplete suggestion
* list to be populated.
*/
function loadAutocompleteData(path, params, cont) {
  $.getJSON(path, params, function(json) {
    var res = [];
    for (var i = 0; i < json.length; i++) {
      res.push({
        id: json[i].id,
        value: json[i].name
      });
    }
    cont(res);
  });
}

/**
* Asynchronous function to load friends data for autocomplete
*
* @param {String} key The search query entered in the text field.
* @param {Function} cont  A function object from the JQAC library,
* cont is called on the results of the JSON request and causes the
* autocomplete suggestion list to be populated.
*/
function loadFriends(key, cont) {
  var path = '/facebooks/friends';
  var params = {'q': key};
  loadAutocompleteData(path, params, cont);
}

/**
* Callback when a friend has been selected from the autocomplete
* list
*
* @param {Object} object The friend object that was selected from the
* autocomplete suggestions.  The object has properties id and value.
*/
function friendSelected(object) {
  $('#friends-selected').show();
  // Friend's name
  var friendSpan = $('<span />')
    .addClass('friend-name')
    .text(object.value)
    .attr('data-friend-id', object.id);
  // Button to remove this tag
  var closeButton = $('<a />')
    .attr('data-dismiss', object.id)
    .addClass('friend-dismiss')
    .text(' x ');
  friendSpan.append(closeButton);
  // Hidden input with this friend's id
  var hiddenInput = $('<input type="hidden" >')
    .attr('value', object.id)
    .attr('name', 'friends[' + friendsCount + ']');
  // Add the friend to the tag list
  $('#friends-selected').append(friendSpan);
  // Add the hidden input to the form
  $('#hidden-friend-inputs').append(hiddenInput);
  // Increment the number of friends selected
  friendsCount++;
  // Clear the input
  $('#friend-input').val('');
}

$(document).ready(function() {

  // Hide the friend input
  $('#friend-input').hide();
  $('#friends-selected').hide();

  // Set the autocomplete preferences for the friend input
  $('#friend-input').autocomplete({
    ajax_get: loadFriends,
    minchars: 1,
    callback: friendSelected
  });

  // Show the friend input when + Friends button is clicked
  $('#add-friend-btn').click(function() {
      $('#friend-input').show();
  });

  // Remove friend tag when 'x' is clicked
  $(document).on('click', '.friend-dismiss', function() {
    var toRemove = $(this).attr('data-dismiss');
    $('[data-friend-id=' + toRemove + ']').remove();
    // Remove the hidden input
    $('[value=' + toRemove + ']').remove();
    // Decrement the number of friends selected
    friendsCount--;
    // Hide the Tagged field if no friends are selected
    if (friendsCount === 0) {
      $('#friends-selected').hide();
    }
  });

});
