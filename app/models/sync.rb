class Sync < CouchRest::Model::Base
	before_save :set_district_code,:set_facility_code
	property :person_record_id, String
	property :dc_sync_status, TrueClass, :default => false
	property :hq_sync_status, TrueClass, :default => false
	property :record_status, String
	property :facility_code, String
	property :district_code, String
	timestamps!
	design do
		view :by__id
		view :by_person_id
		view :by_created_at
		view :by_updated_at
	    view :by_hq_unsynced,
			   :map => "function(doc) {
	                  if (doc['type'] == 'Sync' && doc['hq_sync_status'] == false) {
	                    	emit(doc['record_id'], 1);
	                  }
	                }"
		filter :district_sync, "function(doc,req) {return req.query.district_code == doc.district_code}"
		filter :facility_sync, "function(doc,req) {return req.query.facility_code == doc.facility_code}"
		filter :stats_sync, "function(doc,req) {return doc.district_code != null}"

	end

	def person
	    person = Person.find(self.person_record_id)
	    return person
	 end

	def set_district_code
		unless self.district_code.present?
			self.district_code = (self.person.district_code rescue CONFIG["district_code"])
		end      
	end

	def set_facility_code
		unless self.facility_code.present?
			self.facility_code = (self.person.facility_code rescue (CONFIG['facility_code'] rescue nil))
		end	
	end
end
