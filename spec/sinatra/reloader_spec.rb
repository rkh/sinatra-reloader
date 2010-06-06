require File.expand_path("../../spec_helper", __FILE__)

describe Sinatra::Reloader do
  it_should_behave_like 'sinatra'

  def app_file(file, content)
    file = File.expand_path(file, @temp_dir)
    old_mtime = File.exist?(file) ? File.mtime(file) : Time.at(0)
    new_mtime = old_mtime
    # this is eventually faster than a hard coded sleep 1, also it adjusts to the systems
    # mtime granularity
    until new_mtime > old_mtime
      File.open(file, "w") do |f|
        f << "class ::ExampleApp < Sinatra::Base; #{content}; end\n"
        yield f if block_given?
      end
      File.utime File.atime(file), old_mtime + 10, file unless ENV['MTIME']
      new_mtime = File.mtime file
      # ok, let's not generate too much io
      sleep 0.1 if new_mtime == old_mtime
    end
    require file
    file
  end

  def app
    ::ExampleApp
  end

  before do
    @temp_dir ||= File.expand_path "../../temp", __FILE__
    rm_rf @temp_dir
    mkdir_p @temp_dir
    $LOADED_FEATURES.reject! { |f| f =~ /^#{@temp_dir}/ }
    class ::ExampleApp < Sinatra::Base
      reset!
      register Sinatra::Reloader
    end
  end
  
  after :all do
    rm_rf @temp_dir
  end

  it "should reload files" do
    app_file("example_app.rb", "get('/foo') { 'foo' }")
    browse_route(:get, '/foo').body.should == 'foo'
    app_file("example_app.rb", "get('/foo') { 'bar' }")
    browse_route(:get, '/foo').body.should == 'bar'
  end

  it "should not affact other routes" do
    app_file("example_app.rb", "get('/foo') { 'foo' }")
    app_file("example_app2.rb", "get('/bar') { 'bar' }")
    browse_route(:get, '/bar').body.should == 'bar'
    app_file("example_app.rb", "get('/foo') { 'bar' }")
    browse_route(:get, '/bar').body.should == 'bar'
  end

  it "should respect dont_reload" do
    file = app_file("example_app3.rb", "get('/baz') { 'foo' }")
    app.dont_reload file
    app_file("example_app3.rb", "get('/baz') { 'bar' }")
    browse_route(:get, '/baz').body.should == 'foo'
  end

  it "reloads inline templates" do
    file = app_file("example_app4.rb", "get('/foo') { haml :foo }") { |f| f.puts "__END__", "@@foo", "foo" }
    app.set :inline_templates, file
    browse_route(:get, '/foo').body.strip.should == "foo"
    app_file("example_app4.rb", "get('/foo') { haml :foo }") { |f| f.puts "__END__", "@@foo", "bar" }
    browse_route(:get, '/foo').body.strip.should == "bar"
  end

  it "should not readd middleware" do
    3.times do
      app_file "example_app5.rb", <<-RUBY
        use Rack::Config do |env|
          env['some.counter'] ||= 0
          env['some.counter'] += 1
          $counter = env['some.counter']
        end
      RUBY
      browse_route :get, '/foo'
    end
    $counter.should == 1
  end

end
