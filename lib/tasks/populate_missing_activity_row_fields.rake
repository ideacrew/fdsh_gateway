# frozen_string_literal: true

# Report: Rake task to Populate activity_row collection with historical data
# format: RAILS_ENV=production bundle exec rake update:populate_activity_row

namespace :update do
  desc "Populate activity row collection with missing data that was calculated in view"
  task :populate_missing_activity_row_fields => :environment do
    start_time = Process.clock_gettime(Process::CLOCK_REALTIME)
    puts "Start Time: #{Time.at(start_time)}"
    count = 0

    incomplete_rows = ActivityRow.where(application_id: {'$in' => ['',nil]}).or(primary_hbx_id: {'$in' => ['',nil]})
    incomplete_rows.no_timeout.each do |row|
      t = Transaction.find(row.transaction_id)
      unless row.application_id
        app = JSON.parse(t.magi_medicaid_application).dig("family_reference", "hbx_id")
        row.application_id = app
        row.save
        count += 1
        puts "application_id updated for ActivityRow: #{row.correlation_id.strip} with app_id #{app}"
      end
      unless row.primary_hbx_id
        hbx = t.primary_applicant.dig(:person_hbx_id)
        row.primary_hbx_id = hbx
        row.save
        count += 1
        puts "primary_hbx_id updated for ActivityRow: #{row.correlation_id.strip} with hbx_id #{hbx}"
      end
    end

    end_time = Process.clock_gettime(Process::CLOCK_REALTIME)
    total_run_time = end_time - start_time
    puts "======================================"
    puts "Start Time: #{Time.at(start_time)}"
    puts "End Time: #{Time.at(end_time)}"
    puts "Total Run Time: #{ActiveSupport::Duration.build(total_run_time).inspect}"
    puts "======================================"
    puts "Total: #{count} ActivityRows updated."
    puts "======================================"
  end
end