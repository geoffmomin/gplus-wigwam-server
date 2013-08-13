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
 * Object for namespacing purposes
 */
var wigwam = {

  /**
   * Displays a flash-style message at the top of the page.  This is for when the
   * rails flash[:type] = message behavior is desired but can't be set
   * server-side.  The message appears in a box with a close-button.  Calling
   * multiple times will caused stacked messages, rather than replacing the
   * original message.
   *
   * @param {String} type The type of flash message. Can be error, success, info,
   * or notice.
   * @param {String} message The message to display in the flash box.
   */
  jsFlash: function(type, message) {
     $('#flash-container').prepend(
        $('<div id="flash"></div>')
          .addClass('alert alert-' + type)
            .append($('<span>' + message + '</span>'))
            .append(
              $('<button type="button"></button>')
                .addClass('close')
                .attr('data-dismiss', 'alert')
                .text('×')
            )
      );
  }

};
