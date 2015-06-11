require 'rails_helper'

describe ConstituencyApi::Mp do
  describe "#initialize" do
    let(:mp) { ConstituencyApi::Mp.new(1536, "Emily Thornberry MP", "2015-05-07T00:00:00") }

    it "converts valid date string into a datetime variable" do
      expect(mp.start_date).to eq Date.new(2015, 5, 7)
    end

  describe "#url" do
    let(:mp) { ConstituencyApi::Mp.new(1536, "Emily Thornberry MP", Date.new(2015, 5, 7)) }

    it "returns the URL for the mp" do
      expect(mp.url).to eq "#{ConstituencyApi::Mp::URL}/emily-thornberry-mp/1536"
    end
  end
end

describe ConstituencyApi do
  describe "#constituencies" do
    let(:api) { ConstituencyApi::Client }
    let(:api_url) { "http://data.parliament.uk/membersdataplatform/services/mnis/Constituencies" }

    let(:mp_1) { ConstituencyApi::Mp.new(1536, "Emily Thornberry MP", Date.new(2015, 5, 7)) }
    let(:mp_2) { ConstituencyApi::Mp.new(172, "Ms Diane Abbott MP", Date.new(2015, 5, 7)) }
    let(:mp_3) { ConstituencyApi::Mp.new(1524, "Meg Hillier MP", Date.new(2015, 5, 7)) }
    let(:mp_4) { ConstituencyApi::Mp.new(4514, "Keir Starmer MP", Date.new(2015, 5, 7)) }
    let(:mp_5) { ConstituencyApi::Mp.new(185, "Jeremy Corbyn MP", Date.new(2015, 5, 7)) }

    let(:constituency_array_1) { [ConstituencyApi::Constituency.new("Islington South and Finsbury", mp_1)] }
    let(:constituency_array_2) { [ConstituencyApi::Constituency.new("Hackney North and Stoke Newington", mp_2),
                                  ConstituencyApi::Constituency.new("Hackney South and Shoreditch", mp_3),
                                  ConstituencyApi::Constituency.new("Holborn and St Pancras", mp_4),
                                  ConstituencyApi::Constituency.new("Islington North", mp_5),
                                  ConstituencyApi::Constituency.new("Islington South and Finsbury", mp_1)] }
    let(:constituency_array_3) { [ConstituencyApi::Constituency.new("Holborn and St Pancras", mp_4)] }

    let(:empty_body) { IO.read(Rails.root.join("spec", "fixtures", "constituency_api", "no_results.xml")) }
    let(:fake_body) { IO.read(Rails.root.join("spec", "fixtures", "constituency_api", "N11TY.xml")) }
    let(:fake_body_multiple) { IO.read(Rails.root.join("spec", "fixtures", "constituency_api", "N1.xml")) }
    let(:fake_body_multiple_mps) { IO.read(Rails.root.join("spec", "fixtures", "constituency_api", "N1C4QP.xml")) }

    it "returns an empty Constituency array for invalid postcode" do
      stub_request(:get, "#{ api_url }/SW149RQ/").to_return(status: 200, body: empty_body)
      expect(api.constituencies("SW14 9RQ")).to eq []
    end

    it "returns Constituency array for valid postcode" do
      stub_request(:get, "#{ api_url }/N11TY/").to_return(status: 200, body: fake_body)
      expect(api.constituencies("N11TY")).to eq constituency_array_1
    end

    it "returns Constituency array for valid postcode with whitespaces" do
      stub_request(:get, "#{ api_url }/N11TY/").to_return(status: 200, body: fake_body)
      expect(api.constituencies("N1 1TY ")).to eq constituency_array_1
    end

    it "returns Constituency array for valid postcode with lowercase" do
      stub_request(:get, "#{ api_url }/n11ty/").to_return(status: 200, body: fake_body)
      expect(api.constituencies("n11ty")).to eq constituency_array_1
    end

    it "returns Constituency array with multiple entries" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 200, body: fake_body_multiple)
      expect(api.constituencies("N1")).to eq constituency_array_2
    end

    it "returns Constituency array with the last MP where the MP has changed since the last term" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 200, body: fake_body_multiple_mps)
      expect(api.constituencies("N1")).to eq constituency_array_3
    end

    it "handles timeout errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_timeout
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::Error)
    end

    it "handles connection failed errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_raise(Faraday::Error::ConnectionFailed)
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::Error)
    end

    it "handles resource not found errors" do
      stub_request(:any, /.*data.parliament.uk.*/).to_raise(Faraday::Error::ResourceNotFound)
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::Error)
    end

    it "handles unexpected response" do
      stub_request(:get, "#{ api_url }/N1/").to_return(status: 500, body: fake_body)
      expect{ api.constituencies("N1").count }.to raise_error(ConstituencyApi::Error)
    end
  end
end

