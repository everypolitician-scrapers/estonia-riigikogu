#!/bin/env ruby
# encoding: utf-8

require 'pry'

Dir['.cache/www.riigikogu.ee/*.meta'].each do |f|
  saadik = File.readlines(f).find { |l| l.include? 'saadik' } or next

  orig = f.sub('.meta','')
  id = saadik.split('/')[5]
  filename = id + '.html'

  warn filename
  FileUtils.copy(orig, File.join('mirror', filename))
end
