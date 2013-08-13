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

# Remove identity concepty from the User model and create a new Connections
# table.  First creates Connections table, then migrates all existing user data,
# then removes the columns from the User model.  Reverses each step when
# migrating down.
#
# Author:: samstern@google.com
class SeparateAuthFromUsers < ActiveRecord::Migration
  def up
    # Create Connections table
    create_table :connections do |t|
      t.integer   :user_id
      t.string    :provider
      t.string    :uid
      t.string    :oauth_token
      t.datetime  :oauth_expires_at

      t.timestamps
    end
    # Migrate all existing data to connections
    User.all.each do |user|
      conn = Connection.new(
        user_id: user.id,
        provider: user.provider,
        uid: user.uid,
        oauth_token: user.oauth_token,
        oauth_expires_at: user.oauth_expires_at
      )
      conn.save
    end
    # Remove columns from users table
    remove_column :users, :provider
    remove_column :users, :uid
    remove_column :users, :oauth_token
    remove_column :users, :oauth_expires_at
  end

  def down
    # Add columns to users table
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :oauth_token, :string
    add_column :users, :oauth_expires_at, :datetime
    # Migrate data back to users
    Connection.all.each do |conn|
      user = User.find(conn.user_id)
      user.provider = conn.provider
      user.uid = conn.uid
      user.oauth_token = conn.oauth_token
      user.oauth_expires_at = conn.oauth_expires_at
      user.save
    end
    # Drop connections table
    drop_table :connections
  end
end
