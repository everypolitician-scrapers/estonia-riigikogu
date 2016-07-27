#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'scraped_page_archive'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

class Polidata

  class Page

    attr_accessor :url

    def initialize(url)
      @url = url
    end

    def as_data
      @md ||= Hash[ protected_methods.map { |m| [m, send(m)] } ]
    end

    private

    def noko
      @noko ||= Nokogiri::HTML(open(url).read)
    end

  end

end

class Riigikogu

  class Liikmed < Polidata::Page

    protected

    def members
      noko.css('ul.profile-list li.item').map do |mp|
        {
          name:  mp.css('h3').text.tidy,
          url:   URI.escape(mp.css('h3 a/@href').text),
          email: mp.css('li a[href*="mailto"]').text,
        }
      end
    end

  end

  class Saadik < Polidata::Page

    protected

    def id
      url.split('/')[7]
    end

    def name
      noko.css('.page-header h1').text.tidy
    end

    def faction
      noko.css('.content a[href*="/fraktsioonid/"]').text.tidy
    end

    def image
      img = noko.css('.profile-photo img/@src').text or return
      URI.join(url, URI.escape(img)).to_s
    end

    def phone
      noko.css('.icon-tel').xpath('../text()').text
    end

    def email
      noko.css('.icon-mail').xpath('../text()').text
    end

    def facebook
      social_media.css('a.facebook/@href').text
    end

    def twitter
      social_media.css('a.twitter/@href').text
    end

    def source
      url
    end


    private
    def social_media
      noko.xpath('//h2[.="Sotsiaalmeedia"]/following-sibling::div[@class="group"]')
    end

  end
end

liikmed = Riigikogu::Liikmed.new('http://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/').as_data
liikmed[:members].each do |member|
  data = Riigikogu::Saadik.new(member[:url]).as_data
  ScraperWiki.save_sqlite([:id], data)
end
