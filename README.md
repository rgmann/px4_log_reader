[![Build Status](https://travis-ci.org/rgmann/px4_log_reader.svg?branch=master)](https://travis-ci.org/rgmann/px4_log_reader)

## Welcome to Px4LogReader ##

Px4LogReader is a Ruby gem for parsing PX4 &copy; self-describing log files.


## Install the gem ##

Install it with [RubyGems](https://rubygems.org/)

    gem install px4_log_reader

or add this to your Gemfile if you use [Bundler](http://gembundler.com/):

    gem "px4_log_reader"


## Getting Started ##

### Example: Read PX4 log file ###

     require 'px4_log_reader'

     Px4LogReader.open( 'a_test_log.px4log' ) do |reader|
        reader.each_message( { with: [ 'ATT' ] } ) do |message,context|

           att = [ messaged.get('Roll'), message.get('Pitch'), message.get('Yaw') ]

           puts "ATT( @ #{context.find_by_name('GPS').get('GPSTime')} ): roll=#{att[0]}, pitch=#{att[1]}, yaw=#{att[2]}"

        end
     end


## License and copyright ##

Px4LogReader is released under the BSD License.

Copyright: &copy; 2016 by Robert Glissmann. All Rights Reserved.

"PX4" is a copyright of PX4 Autopilot (aka PX4 Dev Team). All Rights Reserved.

