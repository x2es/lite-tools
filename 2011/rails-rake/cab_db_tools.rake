namespace :cab do
  namespace :db do
    desc 'Creates ROLE/USER and DB from database.yml using super-user (opposite to db:create).'
    task :create do
      require 'highline/import'

      puts ""
      dummy = (Rails.env == 'production' && ENV['ACT'] != 'yes') ? true : false
      say("<%= color('DUMMY', :bold, :yellow) %> job in production until <%= color('ACT=yes', :bold) %>") if dummy

      db_config = Rails.application.config.database_configuration[Rails.env]
      db_config.symbolize_keys!

      begin
        # service_adapter
        sad = setup_service_adapter db_config
      rescue ExAdapterNotSupported => e
        say("<%= color('ERROR', :red, :bold) %>: #{e.message}")
        next
      end

      say("Trying to create <%= color('#{sad.adapter}', :bold) %> db: <%= color('#{sad.database}', :bold)%> with owner <%= color('#{sad.username}', :bold)%>")
      puts ''

      say('Please input db-master auth data:')
      # no good solution - supersuser_config will request user's input
      su_config = sad.superuser_config
      ActiveRecord::Base.establish_connection(su_config)

      jobs = []

      print "\nCheck role/user '#{sad.username}'... "
      if sad.role_exists?
        say("<%= color('YES', :green, :bold) %>")
        say("Check password for user '#{sad.username}'... <%= color('TODO', :red, :bold)%>")
      else
        say("<%= color('NO', :yellow, :bold) %> => <%= color('Will be created', :green, :bold) %>")
        jobs << sad.create_user_job
      end

      print "Check database '#{sad.database}'... "
      if sad.database_exists?
        say("<%= color('YES', :green, :bold) %>")
        say "Check database '#{sad.database}' owner... <%= color('TODO', :red, :bold)%>\n"
        say "Database <%= color('#{sad.database}', :bold)%> already exists. <%= color('Aboting!', :red, :bold)%>"
        next
      else
        say("<%= color('NO', :yellow, :bold) %> => <%= color('Will be created', :green, :bold) %>")
        jobs << sad.create_db_job
      end

      puts "\n==============================\n"
      print "Performing jobs"
      dummy ? say(" <%= color('[DUMMY]', :yellow, :bold) %>:") : puts(':')
      say("(this will be performed on <%= color('#{sad.adapter}', :bold) %> db with <%= color('#{su_config[:username]}', :bold) %> rights)")
      puts "==============================\n"
      jobs.each do |job|
        puts " > #{sad.filter_for_print(job)};"
      end

      puts "\n"

      if agree('Perform? (y/n) ')
        sad.check_connection!
        jobs.each do |job|
          print "#{sad.filter_for_print(job)}; ... "
          unless dummy
            ActiveRecord::Base.connection.execute job
          else
            say("<%= color('dummy', :yellow)%> ")
          end
          say("<%= color('OK', :green, :bold)%>")
        end
        puts ''
        say("<%= color('Done.', :green, :bold)%>")
      else
        puts ''
        say("<%= color('Canceled.', :red, :bold)%>")
      end

      if dummy
        puts ''
        say('Use for taking affect:')
        say('  $ ACT=yes [RAILS_ENV=production] rake cab:db:create')
      end
    end
  end
end

# This method chooses service adapter for performing jobs
def setup_service_adapter dbconfig
  req_adapter = dbconfig[:adapter]
  req_adapter = req_adapter.is_a?(Symbol) ? req_adapter : req_adapter.to_sym

  # HOWTO: add your adapter here
  supported_adapters = { :postgresql => PostgresServiceAdapter }  # only yet

  raise ExAdapterNotSupported, "Adapter '#{req_adapter}' not supported!" unless supported_adapters.keys.include? req_adapter
  supported_adapters[req_adapter].new dbconfig
end

class ExAdapterNotSupported < Exception; end
class ExWrongConfig < Exception; end

class PostgresServiceAdapter

  DBCONFIG_FIELDS = [:database, :username, :password]
  REQUIRED_FIELDS = [:database, :username, :password]
  DEFAULT_DBMASTER = 'postgres'

  attr_reader :adapter
  DBCONFIG_FIELDS.each do |field|
    attr_reader field
  end

  def initialize dbconfig
    raise ExWrongConfig, "Wrong dbconfig[:adapter] for PostgresServiceAdapter (#{dbconfig[:adapter]})" unless dbconfig[:adapter].to_s == 'postgresql'
    @adapter = :postgresql

    REQUIRED_FIELDS.each do |field|
      raise ExWrongConfig, "Field '#{field}' required in database config." unless dbconfig[field]
    end

    DBCONFIG_FIELDS.each do |field|
      instance_variable_set "@#{field.to_s}", dbconfig[field]
    end
  end

  def superuser_config
    {
      :database => 'postgres',
      :username => ask('db-master username: ') { |q| q.default = DEFAULT_DBMASTER },
      :password => ask('db-master password: ') { |q| q.echo = '.' }
    }.merge(:adapter => @adapter.to_s)
  end

  def role_exists? 
    check_connection!
    ActiveRecord::Base.connection.execute("SELECT rolname FROM pg_roles WHERE rolname='#{@username}'").count == 1
  end

  def database_exists?
    check_connection!
    ActiveRecord::Base.connection.execute("SELECT datname FROM pg_database WHERE datname='#{@database}'").count == 1
  end

  def create_user_job
    check_connection!
    "CREATE ROLE #{@username} WITH LOGIN PASSWORD '#{@password}'"
  end

  def create_db_job
    check_connection!
    "CREATE DATABASE #{@database} WITH OWNER #{@username} ENCODING 'utf8'" #LC_COLLATE TODO
  end

  def filter_for_print job
    check_connection!
    job.gsub(/PASSWORD '(.+)'/, 'PASSWORD \'********\'')
  end

  # Checks connection type before command execution
  def check_connection!
    unless ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
    end
  end

end

# Example for Mysql and other service adapters
# class MysqlServiceAdapter
# 
#   DBCONFIG_FIELDS = [:database, :username, :password]
#   REQUIRED_FIELDS = [:database, :username, :password]
#   DEFAULT_DBMASTER = TODO: mysql
# 
#   attr_reader :adapter
#   DBCONFIG_FIELDS.each do |field|
#     attr_reader field
#   end
# 
#   def initialize dbconfig
#     raise ExWrongConfig, "Wrong dbconfig[:adapter] for PostgresServiceAdapter (#{dbconfig[:adapter]})" unless dbconfig[:adapter].to_s == # TODO: mysql
#     @adapter = # TODO: mysql
# 
#     REQUIRED_FIELDS.each do |field|
#       raise ExWrongConfig, "Field '#{field}' required in database config." unless dbconfig[field]
#     end
# 
#     DBCONFIG_FIELDS.each do |field|
#       instance_variable_set "@#{field.to_s}", dbconfig[field]
#     end
#   end
# 
#   def superuser_config
#     {
#       :database => # TODO: mysql
#       :username => ask('db-master username: ') { |q| q.default = DEFAULT_DBMASTER },
#       :password => ask('db-master password: ') { |q| q.echo = '.' }
#     }.merge(:adapter => @adapter.to_s)
#   end
# 
#   def role_exists? 
#     check_connection!
#     # check role presence in mysql
#   end
# 
#   def database_exists?
#     check_connection!
#     # check database presence in mysql
#   end
# 
#   def create_user_job
#     check_connection!
#     # create job for db-user creating
#   end
# 
#   def create_db_job
#     check_connection!
#     # job for creating database (don't forget about encodings)
#   end
# 
#   def filter_for_print job
#     # filter private data like passwords from job, for console output
#   end
# 
#   # Checks connection type before command execution
#   def check_connection!
#     unless ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters:: # TODO: mysql
#       raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
#     end
#   end
# 
# end

