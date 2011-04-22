Appraiser = a simple command line utility for Gemfile
=====================================================

`appraiser` displays gem information from `./Gemfile`.

Like this:

![Screenshot](http://farm6.static.flickr.com/5026/5643970264_2b995ed4b1.jpg)


Install
-------

    $ gem install appraiser


Usage
-----

Appraiser normally displays runtime dependencies.

    $ cd /path/to/project_with_Gemfile/
    $ appraiser

or, displays other dependencies with `-g GROUP`.

    $ appraiser -g development


Contributing
------------

Once you've made your great commits: Fork, fix, then send me a pull request.


Copyright
---------

Copyright (c) 2011 Junya Ogura. See LICENSE.txt for further details.
