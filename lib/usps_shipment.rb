require 'faraday'
require 'nokogiri'
require 'date'
require 'zip-codes'
require 'tzinfo'

class Shipshape::USPSShipment

  def initialize(str)
    @tracking_number = str
    @xml = get_xml
  end

  def timestamp
    time_string = case track_summary
    when /\b([A-Za-z]+ \d{1,2}, \d\d\d\d, \d{1,2}:\d\d [ap]m)\b/
      # January 2, 2014, 8:27 pm
      $1
    when /\b(\d{1,2}:\d\d [ap]m) on ([A-Za-z]+ \d{1,2}, \d\d\d\d)\b/
      # 3:21 pm on January 4, 2014
      "#{$2}, #{$1}"
    when /\b([A-Za-z]+ \d{1,2}, \d\d\d\d)\b/
      # January 4, 2014
      $1
    else
      nil
    end

    datetime = DateTime.parse time_string

    if timestamp_timezone
      timestamp_timezone.local_to_utc(datetime)
    else
      datetime
    end
  end

  def timestamp_timezone
    if location =~ /(\d{5})\Z/
      TZInfo::Timezone.get ZipCodes.identify($1)[:time_zone]
    else
      nil
    end
  end

  def status
    case track_summary
    when /^(Arrived)/
      "#{$1} #{location}"
    else
      nil
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
    @xml.xpath('//TrackSummary').first.content
  end

  def get_xml
    Nokogiri::XML.parse(tracking_response)
  end

  def tracking_response
    conn = Faraday.new(url: "http://production.shippingapis.com") do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
    tracking_request = Nokogiri::XML::Builder.new do |xml|
      xml.TrackRequest("USERID" => ENV['USPS_USERID']) {
        xml.TrackID("ID" => @tracking_number)
      }
    end
    resp = conn.get do |req|
      req.url '/ShippingAPI.dll'
      req.params["API"] = "TrackV2"
      req.params["XML"] = tracking_request.to_xml
    end
    resp.body
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

  def get_date_time(str)
    case str
    when /\b([A-Za-z]+ \d{1,2}, \d\d\d\d, \d{1,2}:\d\d [ap]m)\b/
      # January 2, 2014, 8:27 pm
      DateTime.parse $1
    when /\b(\d{1,2}:\d\d [ap]m) on ([A-Za-z]+ \d{1,2}, \d\d\d\d)\b/
      # 3:21 pm on January 4, 2014
      DateTime.parse "#{$2}, #{$1}"
    when /\b([A-Za-z]+ \d{1,2}, \d\d\d\d)\b/
      # January 4, 2014
      DateTime.parse $1
    else
      nil
    end
  end

  def get_location(str)
    case str
    when /\b([A-Z\ ]+, [A-Z]{2} \d{5})\b/
      # SECAUCUS, NJ 07094
      # DES MOINES, IA 50318.
      $1.strip
    else
      nil
    end
  end

end
