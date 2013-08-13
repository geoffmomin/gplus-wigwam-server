# WigwamNow - Web Server

## Description
WigwamNow is a Ruby on Rails application that demonstrates how to manage Google+ and Facebook integration in the same web application and showcases many of the features of each platform.

## Context
The WigwamNow project is a companion to the article
[Adding Google+ to your Facebook Integration](https://developers.google.com/+/web/facebook) on the Google+ Developers Site.  Please read the article for information on how to integrate Google+ Sign In and other features of the Google+ platform into your existing Facebook application.

## Requirements
1. Ruby 1.9.3
1. PostgreSQL
1. Rubygems
1. nodejs

## Setup

### Facebook Develoeprs Dashboard
1. Follow Facebook's [getting started on web](http://developers.facebook.com/docs/facebook-login/getting-started-web/) to create a new Facebook application.
2. On the Facebook developers [dashboard](https://developers.facebook.com/apps) create a new app, and record your App ID and App Secret.
3. Click 'Edit App' and put `localhost` in the 'App Domains' field and `http://localhost` in the 'Site URL' field.  Choose a namespace for your application.
4. Click 'Open Graph' and then 'Types'.  Create a new object type called `Wigwam` and make it inherit from `Place`.
5. Under 'Open Graph > Types' add the Action Type `Share` and add a `wigwam` property with type `Wigwam`.  Add the action types `List` and `Rent` and for both of them add a `wigwam` property of type `Wigwam` as well as `start_date` and `end_date` properties of type `DateTime`.

### Google APIs Console
1. Follow the first step of the [Google+ Ruby Quickstart](https://developers.google.com/+/quickstart/ruby#step_1_enable_the_google_api) to create a Google APIs Console project with the Google+ API enabled.  Make sure to add `http://localhost:3000` to your JavaScript origins and to record your Client ID and Client Secret.

### Configure Postgres
1. Download and install [PostgreSQL](http://www.postgresql.org/) on your development machine.
2. Create the development database with the command `createdb wigwam_development`.  If this is your first time using Postgres you may need to first [create a user](http://www.postgresql.org/docs/9.1/static/app-createuser.html) with the ability to create databases.
3. Record the username and password that you choose for the database.

### Set up Local Environment
1. Clone this repository using `git clone https://github.com/googleplus/gplus-wigwam-server`
1. Open a console session in the `gplus-wigwam-server` directory.
1. Configure the following environment variables:
<pre>
    `DB_USER=YOUR_POSTGRES_USERNAME`
    `DB_PASS=YOUR_POSTGRES_PASSWORD`
    `GPLUS_APP_ID=YOUR_GOOGLE_CLIENT_ID`
    `GPLUS_APP_SECRET=YOUR_GOOGLE_CLIENT_SECRET`
    `FB_APP_ID=YOUR_FACEBOOK_APP_ID`
    `FB_APP_SECRET=YOUR_FACEBOOK_APP_SECRET`
    `FB_NS=YOUR_FACEBOOK_APP_NAMESPACE`
</pre>
4. Run `gem install bundler` to install the Bundler gem, then run `bundle install` to install all of the gems in the server's `Gemfile`.
5. Run `rake db:migrate` to create the WigwamNow database.
6. Run `foreman start -p 3000` to run the server locally on port 3000 (`http://localhost:3000`).

### Launch
Some features will not work when running on `localhost`, such as posting [app activities](https://developers.google.com/+/web/app-activities/) or [interactive posts](https://developers.google.com/+/web/share/interactive) to Google+, or posting Open Graph actions to Facebook.  Use a deployment or tunneling solution to give your application an external-facing URL for full functionality.  When you deploy, make sure to replace `localhost:3000` on both the Google APIs Console and the Facebook Developers dashboard with your new URL.
