CONFIG = YAML.load_file(Rails.root.join('config', 'couchdb.yml'))[Rails.env]
#SETTINGS = YAML.load_file(Rails.root.join('config', 'settings.yml'))
#BACKUP = YAML.load_file(Rails.root.join('config', 'backup.yml'))
MYSQL = YAML.load_file(File.join(Rails.root, "config", "mysql_connection.yml"))['connection']
def start
	query ="mysql -u #{MYSQL['username']} -p#{MYSQL['password']} -e \"CREATE DATABASE IF NOT EXISTS #{MYSQL['database']};\"" 
	`#{query}`
end
start
