#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'scraped_page_archive/open-uri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

class EPolidata
  require 'field_serializer'

  class Page
    include FieldSerializer

    def initialize(url)
      @url = url
    end

    def noko
      @noko ||= Nokogiri::HTML(open(url).read)
    end

    private

    attr_accessor :url

    def at_css(selector, h={})
      _at_selector(h.merge(selector_type: 'css', selector: selector))
    end

    def at_xpath(selector, h={})
      _at_selector(h.merge(selector_type: 'xpath', selector: selector))
    end

    def _at_selector(h)
      start_node = h[:scope] || noko
      start_node.send(h[:selector_type], h[:selector]).text.tidy
    end

    def absolute_link(rel)
      return if rel.to_s.empty?
      URI.join(url, URI.encode(URI.decode(rel)))
    end
  end

end

class Riigikogu

  class Liikmed < EPolidata::Page
    field :members do
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
    field :id do
      url.split('/')[7]
    end

    field :name do
      at_css('.page-header h1')
    end

    field :faction do
      at_css('.content a[href*="/fraktsioonid/"]')
    end

    field :image do
      absolute_link(at_css('.profile-photo img/@src')).to_s
    end

    field :phone do
      at_xpath('//span[contains(@class,"icon-tel")]/following-sibling::text()')
    end

    field :email do
      at_xpath('//span[contains(@class,"icon-mail")]/following-sibling::text()')
    end

    field :facebook do
      at_css('a.facebook/@href', scope: social_media)
    end

    field :twitter do
      at_css('a.twitter/@href', scope: social_media)
    end

    field :source do
      url
    end


    private
    def social_media
      noko.xpath('//h2[.="Sotsiaalmeedia"]/following-sibling::div[@class="group"]')
    end

  end
end

liikmed = Riigikogu::Liikmed.new('http://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/').to_h
liikmed[:members].each do |member|
  data = Riigikogu::Saadik.new(member[:url]).to_h
  ScraperWiki.save_sqlite([:id], data)
end
