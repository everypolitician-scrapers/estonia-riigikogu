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

require 'singleton'
module ScraperArchive
  class GitBranchCache
    include Singleton

    attr_writer :github_repo_url

    def cache_response(url)
      clone_repo_if_missing!
      Dir.chdir(archive_directory) do
        create_or_checkout_archive_branch!
        OpenURI::Cache.cache_path = archive_directory
        response = yield(url)
        message = "#{response.status.join(' ')} #{url}"
        system("git add .")
        system("git commit --allow-empty --message='#{message}'")
        system("git push origin #{branch_name}")
        response
      end
    end

    def clone_repo_if_missing!
      unless File.directory?(archive_directory)
        warn "Cloning archive repo into /tmp"
        system("git clone #{github_repo_url} #{archive_directory}")
      end
    end

    def create_or_checkout_archive_branch!
      if system("git rev-parse --verify #{branch_name} > /dev/null 2>&1")
        system("git checkout --quiet -B #{branch_name}")
      else
        system("git checkout --orphan #{branch_name}")
        system("git rm --quiet -rf .")
      end
    end

    def github_repo_url
      @github_repo_url ||= ENV['MORPH_SCRAPER_CACHE_GITHUB_REPO_URL']
    end

    # TODO: This should be configurable
    def refresh_cache?
      true
    end

    # TODO: This should be configurable
    def archive_directory
      @archive_directory ||= '/tmp/scraper-archive'
    end

    # TODO: This should be configurable
    def branch_name
      @branch_name ||= 'scraped-pages-archive'
    end
  end
end

ScraperArchive::GitBranchCache.instance.github_repo_url = 'https://github.com/tmtmtmtm/estonia-riigikogu'

module OpenURI
  class << self
    alias __open_uri open_uri
    def open_uri(url, *args)
      ScraperArchive::GitBranchCache.instance.cache_response(url) do |*open_uri_args|
        __open_uri(*open_uri_args)
      end
    end
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
