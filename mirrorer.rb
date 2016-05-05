#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'pry'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def mirror(url, local)
  safe_url = URI.escape(URI.unescape(url))
  warn safe_url

  html = open(safe_url).read
  File.write(File.join('mirror', local), html)
  Nokogiri::HTML(html)
end

people = mirror('http://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/', 'liikmed.html')
people.css('ul.profile-list li.item h3 a/@href').map(&:text).each do |url|
  id = url.split('/')[7]
  mirror(url, id + '.html')
end
