# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fdsh::H41::Transmissions::Publish do
  subject { described_class.new }

  before :each do
    FileUtils.rm_rf(Rails.root.join("h41_transmissions").to_s)
    FileUtils.rm_rf(Rails.root.join("h41_files").to_s)
  end

  after :all do
    FileUtils.rm_rf(Rails.root.join("h41_transmissions").to_s)
    FileUtils.rm_rf(Rails.root.join("h41_files").to_s)
  end

  after :each do
    DatabaseCleaner.clean
  end

  let(:report_kind) { :h41_1095a }

  context 'with invalid input params' do
    context 'bad report_type' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_type: :initial
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq(
          'report_type must be one corrected, original, void'
        )
      end
    end

    context 'bad report_type' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: :report_kind,
          report_type: :original
        }
      end

      it 'returns failure with errors' do
        result = subject.call(input_params)
        expect(result.failure).to eq(
          'report_kind must be one of [:h41_1095a, :h41]'
        )
      end
    end
  end

  context "no pending transactions for transmission" do
    let!(:insurance_polices) do
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households, transaction_xml: transaction_xml,
                                                                            transmission: open_transmission)
    end

    let(:outbound_folder) do
      Rails.root.join("h41_transmissions").to_s
    end

    let(:input_params) do
      {
        reporting_year: Date.today.year,
        report_kind: :h41,
        report_type: :original
      }
    end

    let!(:open_transmission) { FactoryBot.create(:h41_original_transmission) }
    let(:transaction_xml) do
      File.read(Rails.root.join("spec/test_payloads/h41/original.xml").to_s)
    end

    it 'should leave transmission in processing state' do
      open_transmission.transactions.update_all(status: :blocked, transmit_action: :no_transmit)
      @result = subject.call(input_params)
      open_transmission.reload
      expect(open_transmission.status).to eq :processing
    end

    it 'should not create h41_transmissons directory' do
      expect(Dir.exist?(Rails.root.join("h41_transmissions").to_s)).to be_falsey
    end
  end

  describe 'cms_eft_serverless feature' do
    let!(:insurance_polices) do
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households, transaction_xml: transaction_xml,
                                                                            transmission: open_transmission)
    end

    let(:outbound_folder) do
      Rails.root.join("h41_transmissions").to_s
    end

    let(:input_params) do
      {
        reporting_year: Date.today.year,
        report_kind: report_kind,
        report_type: :original
      }
    end

    let!(:open_transmission) { FactoryBot.create(:h41_original_transmission) }
    let(:transaction_xml) do
      File.read(Rails.root.join("spec/test_payloads/h41/original.xml").to_s)
    end

    context 'when feature is enabled' do
      before do
        allow(FdshGatewayRegistry).to receive(:feature_enabled?).with(:cms_eft_serverless).and_return(true)
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'validates file name format without .IN' do
        file_names = Dir.glob("#{outbound_folder}/*").collect {|file| File.basename(file) }
        expect(file_names.first).to match(/SBE00ME\.DSH\.EOYIN\.D\d{6}\.T\d{6}000\.P/)
      end
    end

    context 'when feature is disabled' do
      before do
        allow(FdshGatewayRegistry).to receive(:feature_enabled?).with(:cms_eft_serverless).and_return(false)
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'validates file name format with .IN' do
        file_names = Dir.glob("#{outbound_folder}/*").collect {|file| File.basename(file) }
        expect(file_names.first).to match(/SBE00ME\.DSH\.EOYIN\.D\d{6}\.T\d{6}000\.P\.IN/)
      end
    end
  end

  describe '.publish' do
    let!(:insurance_polices) do
      create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households, transaction_xml: transaction_xml,
                                                                            transmission: open_transmission)
    end

    let(:outbound_folder) do
      Rails.root.join("h41_transmissions").to_s
    end

    context 'for original' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :original
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_original_transmission) }
      let(:transaction_xml) do
        File.read(Rails.root.join("spec/test_payloads/h41/original.xml").to_s)
      end

      before do
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should generate h41 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change open transmission to transmitted' do
        expect(open_transmission.status).to eq :transmitted
      end

      it 'should create new open transmission' do
        new_transmission = Transmittable::Transmission.open.first

        expect(new_transmission).not_to eq open_transmission
        expect(new_transmission.reporting_year).to eq input_params[:reporting_year]
        expect(new_transmission.class).to eq open_transmission.class
      end

      it 'should transmission batch file' do
        file_names = Dir.glob("#{outbound_folder}/*").collect do |file|
          File.basename(file)
        end
        expect(file_names.count).to eq 1
        expect(file_names.first).to match(/SBE00ME\.DSH\.EOYIN\.D\d{6}\.T\d{6}000\.P\.IN/)
      end

      it 'should update transmission to transmitted state' do
        open_transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end

      it 'should create transmission paths' do
        expect(open_transmission.transmission_paths.count).to eq open_transmission.transactions.count
      end

      context 'with h41 as report_kind' do
        let(:report_kind) { :h41 }

        it 'should geenrate H41 transmission' do
          expect(@result.success).to eq(
            "Successfully generated H41 transmissions only for given report_type: original"
          )
        end

        it 'should update the existing transmission with report_kind' do
          expect(open_transmission.report_kind).to eq(report_kind)
        end
      end
    end

    context 'for corrected' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :corrected
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }
      let(:transaction_xml) { File.read(Rails.root.join("spec/test_payloads/h41/corrected.xml").to_s) }

      before do
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should generate corrected h41 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change open transmission to transmitted' do
        expect(open_transmission.status).to eq :transmitted
      end

      it 'should create new open transmission' do
        new_transmission = Transmittable::Transmission.open.first

        expect(new_transmission).not_to eq open_transmission
        expect(new_transmission.reporting_year).to eq input_params[:reporting_year]
        expect(new_transmission.class).to eq open_transmission.class
      end

      it 'should transmission batch file' do
        file_names = Dir.glob("#{outbound_folder}/*").collect do |file|
          File.basename(file)
        end
        expect(file_names.count).to eq 1
        expect(file_names.first).to match(/SBE00ME\.DSH\.EOYIN\.D\d{6}\.T\d{6}000\.P\.IN/)
      end

      it 'should have valid original batch id tag in manifest file' do
        destination_directory = "#{Rails.root}/h41_files"
        FileUtils.mkdir_p(destination_directory) unless File.directory?(destination_directory)
        file_names = Dir.glob("#{outbound_folder}/*").collect do |file|
          File.basename(file)
        end

        Zip::File.open("#{Rails.root}/h41_transmissions/#{file_names.first}") do |zip_file|
          zip_file.each do |entry|
            # Construct the destination path for each file in the zip
            destination_path = File.join(destination_directory, entry.name)

            # Extract the file
            entry.extract(destination_path)
          end
        end

        file = File.open("#{Rails.root}/h41_files/manifest.xml", "r")
        begin
          file_contents = file.read
          text_to_check = "OriginalBatchID"
          expect(file_contents).to include(text_to_check)
        ensure
          file.close
        end
      end

      it 'should update transmission to transmitted state' do
        open_transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end

      it 'should create transmission paths' do
        expect(open_transmission.transmission_paths.count).to eq open_transmission.transactions.count
      end

      context 'with h41 as report_kind' do
        let(:report_kind) { :h41 }

        it 'should geenrate H41 transmission' do
          expect(@result.success).to eq(
            "Successfully generated H41 transmissions only for given report_type: corrected"
          )
        end

        it 'should update the existing transmission with report_kind' do
          expect(open_transmission.report_kind).to eq(report_kind)
        end
      end
    end

    context 'for void' do
      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :void
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_void_transmission) }
      let(:transaction_xml) { File.read(Rails.root.join("spec/test_payloads/h41/void.xml").to_s) }

      before do
        @result = subject.call(input_params)
        open_transmission.reload
      end

      it 'should generate void h41 successfully' do
        expect(@result.success?).to be_truthy
      end

      it 'should change open transmission to transmitted' do
        expect(open_transmission.status).to eq :transmitted
      end

      it 'should create new open transmission' do
        new_transmission = Transmittable::Transmission.open.first

        expect(new_transmission).not_to eq open_transmission
        expect(new_transmission.reporting_year).to eq input_params[:reporting_year]
        expect(new_transmission.class).to eq open_transmission.class
      end

      it 'should transmission batch file' do
        file_names = Dir.glob("#{outbound_folder}/*").collect do |file|
          File.basename(file)
        end
        expect(file_names.count).to eq 1
        expect(file_names.first).to match(/SBE00ME\.DSH\.EOYIN\.D\d{6}\.T\d{6}000\.P\.IN/)
      end

      it 'should update transmission to transmitted state' do
        open_transmission.transactions.each do |transaction|
          expect(transaction.status).to eq :transmitted
          expect(transaction.transmit_action).to eq :no_transmit
        end
      end

      it 'should create transmission paths' do
        expect(open_transmission.transmission_paths.count).to eq open_transmission.transactions.count
      end

      context 'with h41 as report_kind' do
        let(:report_kind) { :h41 }

        it 'should geenrate H41 transmission' do
          expect(@result.success).to eq(
            "Successfully generated H41 transmissions only for given report_type: void"
          )
        end

        it 'should update the existing transmission with report_kind' do
          expect(open_transmission.report_kind).to eq(report_kind)
        end
      end
    end

    context 'when allow and deny lists provided' do

      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :corrected,
          allow_list: allow_list,
          deny_list: deny_list
        }
      end

      let(:deny_list) { ['444232', '333423'] }
      let(:allow_list) { ['553231', '577742'] }

      let!(:active_exclusions) do
        create(:subject_exclusion, :active, subject_name: 'PostedFamily', subject_id: '553231')
      end

      let!(:expired_exclusions) do
        create(:subject_exclusion, :expired, subject_name: 'PostedFamily', subject_id: '333423')
      end

      let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }
      let(:transaction_xml) { File.read(Rails.root.join("spec/test_payloads/h41/corrected.xml").to_s) }

      before do

        open_transmission.reload
      end

      it 'should ingest deny list and allow list' do
        expect(Transmittable::SubjectExclusion.active.map(&:subject_id)).to match_array(['553231'])
        expect(Transmittable::SubjectExclusion.expired.map(&:subject_id)).to match_array(['333423'])

        result = subject.call(input_params)

        expect(result.success?).to be_truthy
        expect(Transmittable::SubjectExclusion.active.map(&:subject_id)).to match_array(deny_list)
        expect(Transmittable::SubjectExclusion.expired.map(&:subject_id)).to match_array(['553231', '333423'])
      end
    end

    context '.create_batch_reference' do

      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :corrected
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_corrected_transmission) }
      let(:transaction_xml) { File.read(Rails.root.join("spec/test_payloads/h41/corrected.xml").to_s) }

      context 'when no previous reference stored' do
        let(:batch_time) { Time.now + 1.hours }
        let(:new_batch_reference) { batch_time.strftime("%Y-%m-%dT%H:%M:%SZ") }

        before do
          allow(subject).to receive(:construct_new_batch_reference).and_return(new_batch_reference)
          @result = subject.call(input_params)
          open_transmission.reload
        end

        it 'should create transmission with new batch reference' do
          file_names = Dir.glob("#{outbound_folder}/*").collect do |file|
            File.basename(file)
          end

          expected_file_name = "SBE00ME.DSH.EOYIN.D#{batch_time.strftime('%y%m%d.T%H%M%S000.P.IN')}"
          expect(file_names.count).to eq 1
          expect(file_names.first).to eq(expected_file_name)
        end
      end
    end

    context 'for denied/errored transactions' do

      let!(:insurance_polices) do
        create_list(:h41_insurance_policy, 20, :with_aptc_csr_tax_households, transaction_xml: transaction_xml,
                                                                              transmission: open_transmission)
      end

      let(:outbound_folder) do
        Rails.root.join("h41_transmissions").to_s
      end

      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :original
        }
      end

      let!(:open_transmission) { FactoryBot.create(:h41_original_transmission) }
      let(:transaction_xml) do
        File.read(Rails.root.join("spec/test_payloads/h41/original.xml").to_s)
      end

      let(:exclusion_contract_holder_hbx_ids) do
        ['242323', '323111']
      end

      let!(:policy_hbx_ids) do
        insurance_polices.map(&:policy_hbx_id)
      end

      let!(:exclusion_transactions) do
        transactions = []
        first_policy = insurance_polices.detect {|policy| policy.policy_hbx_id == policy_hbx_ids[5]}
        first_policy.posted_family.update(contract_holder_id: '242323')
        transactions << first_policy.aptc_csr_tax_households.first.transactions.first
        second_policy = insurance_polices.detect {|policy| policy.policy_hbx_id == policy_hbx_ids[15]}
        second_policy.posted_family.update(contract_holder_id: '323111')
        transactions << second_policy.aptc_csr_tax_households.first.transactions.first
        transactions
      end

      let!(:errored_transactions) do
        transactions = []
        first_policy = insurance_polices.detect {|policy| policy.policy_hbx_id == policy_hbx_ids[9]}
        first_policy.aptc_csr_tax_households.first.update(transaction_xml: '')
        transactions << first_policy.aptc_csr_tax_households.first.transactions.first
        second_policy = insurance_polices.detect {|policy| policy.policy_hbx_id == policy_hbx_ids[18]}
        second_policy.aptc_csr_tax_households.first.update(transaction_xml: '')
        transactions << second_policy.aptc_csr_tax_households.first.transactions.first
        transactions
      end

      let(:input_params) do
        {
          reporting_year: Date.today.year,
          report_kind: report_kind,
          report_type: :original,
          deny_list: exclusion_contract_holder_hbx_ids
        }
      end

      context 'transaction belongs to an excluded family' do

        it 'should exclude from transmission with a denial' do

          subject.call(input_params)
          exclusion_transactions.each do |transaction|
            transaction.reload
            expect(transaction.status).to eq :denied
            expect(transaction.transmit_action).to eq :no_transmit
          end
        end
      end

      context 'transaction errored' do

        it 'should record errors' do

          subject.call(input_params)
          errored_transactions.each do |transaction|
            transaction.reload
            expect(transaction.status).to eq :errored
            expect(transaction.transmit_action).to eq :no_transmit
            expect(transaction.transaction_errors).to eq({ "h41" => "ERROR: Undefined namespace prefix: //airty20a:Form1095AUpstreamDetail" })
          end
        end
      end
    end
  end
end
