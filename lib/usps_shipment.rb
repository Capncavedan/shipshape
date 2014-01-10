require 'faraday'
require 'nokogiri'
require 'date'

class Shipshape::USPSShipment

  def initialize(str)
    @tracking_number = str
  end


  def track
    # tracking_number = '9274899999158703477863'  # AAAs
    tracking_number = '9400110200881038748491'  # AAs

    conn = Faraday.new(:url => "http://production.shippingapis.com") do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.TrackRequest("USERID" => ENV['USPS_USERID']) {
        xml.TrackID("ID" => tracking_number)
      }
    end
    resp = conn.get do |req|
      req.url '/ShippingAPI.dll'
      req.params["API"] = "TrackV2"
      req.params["XML"] = builder.to_xml
    end

    result_xml = Nokogiri::XML.parse(resp.body)

    puts result_xml

    puts "---------"

    summary = nil
    result_xml.xpath('//TrackSummary').each do |n|
      summary = n.content
      puts "#{n.content}  ::  #{get_date_time(n.content)}  ::  #{get_location(n.content)}"
    end

    result_xml.xpath('//TrackDetail').each do |n|
      puts "#{n.content}  ::  #{get_date_time(n.content)}  ::  #{get_location(n.content)}"
    end

    puts "\nExpected delivery date: #{expected_delivery_date(summary)}"
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
