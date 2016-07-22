#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

class EPolidata

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

    def at_css(selector)
      _at_selector(selector_type: 'css', selector: selector)
    end

    def at_xpath(selector)
      _at_selector(selector_type: 'xpath', selector: selector)
    end

    def _at_selector(h)
      noko.send(h[:selector_type], h[:selector]).text.tidy
    end

  end

end

class Riigikogu

  class Liikmed < EPolidata::Page

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

  class Saadik < EPolidata::Page

    protected

    def id
      url.split('/')[7]
    end

    def name
      at_css('.page-header h1')
    end

    def faction
      at_css('.content a[href*="/fraktsioonid/"]')
    end

    def image
      img = noko.css('.profile-photo img/@src').text or return
      URI.join(url, URI.escape(img)).to_s
    end

    def phone
      at_xpath('//span[contains(@class,"icon-tel")]/following-sibling::text()')
    end

    def email
      at_xpath('//span[contains(@class,"icon-mail")]/following-sibling::text()')
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
