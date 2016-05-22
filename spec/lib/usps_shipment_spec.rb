require 'spec_helper'

describe "Shipshape::USPSShipment" do

  context "a delivered item" do
    before do
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<TrackResponse><TrackInfo ID=\"9361289680090035060667\"><TrackSummary>Your item was delivered in or at the mailbox at 11:26 am on May 16, 2016 in DES MOINES, IA 50311.</TrackSummary><TrackDetail>Out for Delivery, May 16, 2016, 8:36 am, DES MOINES, IA 50311</TrackDetail><TrackDetail>Sorting Complete, May 16, 2016, 8:26 am, DES MOINES, IA 50311</TrackDetail><TrackDetail>Arrived at Post Office, May 16, 2016, 8:23 am, DES MOINES, IA 50311</TrackDetail><TrackDetail>Acceptance, May 16, 2016, 4:57 am, DES MOINES, IA 50311</TrackDetail><TrackDetail>Pre-Shipment Info Sent to USPS, May 15, 2016</TrackDetail><TrackDetail>Departed Shipping Partner Facility, May 15, 2016, 7:35 pm, LENEXA, KS 66219</TrackDetail><TrackDetail>Departed Shipping Partner Facility, May 14, 2016, 11:16 pm, WHITESTOWN, IN 46075</TrackDetail><TrackDetail>Picked Up by Shipping Partner, May 14, 2016, 2:40 pm, WHITESTOWN, IN 46075</TrackDetail></TrackInfo></TrackResponse>"
      allow_any_instance_of(Shipshape::USPSShipment).to receive(:tracking_response).and_return(xml)
      @shipment = Shipshape::USPSShipment.new("9361289680090035060667")
    end

    it "returns a location" do
      expect(@shipment.location).to eql "DES MOINES, IA 50311"
    end

    it "returns a status" do
      expect(@shipment.status).to eql "Delivered DES MOINES, IA 50311"
    end

    it "returns a timestamp" do
      # TODO: account for timezone
      expect(@shipment.timestamp).to eql DateTime.parse("2016-05-16T16:26:00+00:00")
    end

    it "returns a timezone" do
      expect(@shipment.timestamp_timezone.class.to_s).to eql "TZInfo::DataTimezone"
      expect(@shipment.timestamp_timezone.to_s).to eql "America - Chicago"
    end
  end

  context "an in-transit shipment" do
    before do
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><TrackResponse><TrackInfo ID=\"9274899999158703477863\"><TrackSummary>Arrived Shipping Partner Facility, January 2, 2014, 8:27 pm, SECAUCUS, NJ 07094</TrackSummary><TrackDetail>Arrived Shipping Partner Facility, January 2, 2014, 8:27 pm, SECAUCUS, NJ 07094</TrackDetail></TrackInfo></TrackResponse>"
      allow_any_instance_of(Shipshape::USPSShipment).to receive(:tracking_response).and_return(xml)
      @shipment = Shipshape::USPSShipment.new("9400110200881038748491")
    end

    it "returns a location" do
      expect(@shipment.location).to eql "SECAUCUS, NJ 07094"
    end

    it "returns a status" do
      expect(@shipment.status).to eql "Arrived SECAUCUS, NJ 07094"
    end

    it "returns a timestamp" do
      # TODO: account for timezone
      expect(@shipment.timestamp).to eql DateTime.parse("2014-01-03T01:27:00+00:00")
    end

    it "returns a timezone" do
      expect(@shipment.timestamp_timezone.class.to_s).to eql "TZInfo::DataTimezone"
      expect(@shipment.timestamp_timezone.to_s).to eql "America - New York"
    end
  end

end