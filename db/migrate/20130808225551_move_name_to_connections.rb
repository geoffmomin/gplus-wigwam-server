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

class MoveNameToConnections < ActiveRecord::Migration

  # Move the :name attribute from the Users table to the Connections table.
  def up
    # Add the column to connections
    add_column :connections, :name, :string

    # Move the information from users
    User.all.each do |user|
      user.connections.each do |conn|
        conn.name = user.name
        conn.save!
      end
    end

    # Remove the column from users
    remove_column :users, :name
  end

  # Move the :name attribute from the Connections table to the Users table
  def down
    # Add the column to users
    add_column :users, :name, :string

    # Move the information from connections
    User.all.each do |user|
      conn = user.active_connection
      user.name = conn.name
      user.save!
    end

    # Remove the column from connections
    remove_column :connections, :name
  end
end
