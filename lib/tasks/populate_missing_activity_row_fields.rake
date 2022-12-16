# frozen_string_literal: true

# Report: Rake task to Populate activity_row collection with historical data
# format: bundle exec rake update:populate_missing_activity_row_fields

namespace :update do
  desc "Populate activity row collection with missing data that was calculated in view"
  task :populate_missing_activity_row_fields => :environment do
    start_time = Process.clock_gettime(Process::CLOCK_REALTIME)
    count = 0

    incomplete_rows = ActivityRow.where(application_id: { '$in' => ['', nil] }).or(primary_hbx_id: { '$in' => ['', nil] })

    incomplete_rows.no_timeout.each do |row|
      t = Transaction.find(row.transaction_id)
      app = t.magi_medicaid_application_hash.dig(:family_reference, :hbx_id)
      hbx = t.primary_applicant[:person_hbx_id]
      params = {}
      params[:application_id] = app if row.application_id.blank? && app.present?
      params[:primary_hbx_id] = hbx if row.primary_hbx_id.blank? && hbx.present?
      if params.present?
        result = row.update(params)
        if result
          count += 1
          puts "ActivityRow #{row.correlation_id.strip} updated with #{params}"
        else
          puts "ActivityRow #{row.correlation_id.strip} FAILED to update with #{params}"
        end
      else
        puts "Application ID and primary HBX ID NOT FOUND for correlation_id #{t.correlation_id.strip}"
      end
    end

    end_time = Process.clock_gettime(Process::CLOCK_REALTIME)
    total_run_time = end_time - start_time
    puts "======================================"
    puts "Start Time: #{Time.at(start_time)}"
    puts "End Time: #{Time.at(end_time)}"
    puts "Total Run Time: #{ActiveSupport::Duration.build(total_run_time).inspect}"
    puts "======================================"
    puts "#{count} ActivityRows updated."
    puts "======================================"
  end
end