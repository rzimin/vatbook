module Vatbook

  class BookFetcher
    require 'nokogiri'
    require 'open-uri'

    attr_accessor :fir, :atc_bookings, :pilot_bookings, :enroute, :doc

    def initialize(fir, args = nil)
      @fir = fir.upcase
      @enroute = true
      process_arguments(args) if args.class == Hash
      @atc_bookings = []; @pilot_bookings = []; @atc_rus_bookings = []
      @doc = raw_list
      atc
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
        @atc_rus_bookings << Booking.new(booking, role = "atc", @fir) if booking.callsign[0]=='U'
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

  end

end
