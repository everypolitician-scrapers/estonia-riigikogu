#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'require_all'
require 'scraperwiki'

require_rel 'lib'

require 'scraped_page_archive/open-uri'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

liikmed = Riigikogu::Members.new('http://www.riigikogu.ee/riigikogu/koosseis/riigikogu-liikmed/').to_h
warn liikmed
liikmed[:members].to_a.each do |member|
  data = Riigikogu::Member.new(member[:url]).to_h
  ScraperWiki.save_sqlite([:id], data)
end
