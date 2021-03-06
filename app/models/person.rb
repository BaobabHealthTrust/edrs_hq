

class Person < CouchRest::Model::Base

  #use_database "death"

  before_save NameCodes.new("first_name")

  before_save NameCodes.new("last_name")

  before_save NameCodes.new("middle_name")

  before_save NameCodes.new("mother_first_name")

  before_save NameCodes.new("mother_last_name")

  before_save NameCodes.new("mother_middle_name")

  before_save NameCodes.new("father_first_name")

  before_save NameCodes.new("father_last_name")

  before_save NameCodes.new("father_middle_name")

  before_save NameCodes.new("informant_first_name")

  before_save NameCodes.new("informant_last_name")

  before_save NameCodes.new("informant_middle_name")

  #after_initialize :decrypt_data

  #before_save :encrypt_data

  before_save :set_facility_code,:set_district_code

  after_create :create_status #,:insert_update_into_mysql

  after_save :insert_update_into_mysql

  cattr_accessor :duplicate
  
  cattr_accessor :dispatch

  def decrypt_data
    encryptable = ["first_name","last_name",
                   "middle_name","last_name",
                   "mother_first_name","mother_last_name",
                   "mother_middle_name","mother_id_number",
                   "father_id_number","father_first_name",
                   "father_last_name","father_middle_name",
                   "father_id_number","informant_first_name","informant_last_name",
                   "informant_middle_name"]
    (self.attributes || []).each do |attribute|

      next unless encryptable.include? attribute[0] || (attribute[1].length > 20 && attribute[1].match(/\=+/))

      self.send("#{attribute[0]}=", (attribute[1].decrypt rescue attribute[1])) unless attribute[1].blank?
    end
  end
  
  def encrypt_data
    encryptable = ["first_name","last_name",
                   "middle_name","last_name",
                   "mother_first_name","mother_last_name",
                   "mother_middle_name","mother_id_number",
                   "father_id_number","father_first_name",
                   "father_last_name","father_middle_name",
                   "father_id_number","informant_first_name","informant_last_name",
                   "informant_middle_name"]
    (self.attributes || []).each do |attribute|

      next unless encryptable.include? attribute[0] || (attribute[1].length > 20 && attribute[1].match(/\=+/))

      self.send("#{attribute[0]}=", attribute[1].encrypt) unless attribute[1].blank?
    end
  end

  def create_status
    
    if self.duplicate.nil?
      PersonRecordStatus.create({
                                  :person_record_id => self.id.to_s,
                                  :status => "NEW",
                                  :district_code => CONFIG['district_code'],
                                  :created_by => User.current_user.id})
    else
      
      change_log = [{:duplicates => self.duplicate.to_s}]

      Audit.create({
                      :record_id  => self.id.to_s,
                      :audit_type => "POTENTIAL DUPLICATE",
                      :reason     => "Record is a potential",
                      :change_log => change_log
      })
      PersonRecordStatus.create({
                                  :person_record_id => self.id.to_s,
                                  :status => "DC POTENTIAL DUPLICATE",
                                  :district_code => CONFIG['district_code'],
                                  :created_by => User.current_user.id})

      self.duplicate = nil

    end
    
  end

  #Person methods
  def person_id=(value)
    self['_id']=value.to_s
  end

  def person_id
    self['_id']
  end


  def self.update_state(id, status, audit_status)

    person = Person.find(id)
    raise "Person with ID: #{id} not found".to_s if person.blank?

    status = status
    audit_status = audit_status
    audit_reason = "Admin request"

    user = User.find("admin")
    name = user.first_name + " " + user.last_name

    person.status = status
    person.status_changed_by = name
    person.save

    audit = Audit.new()
    audit["record_id"] = person.id
    audit["audit_type"] = audit_status
    audit["reason"] = audit_reason
    audit.save
  end

 def set_district_code
    unless self.district_code.present?
      self.district_code = CONFIG["district_code"]
    end      
  end

  def set_facility_code
    unless self.facility_code.present?
      self.facility_code = (CONFIG['facility_code'] rescue nil)
    end 
  end

  def status
    PersonRecordStatus.by_person_recent_status.key(self.id).last.status rescue nil
  end

  def change_status(nextstatus)
    status = PersonRecordStatus.by_person_recent_status.key(self.id.to_s).last
    status.update_attributes({:voided => true}) if status.present?
    PersonRecordStatus.create({
                        :person_record_id => self.id.to_s,
                        :status => nextstatus,
                        :district_code =>(self.district_code rescue CONFIG['district_code']),
                        :creator => User.current_user.id})
  end

  def self.create_person(parameters)
      params = parameters[:person]

      params[:acknowledgement_of_receipt_date] = Time.now

      if !params[:nationality].blank?

        params[:nationality_id] = Nationality.by_nationality.key(params[:nationality]).first.id

      end
      if !params[:place_of_death_district].blank?

            district = District.by_name.key(params[:place_of_death_district]).first

            params[:place_of_death_district_id] = district.id

            if !params[:hospital_of_death].blank? && params[:place_of_death].downcase.match("health facility")

                health_facility = HealthFacility.by_district_id_and_name.key([district.id, params[:hospital_of_death]]).first

                params[:hospital_of_death_id] = health_facility.id
            else

                if !params[:place_of_death_ta].blank? && params[:place_of_death_ta] != "Other"

                     place_ta = TraditionalAuthority.by_district_id_and_name.key([district.id,params[:place_of_death_ta]]).first

                     params[:place_of_death_ta_id] = place_ta.id

                     if !params[:place_of_death_village].blank? && params[:place_of_death_village] != "Other"
                        place_village = Village.by_ta_id_and_name.key([place_ta.id,params[:place_of_death_village]]).first
                        params[:place_of_death_village_id] = place_village.id
                       
                     end
                  
                end

            end

      end

      if !params[:current_country].blank?

          params[:current_country_id] = Country.by_name.key(params[:current_country]).first.id

      end

      if !params[:home_district].blank?
        
          home_district = District.by_name.key(params[:home_district]).first

          params[:home_district_id] = home_district.id

          if !params[:home_ta].blank? && params[:home_ta] != "Other"

               ta = TraditionalAuthority.by_district_id_and_name.key([home_district.id,params[:home_ta]]).first

               params[:home_ta_id] = ta.id

               if !params[:home_village].blank? && params[:home_village] != "Other"
                  village = Village.by_ta_id_and_name.key([ta.id,params[:home_village]]).first
                  params[:home_village_id] = village.id
                 
               end
            
          end
      end

    if !params[:home_country].blank?

          params[:home_country_id] = Country.by_name.key(params[:home_country]).first.id

      end

      if !params[:current_district].blank?
        
          current_district = District.by_name.key(params[:current_district]).first

          params[:current_district_id] = current_district.id

          if !params[:current_ta].blank? && params[:current_ta] != "Other"

               current_ta = TraditionalAuthority.by_district_id_and_name.key([current_district.id,params[:current_ta]]).first

               params[:current_ta_id] = current_ta.id

               if !params[:current_village].blank? && params[:current_village] != "Other"

                  current_village = Village.by_ta_id_and_name.key([current_ta.id,params[:current_village]]).first

                  params[:current_village_id] = current_village.id
                 
               end
            
          end
      end

      if !params[:informant_current_district].blank?
        
          informant_district = District.by_name.key(params[:informant_current_district]).first

          params[:informant_current_district_id] = informant_district.id

          if !params[:informant_current_ta].blank? && params[:informant_current_ta] != "Other"

               informant_ta = TraditionalAuthority.by_district_id_and_name.key([informant_district.id,params[:informant_current_ta]]).first

               params[:informant_current_ta_id] = informant_ta.id

               if !params[:informant_current_village].blank? && params[:informant_current_village] != "Other"

                  informant_village = Village.by_ta_id_and_name.key([informant_ta.id,params[:informant_current_village]]).first

                  params[:informant_current_village_id] = informant_village.id
               end
            
          end
      end

      if params[:potential_duplicate].present?
            Person.duplicate = params[:potential_duplicate]
      end
      
      Person.create(params)
    
  end

  def update_person(id,params)

      person = Person.find(id)

       if !params[:place_of_death_district].blank?

            district = District.by_name.key(params[:place_of_death_district]).first

            params[:place_of_death_district_id] = district.id

            if !params[:hospital_of_death].blank? && params[:place_of_death].downcase.match("health facility")

                health_facility = HealthFacility.by_district_id_and_name.key([district.id, params[:hospital_of_death]]).first

                params[:hospital_of_death_id] = health_facility.id
            else

                if !params[:place_of_death_ta].blank? && params[:place_of_death_ta] != "Other"

                     place_ta = TraditionalAuthority.by_district_id_and_name.key([district.id,params[:place_of_death_ta]]).first

                     params[:place_of_death_ta_id] = place_ta.id

                     if !params[:place_of_death_village].blank? && params[:place_of_death_village] != "Other"
                        place_village = Village.by_ta_id_and_name.key([place_ta.id,params[:place_of_death_village]]).first
                        params[:place_of_death_village_id] = place_village.id
                       
                     end
                  
                end

            end

      end

      if !params[:home_country].blank?

          params[:home_country_id] = Country.by_name.key(params[:home_country]).first.id

      end

      if !params[:home_district].blank?
        
          home_district = District.by_name.key(params[:home_district]).first

          params[:home_district_id] = home_district.id

          if !params[:home_ta].blank? && params[:home_ta] != "Other"

               ta = TraditionalAuthority.by_district_id_and_name.key([home_district.id,params[:home_ta]]).first

               params[:home_ta_id] = ta.id

               if !params[:home_village].blank? && params[:home_village] != "Other"
                  village = Village.by_ta_id_and_name.key([ta.id,params[:home_village]]).first
                  params[:home_village_id] = village.id
                 
               end
            
          end
      end

      if !params[:current_district].blank?
        
          current_district = District.by_name.key(params[:current_district]).first

          params[:current_district_id] = current_district.id

          if !params[:current_ta].blank? && params[:current_ta] != "Other"

               current_ta = TraditionalAuthority.by_district_id_and_name.key([current_district.id,params[:current_ta]]).first

               params[:current_ta_id] = current_ta.id

               if !params[:current_village].blank? && params[:place_of_death_ta] != "Other"

                  current_village = Village.by_ta_id_and_name.key([current_ta.id,params[:current_village]]).first

                  params[:current_village_id] = current_village.id
                 
               end
            
          end
      end

      if !params[:informant_current_district].blank? 
        
          informant_district = District.by_name.key(params[:informant_current_district]).first

          params[:informant_current_district_id] = informant_district.id

          if !params[:informant_current_ta].blank? && params[:informant_current_ta] != "Other"

               informant_ta = TraditionalAuthority.by_district_id_and_name.key([informant_district.id,params[:informant_current_ta]]).first

               params[:informant_current_ta_id] = informant_ta.id

               if !params[:informant_current_village].blank? && params[:informant_current_village] != "Other"

                  informant_village = Village.by_ta_id_and_name.key([informant_ta.id,params[:informant_current_village]]).first

                  params[:informant_village_id] = informant_village.id
               end
            
          end
      end

      person.update_attributes(params)

  end

  #Identifiers
  def den
    if PersonIdentifier.by_person_record_id_and_identifier_type.key([self.id, "DEATH ENTRY NUMBER"]).first.present?
      return PersonIdentifier.by_person_record_id_and_identifier_type.key([self.id, "DEATH ENTRY NUMBER"]).first.identifier rescue nil
    else
      return nil
    end
  end
  def national_id
    return PersonIdentifier.by_person_record_id_and_identifier_type.key([self.id,"National ID"]).first.identifier rescue nil
  end
  def barcode
    if Barcode.by_person_record_id.key(self.id).first.present?
      return Barcode.by_person_record_id.key(self.id).first.barcode rescue nil
    else 
      return nil
    end
      
  end

  def drn
    drn_sort_value = PersonIdentifier.by_person_record_id_and_identifier_type.key([self.id, "DEATH REGISTRATION NUMBER"]).first.drn_sort_value rescue nil
    if drn_sort_value.present?
      drn = "%010d" % drn_sort_value
      infix = ""
      if self.gender.match(/^F/i)
        infix = "1"
      elsif self.gender.match(/^M/i)
        infix = "2"
      end
      drn = "#{drn[0, 5]}#{infix}#{drn[5, 9]}"
      return drn
    else
      return nil
    end
   
    
  end

  def insert_update_into_mysql
    fields  = self.keys.sort
    sql_record = Record.where(person_id: self.id).first
    sql_record = Record.new if sql_record.blank?
    fields.each do |field|
      next if field == "type"
      next if field == "_rev"
      next if field == "source_id"
      if field =="_id"
          sql_record["person_id"] = self[field]
      else
          sql_record[field] = self[field]
      end

    end
    sql_record.save
  end

  def printable_place_of_death
    place_of_death = ""
    person = self
    case person.place_of_death
      when "Home"
          if person.place_of_death_village.present? && person.place_of_death_village.to_s.length > 0
              place_of_death = person.place_of_death_village
          end
          if person.place_of_death_ta.present? && person.place_of_death_ta.to_s.length > 0
              place_of_death = "#{place_of_death}, #{person.place_of_death_ta}"
          end
          if person.place_of_death_district.present? && person.place_of_death_district.to_s.length > 0
              place_of_death = "#{place_of_death}, #{person.place_of_death_district}"
          end
      when "Health Facility"
          place_of_death = "#{person.hospital_of_death}, #{person.place_of_death_district}"
      else  
          place_of_death = "#{person.other_place_of_death}, #{person.place_of_death_district}"
      end

      if person.place_of_death && person.place_of_death.strip.downcase.include?("facility")
                 place_of_death = "#{person.hospital_of_death}, #{person.place_of_death_district}"
      elsif person.place_of_death_foreign && person.place_of_death_foreign.strip.downcase.include?("facility")
             if person.place_of_death_foreign_hospital.present? && person.place_of_death_foreign_hospital.to_s.length > 0
                place_of_death  = person.place_of_death_foreign_hospital
             end
              
             if person.place_of_death_country.present? && person.place_of_death_country.to_s.length > 0
                if person.place_of_death_country == "Other"
                  place_of_death = "#{place_of_death}, #{person.other_place_of_death_country}"
                else
                  place_of_death = "#{place_of_death}, #{person.place_of_death_country}"
                end
                 
             end
      elsif person.place_of_death_foreign && person.place_of_death_foreign.strip =="Home"

              if person.place_of_death_foreign_village.present? && person.place_of_death_foreign_village.length > 0
                 place_of_death = person.place_of_death_foreign_village
              end

              if person.place_of_death_foreign_district.present? && person.place_of_death_foreign_district.to_s.length > 0
                 place_of_death = "#{place_of_death}, #{person.place_of_death_foreign_district}"
              end

              if person.place_of_death_foreign_state.present? && person.place_of_death_foreign_state.to_s.length > 0
                 place_of_death = "#{place_of_death}, #{person.place_of_death_foreign_state}"
              end

              if person.place_of_death_country.present? && person.place_of_death_country.to_s.length > 0
                if person.place_of_death_country == "Other"
                  place_of_death = "#{place_of_death}, #{person.other_place_of_death_country}"
                else
                  place_of_death = "#{place_of_death}, #{person.place_of_death_country}"
                end
                 
              end
        elsif person.place_of_death_foreign && person.place_of_death_foreign.strip =="Other"
               if person.other_place_of_death.present? && person.other_place_of_death.to_s.length > 0
                 place_of_death = person.other_place_of_death
              end

              if person.place_of_death_foreign_village.present? && person.place_of_death_foreign_village.length > 0
                 place_of_death = "#{place_of_death}, #{person.place_of_death_foreign_village}"
              end

              if person.place_of_death_foreign_district.present? && person.place_of_death_foreign_district.to_s.length > 0
                 place_of_death = "#{place_of_death}, #{person.place_of_death_foreign_district}"
              end

              if person.place_of_death_foreign_state.present? && person.place_of_death_foreign_state.to_s.length > 0
                 place_of_death = "#{place_of_death}, #{person.place_of_death_foreign_state}"
              end

              if person.place_of_death_country.present? && person.place_of_death_country.to_s.length > 0
                if person.place_of_death_country == "Other"
                  place_of_death = "#{place_of_death}, #{person.other_place_of_death_country}"
                else
                  place_of_death = "#{place_of_death}, #{person.place_of_death_country}"
                end
                 
              end

      elsif person.place_of_death  && person.place_of_death =="Other"
                if person.other_place_of_death.present?
                    place_of_death  = person.other_place_of_death;
                end
                if person.place_of_death_district.present?
                    place_of_death = "#{place_of_death}, #{person.place_of_death_district}"
                end
      elsif person.place_of_death  && person.place_of_death =="Home"
          if person.place_of_death_village.present? && person.place_of_death_village.to_s.length > 0
            if person.place_of_death_village == "Other"
               place_of_death = person.other_place_of_death_village
            else
               place_of_death = person.place_of_death_village
            end
             
          end
          if person.place_of_death_ta.present? && person.place_of_death_ta.to_s.length > 0
            if person.place_of_death_ta == "Other"
                place_of_death = "#{place_of_death}, #{person.other_place_of_death_ta}"
            else
                place_of_death = "#{place_of_death}, #{person.place_of_death_ta}"
            end
              
          end
          if person.place_of_death_district.present? && person.place_of_death_district.to_s.length > 0
              place_of_death = "#{place_of_death}, #{person.place_of_death_district}"
          end

    end
    return place_of_death 
  end

  def person_name
    str = "#{self.first_name}"
    if self.middle_name.present?
        str = "#{str} #{self.middle_name}"
    end
    str = "#{str} #{self.last_name}"
    return str.strip
  end

  def fathers_name
    str = ""
    if self.father_first_name.present?
        str = "#{str} #{self.father_first_name}"
    end
    if self.father_middle_name.present?
        str = "#{str} #{self.father_middle_name}"
    end
    if self.father_last_name.present?
        str = "#{str} #{self.father_last_name}"
    end
    return str.strip
  end

  def mothers_name
    str = ""
    if self.mother_first_name.present?
        str = "#{str} #{self.mother_first_name}"
    end
    if self.mother_middle_name.present?
        str = "#{str} #{self.mother_middle_name}"
    end
    if self.mother_last_name.present?
        str = "#{str} #{self.mother_last_name}"
    end
    return str.strip  
  end
  def self.qr_code_data(id)
    person = Person.find(id)
    str = "05~#{person.npid}-#{person.den}-#{person.drn}"
    str += "~#{person.person_name}~#{person.birthdate.to_date.strftime("%d-%b-%Y")}~#{person.gender.first}"
    str += "~#{person.nationality}"    
    str += "~#{person.date_of_death.to_date.strftime("%d-%b-%Y")}"
    str += "~#{person.printable_place_of_death}"
    str += ("~#{person.mothers_name}" rescue '~')
    str += ("~#{person.fathers_name}" rescue '~')
    str += ("~#{person.created_at.to_date.strftime("%d-%b-%Y")}" rescue nil)

    str
  end

  def cause_of_death
     return PersonICDCode.by_person_id.key(self.id).first
  end

  #Person properties
  property :source_id, String
  property :first_name, String
  property :middle_name, String
  property :last_name, String
  property :first_name_code, String
  property :last_name_code, String
  property :middle_name_code, String
  property :id_number, String
  property :gender, String
  property :birthdate, Date
  property :birthdate_estimated, Integer, :default => 0
  property :date_of_death, Date
  property :nationality_id, String
  property :nationality, String
  property :other_nationality, String
  property :place_of_registration, String
  property :place_of_death, String
  property :hospital_of_death_id, String
  property :hospital_of_death, String
  property :other_place_of_death, String
  property :other_place_of_death_village, String
  property :place_of_death_village, String
  property :place_of_death_village_id, String
  property :other_place_of_death_ta, String
  property :place_of_death_ta_id, String
  property :place_of_death_ta, String
  property :place_of_death_district_id, String
  property :place_of_death_district, String
  property :place_of_death_country, String
  property :other_place_of_death_country, String
  property :place_of_death_foreign, String
  property :place_of_death_foreign_state, String #State
  property :place_of_death_foreign_district, String #District
  property :place_of_death_foreign_village, String #Town / Village
  property :place_of_death_foreign_hospital, String
  property :cause_of_death_available, String
  property :autopsy_requested, String, :default => "No"
  property :autopsy_used_for_certification, String, :default => "No"
  property :cause_of_death1, String
  property :icd_10_1, String
  property :other_cause_of_death1, String
  property :onset_death_interval1, String
  property :cause_of_death2, String
  property :icd_10_2, String
  property :other_cause_of_death2, String
  property :onset_death_interval2, String
  property :cause_of_death3, String
  property :icd_10_3, String
  property :other_cause_of_death3, String
  property :onset_death_interval3, String
  property :cause_of_death4, String
  property :icd_10_4, String
  property :other_cause_of_death4, String
  property :onset_death_interval4, String
  property :cause_of_death_conditions, {}
  property :coder, String
  property :coded_at, Time
  property :icd_10_code, String
  property :manner_of_death, String
  property :other_manner_of_death, String
  property :death_by_accident, String
  property :other_death_by_accident, String
  property :other_home_village, String
  property :home_village_id, String
  property :home_village, String
  property :other_home_ta, String
  property :home_ta_id, String
  property :home_ta, String
  property :home_district_id, String
  property :home_district, String
  property :home_country_id, String
  property :home_country, String
  property :other_home_country, String
  property :home_foreign_state, String
  property :home_foreign_district, String
  property :home_foreign_village, String
  property :home_foreign_address, String
  property :other_current_village, String
  property :current_village_id, String
  property :current_village, String
  property :other_current_ta, String
  property :current_ta_id, String
  property :current_ta, String
  property :current_district_id, String
  property :current_district, String
  property :current_country_id, String
  property :current_country, String
  property :other_current_country, String
  property :current_foreign_state, String
  property :current_foreign_district, String
  property :current_foreign_village, String
  property :current_foreign_address, String
  property :died_while_pregnant, String, :default => "N/A"
  property :updated_by, String
  property :voided_by, String
  property :voided_date, Time
  property :voided, TrueClass, :default => false
  property :form_signed, String
  property :approved, String, :default => 'No'
  property :npid, String
  property :approved_by, String
  property :approved_at, Time
  property :delayed_registration, String,  :default =>"No"
  property :registration_type, String, :default => "Normal Cases" # Abnormal Death | Unclaimed bodies | Missing Persons | Death abroad
  property :court_order, String
  property :court_order_details, String 
  property :police_report, String
  property :police_report_details, String
  property :reason_police_report_not_available, String
  property :proof_of_death_abroad, String

  #Person's mother properties
  #property :mother do
  property :mother_id_number, String
  property :mother_first_name, String
  property :mother_middle_name, String
  property :mother_last_name, String
  property :mother_first_name_code, String
  property :mother_last_name_code, String
  property :mother_middle_name_code, String
  property :mother_gender, String
  property :mother_birthdate, Date
  property :mother_birthdate_estimated, String
  property :mother_current_village_id, String
  property :mother_current_ta_id, String
  property :mother_current_district_id, String
  property :mother_current_village, String
  property :mother_current_ta, String
  property :mother_current_district, String
  property :mother_home_village, String
  property :mother_home_ta_id, String
  property :mother_home_district_id, String
  property :mother_home_country_id, String
  property :mother_nationality_id, String
  property :mother_home_village_id, String
  property :mother_home_ta, String
  property :mother_home_district, String
  property :mother_home_country, String
  property :mother_nationality, String
  property :other_mother_nationality, String
  property :mother_occupation, String

  #Address details for foreigner
  property :mother_residential_country_id, String #Country
  property :mother_residential_country, String #Country

  property :mother_foreigner_current_district_id, String #District/State
  property :mother_foreigner_current_village_id, String #Village/Town
  property :mother_foreigner_current_ta_id, String #Address
  property :mother_foreigner_current_district, String #District/State
  property :mother_foreigner_current_village, String #Village/Town
  property :mother_foreigner_current_ta, String #Address

  property :mother_foreigner_home_district_id, String #District/State
  property :mother_foreigner_home_village_id, String #Village/Town
  property :mother_foreigner_home_ta_id, String #Address
  property :mother_foreigner_home_district, String #District/State
  property :mother_foreigner_home_village, String #Village/Town
  property :mother_foreigner_home_ta, String #Address

  #end

  #Person's father properties
  #property :father do
  property :father_id_number, String
  property :father_first_name, String
  property :father_middle_name, String
  property :father_last_name, String
  property :father_first_name_code, String
  property :father_last_name_code, String
  property :father_middle_name_code, String
  property :father_gender, String
  property :father_birthdate, Date
  property :father_birthdate_estimated, String
  property :father_current_village_id, String
  property :father_current_ta_id, String
  property :father_current_district_id, String
  property :father_current_village, String
  property :father_current_ta, String
  property :father_current_district, String
  property :father_home_village_id, String
  property :father_home_ta_id, String
  property :father_home_district_id, String
  property :father_home_country_id, String
  property :father_nationality_id, String
  property :father_home_village, String
  property :father_home_ta, String
  property :father_home_district, String
  property :father_home_country, String
  property :father_nationality, String
  property :other_father_nationality, String
  property :father_occupation, String

  #Address details for foreigner

  property :father_residential_country_id, String #Country
  property :father_residential_country, String #Country

  property :father_foreigner_current_district_id, String #District/State
  property :father_foreigner_current_village_id, String #Village/Town
  property :father_foreigner_current_ta_id, String #Address
  property :father_foreigner_current_district, String #District/State
  property :father_foreigner_current_village, String #Village/Town
  property :father_foreigner_current_ta, String #Address

  property :father_foreigner_home_district_id, String #District/State
  property :father_foreigner_home_village_id, String #Village/Town
  property :father_foreigner_home_ta_id, String #Address
  property :father_foreigner_home_district, String #District/State
  property :father_foreigner_home_village, String #Village/Town
  property :father_foreigner_home_ta, String #Address

  #end

  #Details of senior village member
  property :headman_verified, String
  property :headman_verification_date, Date

  #Details of church elder
  property :church_verified, String
  property :church_verification_date, Date

  #Death informant properties
  #property :informant do
  property :informant_id_number, String
  property :informant_first_name, String
  property :informant_middle_name, String
  property :informant_last_name, String
  property :informant_first_name_code, String
  property :informant_last_name_code, String
  property :informant_middle_name_code, String
  property :informant_relationship_to_deceased, String
  property :informant_relationship_to_deceased_other, String
  property :informant_current_village_id, String
  property :informant_current_ta_id, String
  property :informant_current_district_id, String
  property :informant_current_village, String
  property :informant_current_other_village, String
  property :informant_current_ta, String
  property :informant_current_other_ta, String
  property :informant_current_district, String
  property :informant_current_country, String
  property :other_informant_current_country, String
  property :informant_addressline1, String
  property :informant_addressline2, String
  property :informant_city, String
  property :informant_phone_number, String
  property :informant_foreign_state, String
  property :informant_foreign_district, String
  property :informant_foreign_village, String
  property :informant_foreign_address, String
  property :informant_signed, String
  property :informant_signature_date, Date
  property :informant_designation, String
  property :informant_employment_number, String 
  property :informant_office_name,String
  property :informant_office_address, String
  #end

  property :certifier_name, String
  property :certifier_license_number, String
  property :certifier_signed, String
  property :date_certifier_signed, Date
  property :position_of_certifier, String
  property :other_position_of_certifier, String  

  property :acknowledgement_of_receipt_date, Time, :default => Time.now

  #facility related information
  property :facility_code, String
  property :district_code, String

  property :created_by, String
  property :changed_by, String

  property :_deleted, TrueClass, :default => false
  property :_rev, String

  timestamps!

  design do
    view :by__id

    view :by_created_at

    view :by_updated_at

    view :by_approved

    view :by_registration_type

    view :by_registration_type_and_district_code

    view :by_coder_and_coded_at,
         :map => "function(doc) {
                  if (doc['type'] == 'Person' && doc['coder'] != null) {
                    emit([doc['coder'], doc['coded_at']], 1);
                  }
                }"
    view :by_district_code_and_created_at

    view :by_npid

    filter :facility_sync, "function(doc,req) {return req.query.facility_code == doc.facility_code}"
    filter :district_sync, "function(doc,req) {return req.query.district_code == doc.district_code}"

  end

end

