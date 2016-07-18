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

class Polidata

  class Page

    def initialize(url)
      @url = url
    end

    def as_data
      @md ||= Hash[ protected_methods.map { |m| [m, send(m)] } ]
    end

    private

    def noko
      @noko ||= Nokogiri::HTML(open(@url).read)
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
end


def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_mp(url)
  noko = noko_for(url)
  puts url
  data = {
    id: url.split('/')[7],
    name: noko.css('.page-header h1').text.tidy,
    faction: noko.css('.content a[href*="/fraktsioonid/"]').text.tidy,
    image: noko.css('.profile-photo img/@src').text,
    phone: noko.css('.icon-tel').xpath('../text()').text,
    email: noko.css('.icon-mail').xpath('../text()').text,
    source: url,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  puts data
  ScraperWiki.save_sqlite([:id], data)
end

members = Riigikogu::Liikmed.new('http://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/').as_data[:members]
members.each do |mp|
  scrape_mp(mp[:url])
end
