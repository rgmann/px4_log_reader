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

        # Loop over all 'ATT' messages.
        reader.each_message( { with: [ 'ATT' ] } ) do |message|

           # Retrieve the most recent 'GPS' message parsed from the log.
           gps = reader.context.find_by_name('GPS')

           params = []
           params << reader.progress.file_offset
           params << reader.progress.file_size
           params << reader.progress.percentage
           params << gps.get('GPSTime')
           params << messaged.get('Roll')
           params << messaged.get('Pitch')
           params << messaged.get('Yaw')

           puts "%d/%d (%f%%): ATT @ %d - roll=%0.4f, pitch=%0.4f, yaw=%0.4f" % params

        end
     end


## License and copyright ##

Px4LogReader is released under the BSD License.

Copyright: &copy; 2016 by Robert Glissmann. All Rights Reserved.

"PX4" is a copyright of PX4 Autopilot (aka PX4 Dev Team). All Rights Reserved.

