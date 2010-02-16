require "sinatra/rspec"
require "sinatra/reloader"
require "fileutils"
require "monkey"
Sinatra::Base.set :environment, :test
include FileUtils
