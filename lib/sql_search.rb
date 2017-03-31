class SQLSearch

  CONFIGS = YAML.load_file("#{Rails.root}/config/mysql_connection.yml")['connection']

  def self.query(options, selected, accept_blanks=false)
    join_ext = ""
    where_ext = ""

    options.keys.each do |group|
      next if selected[group].blank? && selected[group] != 'On'
      fields = options[group]
      fields.each do |field|
        next if !accept_blanks && selected[field].blank?
        where_ext += (where_ext.length > 0 ? " AND " : "")  + [field, " '#{selected[field]}' "].join(" = ")
      end
    end

    query = "SELECT person_id FROM people #{join_ext} WHERE #{where_ext}"
    self.exec(query)
  end

  def self.exec(query)
    ids = (((`mysql -u #{CONFIGS['username']} -p#{CONFIGS['password']} #{CONFIGS['database']} -e "#{query}"`).split(/\n/) rescue []) - ['person_id']) rescue []
    people = []
    ids.each do |id|
      people << Person.find(id)
    end

    people
  end

end
