namespace :attach do

  desc "Configure the variables that rails need in order to look up for the db
    configuration in a different folder"
  task :set_custom_db_config_paths do
    # This is the minimum required to tell rails to use a different location
    # for all the files related to the database.
    ENV['SCHEMA'] = 'db/schema_files.rb'
    #Rails.application.config.paths['db'] = ['db_attach']
    Rails.application.config.paths['db/migrate'] = ['db/migrate_files']
    Rails.application.config.paths['db/seeds'] = ['db/seeds_files.rb']
    Rails.application.config.paths['config/database'] = ['config/database_files.yml']
  end

  namespace :db do
    task :drop => :set_custom_db_config_paths do
      Rake::Task["db:drop"].invoke
    end

    task :create => :set_custom_db_config_paths do
      Rake::Task["db:create"].invoke
    end

    task :migrate => :set_custom_db_config_paths do
      Rake::Task["db:migrate"].invoke
    end

    task :rollback => :set_custom_db_config_paths do
      Rake::Task["db:rollback"].invoke
    end

    task :seed => :set_custom_db_config_paths do
      Rake::Task["db:seed"].invoke
    end

    task :version => :set_custom_db_config_paths do
      Rake::Task["db:version"].invoke
    end
  end
end

