require 'httparty'
require 'nokogiri'
require 'singleton'
require 'addressable/uri'

module ExUA
  class ExUAFetcher
    include HTTParty
    no_follow true
    # Returns the redirect target for a given uri
    def self.get_redirect(uri)
      get URI.parse(URI.encode(uri))
    rescue HTTParty::RedirectionTooDeep => e
      e.response["location"]
    end
  end
  # Client for ExUA
  # @example Usage
  #   client = ExUA::Client.new
  #   categories = client.base_categories('ru')
  #
  class Client
    include Singleton
    KNOWN_BASE_CATEGORIES = %w[video audio images texts games software]
    class<<self
      [:available_languages, :base_categories, :search].each do |met|
        define_method(met) do |*args| #delegate to instance
          instance.public_send(met, *args)
        end
      end
    end
    # List of available languages
    # @return [Array<String>]
    def available_languages
      @available_langauges ||= get('/').search('select[name=lang] option').inject({}){|acc,el| acc[el.attributes["value"].value]=el.text;acc}
    end

    # List of base categories for a given language
    # @param[String] lang Language
    # @example Usage
    #   client.base_categories('ru')
    # @return [Array<ExUA::Category>]
    def base_categories(lang)
      base_categories_names.map{|cat| Category.new(url: "/#{lang}/#{cat}")}
    end

    # Search for a given @text
    # @param[String] text A term to search for
    # @param[Integer] page Page number, starting from 0
    # @param[Integer] per Items per page. Defaults to 20
    # @return[Array<ExUA::Category>] list of categories

    def search(text, page=0, per=20)
      uri = Addressable::URI.parse("/search?#{Addressable::URI.form_encode(s: text, p: page, per: per)}")
      page = get(uri)
      page.search('table.panel tr td').map do |s|
        s.search('a')[1]
      end.compact.map do |link|
        ExUA::Category.new(url: link.attributes['href'], name: link.text)
      end
    end

    def get(path)
      Nokogiri.parse(HTTParty.get(Addressable::URI.join(ExUA::BASE_URL,path).to_s).body)
    end

    private
    def base_categories_names
      KNOWN_BASE_CATEGORIES
    end
  end
end
