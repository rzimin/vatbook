module Vatbook

  class BookFetcher
    %w{curb tempfile time_diff tmpdir csv}.each { |lib| require lib }
    require 'nokogiri'
    require 'open-uri'

    STATUS_URL = "http://status.vatsim.net/status.txt"
    LOCAL_STATUS = "#{Dir.tmpdir}/vatsim_status.txt"
    LOCAL_DATA = "#{Dir.tmpdir}/vatbook.xml"


    attr_accessor :fir, :atc_bookings, :pilot_bookings, :enroute, :doc

    def initialize(fir, args = nil)
      @fir = fir.upcase
      @enroute = true
      process_arguments(args) if args.class == Hash
      @atc_bookings = []; @pilot_bookings = []; @atc_rus_bookings = []
      fir == '' ? @doc = data_file : @doc = raw_list
      atcs
      atcs_rus
      pilots
    end

    def raw_list
      Nokogiri::XML(open("http://vatbook.euroutepro.com/xml2.php?fir=#{@fir}"))
    end

    def fetch
       {:atc => atc_bookings, :pilots => pilot_bookings, :atc_rus => atc_rus_bookings}
    end

    def atc_bookings
      @atc_bookings
    end

     def atc_rus_bookings
      @atc_rus_bookings
    end

    def pilot_bookings
      @pilot_bookings
    end

    def atcs_count
      @doc.css("atcs booking").count
    end

    def pilots_count
      @doc.css("pilots booking").count
    end

    private

    def atcs
      @doc.css("atcs booking").each do |booking|
        @atc_bookings << Booking.new(booking, role = "atc", @fir)
      end
    end

    def atcs_rus
      @doc.css("atcs booking").each do |booking|
        callsign = booking.children.css("callsign").first.children.to_s
        @atc_rus_bookings << Booking.new(booking, role = "atc", @fir) if callsign[0]=='U'
      end
    end

    def pilots
      @doc.css("pilots booking").each do |booking|
        if @enroute == false
          bk = Booking.new(booking, role = "pilot", @fir)
          if bk.enroute == false
            @pilot_bookings << bk
          end
        else
          @pilot_bookings << Booking.new(booking, role = "pilot", @fir)
        end
      end
    end

    def process_arguments(args)
      args[:enroute] == false ? @enroute = false : @enroute = true
    end

   def data_file      
      File.exists?(LOCAL_DATA) ? read_local_datafile : create_local_data_file
      LOCAL_DATA
      Nokogiri::XML(open(LOCAL_DATA))    
    end
   
    def read_local_datafile
      data = File.open(LOCAL_DATA)
      difference = Time.diff(data.ctime, Time.now)[:minute]
      difference > 2 ? create_local_data_file : data.read
    end

    def create_local_data_file
          curl = Curl::Easy.new('http://vatbook.euroutepro.com/xml2.php')
          curl.timeout = 5
          curl.perform

          data = Tempfile.new('vatbook', :encoding => 'utf-8')
          File.rename data.path, LOCAL_DATA
          data = ccurl.gsub(/["]/, '\s').encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '').encode!('UTF-8', 'UTF-16')
          File.open(LOCAL_DATA, "w+") {|f| f.write(data)}
          File.chmod(0777, LOCAL_DATA)
          gem_data_file if curl.include? "<html><head>"
          gem_data_file if File.open(LOCAL_DATA).size == 0
        #rescue Curl::Err::HostResolutionError
         # gem_data_file
        #rescue Curl::Err::TimeoutError
         # gem_data_file
        #rescue
         # gem_data_file
        #rescue Exception
         # gem_data_file    
    end

  end

end
