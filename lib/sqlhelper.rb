module SQLHelper

  def self.execute_sql query
    ActiveRecord::Base.connection.execute query 
  end

  def self.adapter_name
     ActiveRecord::Base.connection.adapter_name
  end


  def self.adapter_is_mysql?
    adapter_name == "Mysql2" ? true : false
  end

  def self.adapter_is_postgresql?
    adapter_name == "PostgreSQL" ? true : false
  end


  def self.database_name
    Rails.configuration.database_configuration[Rails.env]["database"]
  end

  def self.table_names
    if adapter_is_postgresql?
      (execute_sql "SELECT tablename from pg_tables where tableowner = 'rails' AND tablename <> 'schema_migrations' ORDER BY tablename").values.flatten
    elsif adapter_is_mysql?
      (execute_sql %Q@ SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE table_type = "BASE TABLE" AND TABLE_SCHEMA = "#{database_name}" @).to_a.flatten
    end
  end

end