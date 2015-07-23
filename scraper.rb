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

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('ul.profile-list li.item h3 a/@href').map(&:text).each do |link|
    scrape_mp(URI.escape link)
  end
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

scrape_list('http://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/')
