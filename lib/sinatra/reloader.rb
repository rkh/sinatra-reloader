require "monkey"
require "sinatra/base"
require "sinatra/sugar"
require "sinatra/advanced_routes"

module Sinatra
  Base.ignore_caller

  module Reloader

    class FileWatcher < Array

      attr_reader :file, :mtime

      extend Enumerable
      @map ||= {}

      def self.register(route)
        new(route.file) << route if route.file?
      end

      def self.new(file)
        return nil unless File.exist? file
        @map[file.realpath] ||= super
      end

      class << self
        alias [] new
      end

      def self.each(&block)
        @map.values.each(&block) 
      end

      def initialize(file)
        @reload, @file = true, file
        @mtime = File.exist?(file) ? File.mtime(file) : Time.at(0)
        super()
      end

      def changed?
        !File.exist? file or @mtime != File.mtime(file)
      end

      def dont_reload!(dont = true)
        @reload = !dont
      end

      def reload?
        @reload and changed?
      end

      def reload
        reload! if reload?
      end

      def reload!
        each { |route| route.deactivate }
        $LOADED_FEATURES.delete file
        clear
        if File.exist? file
          @mtime = File.mtime(file)
          require file
        end
      end

    end

    module ClassMethods
      def dont_reload(*files)
        if [true, false].include? files.last then dont = files.pop
        else dont = true
        end
        files.flatten.each do |file|
          # Rubinius and JRuby ignore block passed to glob.
          Dir.glob(file).each { |f| FileWatcher[f].dont_reload! dont }
        end
      end

      def also_reload(*files)
        dont_reload(files, false)
      end
    end

    def self.registered(klass)
      klass.register AdvancedRoutes
      klass.extend ClassMethods
      klass.each_route { |route| advanced_route_added(route) }
      klass.before { Reloader.reload_routes }
    end

    def self.advanced_route_added(route)
      FileWatcher.register(route)
    end

    def self.thread_safe?
      Thread and Thread.list.size > 1 and Thread.respond_to? :exclusive
    end

    def self.reload_routes(thread_safe = true)
      return Thread.exclusive { reload_routes(false) } if thread_safe and thread_safe?
      FileWatcher.each { |file| file.reload }
    end

  end

  register Reloader

end