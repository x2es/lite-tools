namespace :cab do
  namespace :db do
    desc 'Creates ROLE/USER and DB from database.yml using super-user (opposite to db:create).'
    task :create do
      # TODO: usage guide
      require 'highline/import'

      supported_adapters = [:postgresql]  # only yet
      puts ""
      dummy = (Rails.env == 'production' && ENV['ACT'] != 'yes') ? true : false
      say("<%= color('DUMMY', :bold, :yellow) %> job in production until <%= color('ACT=yes', :bold) %>") if dummy

      db_config = Rails.application.config.database_configuration[Rails.env]
      db_config.symbolize_keys!

      unless supported_adapters.include? db_config[:adapter].to_sym
        say("<%= color('ERROR', :red, :bold) %>: Adapter '#{db_config[:adapter]}' not supported!")
        next
      end

      say("Trying to create <%= color('#{db_config[:adapter]}', :bold) %> db: <%= color('#{db_config[:database]}', :bold)%> with owner <%= color('#{db_config[:username]}', :bold)%>")
      puts ''
      say('Please input db-master auth data:')
      su_config = superuser_config(db_config[:adapter])
      ActiveRecord::Base.establish_connection(su_config)

      jobs = []

      print "\nCheck role/user '#{db_config[:username]}'... "
      if role_exists? db_config[:username]
        #puts "YES"
        say("<%= color('YES', :green, :bold) %>")
        say("Check password for user '#{db_config[:username]}'... <%= color('TODO', :red, :bold)%>")
      else
        say("<%= color('NO', :yellow, :bold) %> => <%= color('Will be created', :green, :bold) %>")
        jobs << create_user_job(db_config)
      end

      print "Check database '#{db_config[:database]}'... "
      if database_exists? db_config[:database]
        say("<%= color('YES', :green, :bold) %>")
        say "Check database '#{db_config[:database]}' owner... <%= color('TODO', :red, :bold)%>\n"
        say "Database <%= color('#{db_config[:database]}', :bold)%> already exists. <%= color('Aboting!', :red, :bold)%>"
        next
      else
        say("<%= color('NO', :yellow, :bold) %> => <%= color('Will be created', :green, :bold) %>")
        jobs << create_db_job(db_config)
      end

      puts "\n==============================\n"
      print "Performing jobs"
      dummy ? say(" <%= color('[DUMMY]', :yellow, :bold) %>:") : puts(':')
      say("(this will be performed on <%= color('#{db_config[:adapter]}', :bold) %> db with <%= color('#{su_config[:username]}', :bold) %> rights)")
      puts "==============================\n"
      jobs.each do |job|
        puts " > #{filter_for_print(job)};"
      end

      puts "\n"

      if agree('Perform? (y/n) ')
        jobs.each do |job|
          print "#{filter_for_print(job)}; ... "
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

def superuser_config adapter
  req_adapter = adapter.is_a?(Symbol) ? adapter : adapter.to_sym
  if req_adapter == :postgresql
    {
      :database => 'postgres',
      :username => ask('db-master username: ') { |q| q.default = 'postgres' },
      :password => ask('db-master password: ') { |q| q.echo = '.' }
    }.merge(:adapter => adapter.to_s)
  end
end

def role_exists? rolename
  if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    role_exists = false
    ActiveRecord::Base.connection.execute('SELECT rolname FROM pg_roles').each do |res|
      if res['rolname'] == rolename
        role_exists = true
        break
      end
    end
    role_exists
  else
    raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
  end
end

def database_exists? database
  if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    database_exists = false
    ActiveRecord::Base.connection.execute('SELECT datname FROM pg_database').each do |res|
      if res['datname'] == database
        database_exists = true
        break
      end
    end
    database_exists
  else
    raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
  end
end

def create_user_job config
  if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    "CREATE ROLE #{config[:username]} WITH LOGIN PASSWORD '#{config[:password]}'"
  else
    raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
  end
end

def create_db_job config
  if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    "CREATE DATABASE #{config[:database]} WITH OWNER #{config[:username]} ENCODING 'utf8'" #LC_COLLATE TODO
  else
    raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
  end
end

def filter_for_print job
  if ActiveRecord::Base.connection.is_a? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    job.gsub(/PASSWORD '(.+)'/, 'PASSWORD \'********\'')
  else
    raise "Not supported connection! Used '#{ActiveRecord::Base.connection.class}'."
  end
end
