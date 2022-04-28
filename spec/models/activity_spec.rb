# frozen_string_literal: true

require 'rails_helper'
require 'medicare_metadata_setup'

RSpec.describe Activity, type: :model, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:correlation_id) { "id123" }
  # rubocop:disable Layout/LineLength
  let(:xml_message) do
    {
      "request" => "VmA/OAYBXNKGAyGcrXZGfZNv/fkDKJJB39xRKCEnQPRPYe6HHl5juHsOhVs3\nrf4FcTB+nGiVPCfOmHOntPxI8nyAJPAlorLEBdViVdv+9iDJEnEI8bh2eoQx\nIc+1TtvNGVP/VilQbm1vsbFsH4NLRJsJHrkRlma3trXgVNJ+uyBctT/LQX/8\nfAkjBorfEooKho5DYbzWFCV2iLFZqkhlLQzvZRECxwZXggkEjUvMYHwdms9H\nN0guPsN6V/+4BxMjw7pzmupIYjFhWchkiZxBuf2smkDB+0vzz3MJhlGatevI\nd9vqvGUuU1MqPamYOezXYHdp1WSn90Ja5bJnhdjY0f9RZ3JKSj/xwUOsb2tH\ndHIZaWqXaDKWwct0iZRzRGQm/WQa1piw3MQeQ2r4Vj6cqIhuAYseNbQLrXZG\nULTAtMpC3WlbcMogNh964yWHSF6T8kd3m9iOFXT8iFIwDePX42r0SqYjpdCt\nEsy+DpDJSQO4WGIDzYmXshzbC2uN/FEhrTf831Fc+XOS8zJYpduRK9XNhK12\nBtn3agJbzlmoD6YsSKlMPPZPNq2zUtLFP5iTOPwqw5OOxWwLILCh9PDljk6G\n4AdqYiQKdt+JH8b5p0tPK16qAe5FBvCxDZYlldgM1YKheic9LNQHEEH7oe69\nfHubsHRNinXv683xsP8b4ZwzL0IC5FKBR+qb//o178gzp9oFDCnYLr9o924L\n5xt2ufXOxxJMZJC/xlZs0WSTndxSZ8zicMkJlqBrZ8yvJ62pgK2btpcbABld\nK+IH/X57wWft5tZPiRhpb590MPP4T1ACpoWFT1wCJc5wjJOVhjhF323KZ92x\nKndCB6Cg0heVhTxBHRn36twFnpidcJYnQ7/Qr4P9lGniCsL+bxixqmfjff9z\nDBMVDklJVdZcZ5GxWs10FBWdV20Pctfe5tREooagvkO3sgz26up/32Y/pRKj\nYROQGUQHY+ldDZueqcRGD4KN8i8W2IHIN1vr4/n4rncwpR/suoJf2Ri74c2m\nYvwskR3QYqnIYdoEsIG4pL5U+Y16EZCE4di9lRXA8CNJhueCRcvnSQf8XyJV\n7nUl76uWp72AuQFuxabuk7WRmD6LBTGlidmFFrmJhJB8MavYXJ6OMTGNLzpF\ndOn4ysORumHjSCm+FKqJzO1E3SICahHxB5D7TGY1Skn9us27as7/U5W5SJKi\ng+SqZO3csu4gmhjrTZfw7W82Ws5JPXAeFNlQAfBFbXTx7Nz8haj6Mssn4Nbx\nvd07ZiYUiUqFIHbn+ZhXNFcy+xQPYn+dCI58jbTHxJseU3LNLlpoNahPYPfk\nabt2+BYcTn8CtSMikErn9ZKyJjy5WmaSAnr2rFLwO/fKnrGOlcBd2Ju5kskL\nMPep027uQx3qv6nUoKiMC7F5z14hQkIqda9lEjjrCL8p8hYiawVuaARetDie\ncFoxZX4Z0lcOFZEhtIUyZikpch40sATCKr/gCJr8o2j4qxQq3iTHIToMbXLf\njjJD8m4mkiXz0unFGw2/A0Xvffxy1abvzedlGpi+64eUPMKLpuiSJ9qENtWH\nPBhGMvaKGctIFKTOn/JupJ13RUawFmEg9u7YP+tq7tfkPYdTQTaYzGmiS9Wh\npxl7xQHwseGyyamfxV4Xbkk6AuwoLN3UDxjxRuOgOrae0IU00tHXp1064NWb\ntFF/Iek4mezUtOTotv8VBSiN+nSKQ8QOjgVvEpuBbgX3LSKORoM6L29feU6+\nJLIsEv75MRY=\n"
    }
  end
  let(:hash_message) do
    {
      "response" => "G6FcgAgTzmtVefXEwR6oT8oRyblDd5gdxt9JWjIxQuhIfeXpJwhwrDBw5hQb\ntKdWIztWoFGTfHiTiGC686sp3zugKOUsg7PZJctObP/ZxTHZRS4Ap8prZJgw\nPIamY9HEQS3nHBVhLmdwrvczWMJHc5tUHb8Sy2eAu+jgS8ggpyFA9QzBT1f8\nZlMPGpTAQYcY2cc/DbvWQBMj0vBT4VAkITnlYE4DwBBf/QIfm0mPISkU3bAQ\nawsdcsxcKYbvByE5ivxGjLsMOD15FZdykZxLuPqumkLd+UbVw20SqmbM07zL\nftu+1Ds8Q0IoHKGEK57EZnVl2z+I839zz5hojcP2ya4VPXh4BiWqwyriPEJA\nJSxJb12JfTPF8s9ojql4ZEcH2nMamtaimOQTUWvjWD6juPkuQoJCZ+1U6xAb\nFPX5so4XikkbcME3OkJPpG2PBWO0wHtKu9yUBD+gwwNhS7iVvQesSqcy7K6G\nXIjaT8SMN0yqWmFSicrD7Qu4XzuDvx0moins8UUCqiW23ywU7JjQZYGoyJhk\nX4uobDFY21j9JqYsaLZNFexWIaaZetHTFp/CZqwq746D8HpaZOyw+bztik/P\n1U46WCUXRMSeFMvSh1ZaG0L5ULNUE/DiWMRg0bFCkbe3K2NhPYBTE02tgu6y\nIza8jWJQqmfr/eXh7qxRzZchL0UG/l6WOaXNrqUlpZJ/j9hRKCTGJIB0wXYQ\n3BdascbOmVZdO6KkihoxjBnOvA==\n"
    }
  end
  # rubocop:enable Layout/LineLength
  let(:mm_application) { TEST_APPLICATION_1 }

  let(:activity) do
    {
      correlation_id: correlation_id,
      command: "Fdsh::NonEsi::H31::RequestNonEsiDetermination",
      event_key: "event_key1",
      message: xml_message,
      status: nil
    }
  end

  let(:activity2) do
    {
      correlation_id: correlation_id,
      command: "Fdsh::NonEsi::H31::RequestNonEsiDetermination",
      event_key: "event_key2",
      message: hash_message,
      status: nil
    }
  end

  let(:transaction_values) do
    {
      correlation_id: correlation_id,
      magi_medicaid_application: mm_application.to_json,
      activities: [activity, activity2]
    }
  end

  context 'with an encrypted message' do

    before do
      @transaction = Transaction.new(transaction_values)
      @transaction.save!
      @activity1 = @transaction.activities.detect {|a| a.event_key == "event_key1" }
      @activity2 = @transaction.activities.detect {|a| a.event_key == "event_key2" }
    end

    it 'should decrypt the first activity into xml' do
      expect(@activity1.xml_formatted_message?).to eq true
    end

    it 'should decrypt the first activity into a hash' do
      expect(@activity2.xml_formatted_message?).to eq false
    end

  end
end