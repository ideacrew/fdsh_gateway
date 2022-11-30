# Report: Rake task to Populate activity_row collection with historical data
# format: RAILS_ENV=production bundle exec rake update:populate_activity_row 

namespace :update do
    desc "Populate activity_row collection with historical data from transaction/activity collections"
    task :populate_activity_row => :environment do
        count = 0
        Transaction.no_timeout.each do |t|
            t.activities.each do |a|
                row = {
                    transaction_id: t._id,
                    application_id: t.application_id,
                    primary_hbx_id: t.primary_hbx_id,
                    fpl_year: t.fpl_year, 
                    correlation_id: a.correlation_id,
                    activity_name: a.event_key_label,
                    status: a.status, 
                    message: a.message
                  }
                  ::ActivityRow.create(row)
                  count += 1
                  puts "Activity_row created for activity: #{a.correlation_id.strip} on transaction: #{t._id}"
            end
        end
        puts "======================================"
        puts "Total: #{count} activity_rows created."
        puts "======================================"
    end
end