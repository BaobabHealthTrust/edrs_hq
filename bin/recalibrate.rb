#Load metadata
=begin
puts "########### LOADING METADATA PLEASE WAIT ITS GOING TO TAKE A MOMENT ###########"
`cd #{Rails.root} && bundle exec rails r bin/scripts/load_metadata_to_sql.rb`
puts "########### DONE LOADING METADATA ###########"
puts "########################################################################################"
puts "########### LOADING DATA PLEASE WAIT ITS GOING TO TAKE A MOMENT ######################"
#Save data to mysql
`cd #{Rails.root} && bundle exec rails r bin/scripts/save_mysql.rb`
puts "########################################################################################"
puts "################################# DONE LOADING DATA #################################"
puts "########################################################################################"
puts "################################# ADDING ENTRIES TO CRONTAB #################################"
puts `cd #{Rails.root} && bundle exec rails r bin/scripts/add_to_crontab.rb`
puts "################################# DONE RECALIBRATION #################################"
=end
alter_table_couchdb_sequence_and_audit_trail = "ALTER TABLE couchdb_sequence MODIFY COLUMN seq TEXT;
												ALTER TABLE audit_trail MODIFY COLUMN change_log TEXT;"
SimpleSQL.query_exec(alter_table_couchdb_sequence_and_audit_trail); 
