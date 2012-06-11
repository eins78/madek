require 'digest'
require 'action_controller'

namespace :madek do
  task :create_migrated_persona_dump do

    def needs_migration?(file_path)
      if File.exists?(file_path)
        versions_string = `grep -i "insert into.*schema_migrations.*" #{file_path}`
        latest_migration = versions_string.split(",").last.gsub(/(\(|\)|\'|;)/, "").to_i # ('20120423094303'); -> 20120423094303

        latest_available_migration = `ls -1 #{Rails.root + 'db/migrate'}`.split("\n").last.split("_").first.to_i
        if latest_available_migration == 0
          raise "No migrations available, please verify that db/migrations contains some migrations"
        else
          !(latest_migration == latest_available_migration)
        end
      else
        raise "File #{file_path} does not exist. Cannot determine if it needs migration."        
      end
    end

    # Load the latest dump from personas.madek.zhdk.ch, migrate it to the latest version
    # and then use that migrated dump in further tests (to prevent having to migrate multiple times)
    config = Rails.configuration.database_configuration[Rails.env]
    adapter      = config["adapter"]
    sql_host     = config["host"]
    sql_database = config["database"]
    sql_username = config["username"]
    sql_password = config["password"]

    if ["mysql", "mysql2"].include?(adapter)
      unmigrated_file = Rails.root + 'db/empty_medienarchiv_instance_with_personas.mysql.sql'
      migrated_file = Rails.root + 'db/empty_medienarchiv_instance_with_personas.mysql.migrated.sql'
      remove_command = "rm -f #{migrated_file}"
      drop_command = "mysql -u #{sql_username} --password=#{sql_password} -e 'drop database if exists #{sql_database}'"
      load_premigration_command = "mysql -u #{sql_username} --password=#{sql_password} #{sql_database} < #{unmigrated_file}"
      create_command = "mysql -u #{sql_username} --password=#{sql_password} -e 'create database #{sql_database}'"
      dump_postmigration_command = "mysqldump -u #{sql_username} --password=#{sql_password} #{sql_database} > #{migrated_file}"
    elsif adapter == "postgresql"
      auth_part = " -U #{sql_username} -w "
      encoding_part = " -E utf-8 "
      unmigrated_file = Rails.root.join 'db','empty_medienarchiv_instance_with_personas.pgbin'
      migrated_file = Rails.root.join 'db','empty_medienarchiv_instance_with_personas.pgbin'
      remove_command = "rm -f #{migrated_file}"
      drop_command =  "dropdb #{auth_part} #{sql_database} " 
      load_premigration_command = "pg_restore #{auth_part} -j 2 -d #{sql_database} #{unmigrated_file}"
      create_command = "createdb -w #{auth_part} #{sql_database}"
      dump_postmigration_command = "pg_dump #{auth_part} #{encoding_part} -F c -f #{migrated_file} "
    else
      raise "Cannot handle database adapter #{adapter}, sorry! Exiting."
    end

    # The migrated file is older than the unmigrated one -- we need to migrate
    if !File.exists?(migrated_file) or (File.mtime(unmigrated_file) > File.mtime(migrated_file)) or needs_migration?(unmigrated_file)
      system remove_command
      system drop_command
      system create_command
      system load_premigration_command
      puts "Trying to migrate the persona database"
      # TODO why this called indirectly? 
      system "bundle exec rake db:migrate"
      system dump_postmigration_command
    else
      if needs_migration?(unmigrated_file) == false
        puts "The migrated file has no newer migrations than the unmigrated file."
      end
      puts "No need to create a new migrated persona SQL file -- the unmigrated file #{unmigrated_file} is older than an existing migrated file #{migrated_file}"
    end
  end

  desc "Set up the environment for testing, then run all tests in one block"
  task :test => 'test:run_all'

  namespace :test do
    task :run_all do
      Rake::Task["madek:test:setup"].invoke
      Rake::Task["madek:test:rspec"].invoke
      Rake::Task["madek:test:cucumber:all"].invoke
    end

    task :run_separate do
      Rake::Task["madek:test:setup"].invoke
      Rake::Task["madek:test:rspec"].invoke
      Rake::Task["madek:test:cucumber:separate"].invoke
    end

    task :setup do
      # Rake seems to be very stubborn about where it takes
      # the RAILS_ENV from, so let's set a lot of options (?)
      Rails.env = 'test'
      task :environment
      Rake::Task["madek:create_migrated_persona_dump"].invoke
      # The rspec part of this whole story gets tested against an empty database, so nothing
      # to import from a file here. Instead, we reset based on our migrations.
      Rake::Task["madek:reset"].invoke
      File.delete("tmp/rerun.txt") if File.exists?("tmp/rerun.txt")
      File.delete("tmp/rerun_again.txt") if File.exists?("tmp/rerun_again.txt")
    end

    task :rspec do
      system "bundle exec rspec --format d --format html --out tmp/html/rspec.html spec"
      exit_code = $? >> 8 # magic brainfuck
      raise "Tests failed with: #{exit_code}" if exit_code != 0
    end

    namespace :cucumber do

      task :all do
        puts "Running all Cucumber tests in one block"
        system "bundle exec cucumber -p all"
        exit_code_first_run = $? >> 8 # magic brainfuck

        system "bundle exec cucumber -p rerun"
        exit_code_rerun = $? >> 8

        system "bundle exec cucumber -p rerun_again"
        exit_code_rerun_again = $? >> 8

        raise "Tests failed!" if exit_code_rerun_again != 0
      end

      task :seperate do
        puts "Running 'default' Cucumber profile"
        system "bundle exec cucumber -p default"

        puts "Running 'examples' Cucumber profile"
        system "bundle exec cucumber -p examples"

        puts "Running 'current_examples' Cucumber profile"
        system "bundle exec cucumber -p current_examples"

        system "bundle exec cucumber -p rerun"
        exit_code_rerun = $? >> 8

        if File.exists?("tmp/rerun_again.txt")
          system "bundle exec cucumber -p rerun_again"
          exit_code_rerun = $? >> 8
        end

        raise "Tests failed with: #{exit_code}" if exit_code_rerun != 0

      end
    end
    
  end

  desc "Back up images and database before doing anything silly"
  task :backup do
   unless Rails.env == "production"
     puts "HOLD IT! Are you sure you don't want to run this in production mode?"
     puts "Exiting."
     exit
   end

   puts "Copying attachment files."
   system "cp -apr /home/rails/madek/data_medienarchiv/attachments /home/rails/madek/data_medienarchiv/attachments-#{date_string}.bak"
   dump_database  
  end

  task :dump_database do
   unless Rails.env == "production"
     puts "HOLD IT! Are you sure you don't want to run this in production mode?"
     puts "Exiting."
     exit
   end

   date_string = DateTime.now.to_s.gsub(":","-")
   config = Rails.configuration.database_configuration[Rails.env]
   sql_host     = config["host"]
   sql_database = config["database"]
   sql_username = config["username"]
   sql_password = config["password"]
   dump_path =  "/home/rails/madek/shared/db_backups/#{sql_database}-#{date_string}.sql"

   puts "Dumping database"
   system "mysqldump -h #{sql_host} --user=#{sql_username} --password=#{sql_password} -r #{dump_path} #{sql_database}"
   puts "Compressing database with bzip2"
   system "bzip2 #{dump_path}"

  end

  namespace :db  do

    desc "Dump the PostgresDB"
    task :dump do
      date_string = DateTime.now.to_s.gsub(":","-")
      config = Rails.configuration.database_configuration[Rails.env]
      sql_host     = config["host"]
      sql_database = config["database"]
      sql_username = config["username"]
      sql_password = config["password"]
      date_string = DateTime.now.to_s.gsub(":","-")
      path = "tmp/pg-dump-#{Rails.env}-#{date_string}.bin" 
      puts "Dumping database to #{path}"
      cmd = "pg_dump -U #{sql_username} -h #{sql_host} -v -E utf-8 -F c -f #{path} #{sql_database}"
      puts "executing : #{cmd}"
      system cmd 
    end
    
    desc "Restore the PostgresDB" 
    task :restore do
      unless ENV['FILE'] 
         puts "can't find the FILE env variable, bailing out"
         exit
      end
      puts "dropping the db" 
      Rake::Task["db:drop"].invoke
      puts "creating the db"  
      Rake::Task["db:create"].invoke
      config = Rails.configuration.database_configuration[Rails.env]
      sql_host     = config["host"]
      sql_database = config["database"]
      sql_username = config["username"]
      sql_password = config["password"]
      file= ENV['FILE']
      cmd = "pg_restore -U #{sql_username} -d #{sql_database} #{file}"
      puts "executing: #{cmd}"
      system cmd
    end

  end

  desc "Fetch meta information from ldap and store it into db/ldap.json"
  task :fetch_ldap => :environment do
    DevelopmentHelpers.fetch_from_ldap
  end

# CONSTANTS used here are in environment.rb
  desc "Reset"
  task :reset => :environment  do |t,args|
    
      def rm_and_mkdir(path)
        puts "Removing #{path}"
        system "rm -rf '#{path}'"
        puts "Creating #{path}"
        system "mkdir -p #{path}"
      end
    
      # If any of the paths are either nil or set to ""...
      if [FILE_STORAGE_DIR, THUMBNAIL_STORAGE_DIR, TEMP_STORAGE_DIR, DOWNLOAD_STORAGE_DIR, ZIP_STORAGE_DIR].map{|path| path.to_s}.uniq == ""
        puts "DANGER, EXITING: The file storage paths are not defined! You need to define FILE_STORAGE_DIR, THUMBNAIL_STORAGE_DIR, TEMP_STORAGE_DIR, DOWNLOAD_STORAGE_DIR, ZIP_STORAGE_DIR in your config/application.rb"
        exit        
      else
        if (File.exist?(FILE_STORAGE_DIR) and File.exist?(THUMBNAIL_STORAGE_DIR))
          puts "Deleting #{FILE_STORAGE_DIR} and #{THUMBNAIL_STORAGE_DIR}"
          system "rm -rf '#{FILE_STORAGE_DIR}' '#{THUMBNAIL_STORAGE_DIR}'"         
        end
      
        [ '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f' ].each do |h|
          puts "Creating #{FILE_STORAGE_DIR}/#{h} and #{THUMBNAIL_STORAGE_DIR}/#{h}"
          system "mkdir -p #{FILE_STORAGE_DIR}/#{h} #{THUMBNAIL_STORAGE_DIR}/#{h}"
        end
      
        rm_and_mkdir(TEMP_STORAGE_DIR)
        rm_and_mkdir(DOWNLOAD_STORAGE_DIR)
        rm_and_mkdir(ZIP_STORAGE_DIR)
      end
      
     Rake::Task["log:clear"].invoke
     Rake::Task["db:migrate:reset"].invoke

      # workaround for realoading Models
     ActiveRecord::Base.subclasses.each { |a| a.reset_column_information }

     Rake::Task["db:seed"].invoke

     Rake::Task["madek:meta_data:import_presets"].invoke

  end
  
  namespace :meta_data do

    desc "Export MetaData Presets" 
    task :export_presets  => :environment do

      data_hash = DevelopmentHelpers::MetaDataPreset.create_hash

      date_string = DateTime.now.to_s.gsub(":","-")
      file_path = "tmp/#{date_string}_meta_data.yml"

      File.open(file_path, "w"){|f| f.write data_hash.to_yaml } 
      puts "the file has been saved to #{file_path}"
      puts "you might want to copy it to features/data/minimal_meta.yml"
    end

    desc "Import MetaData Presets" 
    task :import_presets => :environment do
      DevelopmentHelpers::MetaDataPreset.load_minimal_yaml
    end

  end


end # madek namespace
