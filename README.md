Sinatra::Reloader
=================

Advanced code reloader for [Sinatra](http://sinatrarb.com). Reloads only files that have
changed and automatically detects orphaned routes that have to be removed. Most other
implementations delete all routes and reload all code if one file changed, which takes way
more time than reloading only one file, especially in larger projects. Files defining
routes will be added to the reload list per default. Avoid reloading with dont_reload. Add
other files to the reload list with also_reload.

BigBand
-------

Sinatra::Reloader is part of the [BigBand](http://github.com/rkh/big_band) stack.
Check it out if you are looking for other fancy Sinatra extensions.

BigBand will setup the reloader automatically, but only in development mode.

Installation
------------

    gem install sinatra-reloader

Usage
-----

Simple example:

    require "sinatra"
    require "sinatra/reloader" if development?

More complex:

    require "sinatra/base"
    require "sinatra/reloader"
    
    class Foo < Sinatra::Base
      configure(:development) do
        register Sinatra::Reloader
        also_reload "app/models/*.rb"
        dont_reload "lib/**/*.rb"
      end
    end
