Appraiser = a simple command line utility for gem paranoia
==========================================================

`appraiser` displays gem information from `./Gemfile`.

Like this:
![Screenshot](http://farm5.static.flickr.com/4104/5603713804_d24546947d_z.jpg)


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
