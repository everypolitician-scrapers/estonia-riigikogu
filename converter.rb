#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'colorize'
require 'json'
require 'pry'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(page)
  Nokogiri::HTML(open(page).read)
end

def members(page)
  noko = noko_for(page)
  date = noko.to_html[/Cached page generated on (.*) --/, 1]

  members = noko.css('ul.profile-list li.item').map do |mem|
    content = mem.css('div.content')
    data = {
      id:          content.css('h3 a/@href').text.split('/')[7],
      name:        content.css('h3').text.tidy,
      source:      content.css('h3 a/@href').text,
      faction:     content.css('li strong').text.tidy,
      commissions: content.css('li a[href*="/komisjonid/"]').map { |a| { name: a.text.tidy, link: a.attr('href') } },
      email:       content.css('li a[href*="mailto:"]').text.tidy,
      img:         mem.css('.photo img/@src').text,
    }
  end

  {
    date:    date,
    members: members,
  }
end

data = members('mirror/liikmed.html')
File.write('parsed/liikmed.json', JSON.pretty_generate(data))
