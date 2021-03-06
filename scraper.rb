#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'require_all'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

# require 'scraped_page_archive/open-uri'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

url = 'https://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/'
page = Riigikogu::Members.new(response: Scraped::Request.new(url: url).response)

warn "Found #{page.members.count} members"
data = page.members.map do |member|
  Riigikogu::Member.new(response: Scraped::Request.new(url: member.url).response).to_h
end
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:id], data)
