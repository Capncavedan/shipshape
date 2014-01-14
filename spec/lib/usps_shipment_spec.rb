require 'spec_helper'

describe "Shipshape::USPSShipment" do

  context "instance methods" do

    before do
      Shipshape::USPSShipment.any_instance.stub(:tracking_response).and_return(
<<-XML
<?xml version="1.0" encoding="UTF-8"?>
<TrackResponse>
  <TrackInfo ID="9274899999158703477863">
    <TrackSummary>Arrived Shipping Partner Facility, January 2, 2014, 8:27 pm, SECAUCUS, NJ 07094</TrackSummary>
    <TrackDetail>Arrived Shipping Partner Facility, January 2, 2014, 8:27 pm, SECAUCUS, NJ 07094</TrackDetail>
  </TrackInfo>
</TrackResponse>
XML
)
      @shipment = Shipshape::USPSShipment.new("9400110200881038748491")
    end

    it "returns a location" do
      @shipment.location.should eql "SECAUCUS, NJ 07094"
    end

    it "returns a status" do
      @shipment.status.should eql "Arrived SECAUCUS, NJ 07094"
    end

    it "returns a timestamp" do
      # TODO: account for timezone
      @shipment.timestamp.should eql DateTime.parse("2014-01-03T01:27:00+00:00")
    end

    it "returns a timezone" do
      @shipment.timestamp_timezone.class.to_s.should eql("TZInfo::DataTimezone")
      @shipment.timestamp_timezone.to_s.should eql "America - New York"
    end

  end
end