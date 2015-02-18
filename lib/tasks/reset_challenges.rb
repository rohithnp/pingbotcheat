task :reset_challenges => :environment do
    Challange.where("status = ? and created_at >= ?", 0, Time.zone.now.beginning_of_day)
    		 .update_all(status: -1)
end