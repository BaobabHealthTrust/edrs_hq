require 'couchrest_model'

class Audit < CouchRest::Model::Base
  
  before_save :set_site_id, :set_site_type, :set_user_id

  property :record_id, String # Person/Audit...
  property :audit_type, String # Quality Control | Reprint | Audit | Amendment | User Access
  property :level, String # Person | User
  property :model, String
  property :field, String
  property :previous_value, String
  property :current_value, String
  property :reason, String
  property :user_id, String # User id
  property :site_id, String #Site Code | District Code
  property :site_type, String  #FACILITY, DC, HQ
  property :ip_address,String
  property :mac_address, Strin
  property :change_log, {}, :default => {}
  property :creator, String
  property :voided, TrueClass, :default => false
  timestamps!

  cattr_accessor :user
  
  timestamps!

  design do
    view :by__id
    view :by_record_id
    view :by_record_id_and_audit_type
    view :by_record_id_and_reason
    view :by_audit_type
    view :by_level
    view :by_user_id
    view :by_site_id
    view :by_site_type
    view :by_voided
    view :by_created_at
    view :by_updated_at

    filter :facility_sync, "function(doc,req) {return req.query.site_id == doc.site_id}"

  end

  def person
    person = Person.find(self.record_id)
    return person
  end

  def set_user_id
    if Audit.user.present?
      self.user_id = Audit.user
    else
     self.user_id = User.current_user.id rescue (User.by_role.key('System Administrator').first.id)
    end
  end
  
  def set_site_id
    if CONFIG['site_type'] =="facility"
      self.site_id = (self.person.facility_code rescue self.person.district_code)
    else
      self.site_id = (self.person.district_code rescue CONFIG["district_code"])
    end
  end  
  
  def set_site_type
     if CONFIG['site_type'] =="facility"
        self.site_type = "facility"
    else
        self.site_type = "DC"
    end
  end 
  def set_creator
    self.creator = (User.current_user.id rescue User.by_created_at.each.first)
  end
end
