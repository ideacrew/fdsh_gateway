# frozen_string_literal: true

# This script creates Open Transmissions for both H36 and H41 for years 2022 & 2023
# bundle exec rails runner script/create_h36_h41_open_transmissions.rb

def create_h36_transmission(month_of_year, assistance_year)
  find_result = Fdsh::H36::Transmissions::Find.new.call(
    {
      assistance_year: assistance_year,
      month_of_year: month_of_year
    }
  )
  return find_result.success if find_result.success?

  Fdsh::H36::Transmissions::Create.new.call(
    {
      assistance_year: assistance_year,
      month_of_year: month_of_year
    }
  ).success
end

def create_h41_transmission(transmission_type, reporting_year)
  Fdsh::H41::Transmissions::FindOrCreate.new.call(
    {
      reporting_year: reporting_year,
      status: :open,
      transmission_type: transmission_type
    }
  )
end

create_h41_transmission(:corrected, 2022)
create_h41_transmission(:original, 2022)
create_h41_transmission(:void, 2022)

create_h41_transmission(:corrected, 2023)
create_h41_transmission(:original, 2023)
create_h41_transmission(:void, 2023)

create_h36_transmission(14, 2022)
create_h36_transmission(15, 2022)
create_h36_transmission(2, 2023)
create_h36_transmission(3, 2023)
