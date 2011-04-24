Appraiser = a simple rubygems subcommand for Gemfile
====================================================

`appraiser` displays gem information from `./Gemfile`.

Like this:

![Screenshot](http://farm6.static.flickr.com/5263/5650073256_6ed10dc831_o.png)


Install
-------

appraiser installed as a rubygems subcommand.

    $ gem install appraiser
    $ gem help commands | grep appraiser
        appraiser         Display gem information in ./Gemfile


Usage
-----

Normally displays runtime dependencies.

    $ cd /path/to/project_with_Gemfile/
    $ gem appraiser

or, displays other dependencies with `-g GROUP`.

    $ gem appraiser -g development


Contributing
------------

Once you've made your great commits: Fork, fix, then send me a pull request.


Copyright
---------

Copyright (c) 2011 Junya Ogura. See LICENSE.txt for further details.
