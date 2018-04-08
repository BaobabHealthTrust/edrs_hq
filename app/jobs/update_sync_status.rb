class UpdateSyncStatus
	include SuckerPunch::Job
  	workers 1
  	def perform
  		`bundle exec rake edrs:update_sync_status`
      update_sync_tracker = CronJobsTracker.first
      update_sync_tracker = CronJobsTracker.new if update_sync_tracker.blank?
      update_sync_tracker.time_last_updated_sync = Time.now
      update_sync_tracker.save
  		if Rails.env == "development"
          SuckerPunch.logger.info "Sync status update from DC Done"
        end

        if Rails.env == 'development'
        	UpdateSyncStatus.perform_in(60)
        else
  			UpdateSyncStatus.perform_in(900)
  		end
  	end
end