require 'faraday'
require 'nokogiri'
require 'date'
require 'zip-codes'
require 'tzinfo'

class Shipshape::USPSShipment

  def initialize(str)
    @tracking_number = str
  end

  def timestamp
    datetime = DateTime.parse track_summary
    if timestamp_timezone
      timestamp_timezone.local_to_utc(datetime)
    else
      datetime
    end
  end

  def timestamp_timezone
    if location.to_s =~ /(\d{5})\Z/
      TZInfo::Timezone.get ZipCodes.identify($1)[:time_zone]
    else
      nil
    end
  end

  def status
    case track_summary
    when /^Arrived/
      "Arrived #{location}"
    when /was delivered/
      "Delivered #{location}"
    when /Your item departed our USPS facility/
      "Departed #{location}"
    end
  end

  def location
    case track_summary
    when /\b([A-Z\ ]+, [A-Z]{2} \d{5})\b/
      # SECAUCUS, NJ 07094
      # DES MOINES, IA 50318.
      $1.strip
    else
      nil
    end
  end

  def track_summary
    xml.xpath('//TrackSummary').first.content
  end

  def expected_delivery_date(str)
    # Your item arrived at the Post Office at 7:57 am on January 6, 2014 in DES MOINES, IA 50311. The Postal Service expects to deliver the item on Tuesday, January 7, 2014. Information, if available, is updated periodically throughout the day. Please check again later.
    case str
    when /The Postal Service expects to deliver the item on \w+, ([A-Za-z]+ \d{1,2}, \d\d\d\d)\b/
      Date.parse $1
    else
      nil
    end
  end


  private

  def xml
    @xml ||= Nokogiri::XML.parse(tracking_response)
  end

  def http_response
    @http_response ||= http_connection.get do |request|
      request.url '/ShippingAPI.dll'
      request.params["API"] = "TrackV2"
      request.params["XML"] = tracking_request.to_xml
    end
  end

  def tracking_request
    Nokogiri::XML::Builder.new do |xml|
      xml.TrackRequest("USERID" => ENV['USPS_USERID']) {
        xml.TrackID("ID" => @tracking_number)
      }
    end
  end

  def http_connection
    Faraday.new(url: "http://production.shippingapis.com") do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

end
