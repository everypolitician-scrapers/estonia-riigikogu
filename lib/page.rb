# frozen_string_literal: true
require 'field_serializer'
require 'nokogiri'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

class Riigikogu
  class Page
    include FieldSerializer

    def initialize(url)
      @url = url
    end

    def noko
      warn "Loading #{url}"
      @noko ||= Nokogiri::HTML(open(url).read)
    end

    private

    attr_accessor :url

    def at_css(selector, h = {})
      _at_selector(h.merge(selector_type: 'css', selector: selector))
    end

    def at_xpath(selector, h = {})
      _at_selector(h.merge(selector_type: 'xpath', selector: selector))
    end

    def _at_selector(h)
      start_node = h[:scope] || noko
      start_node.send(h[:selector_type], h[:selector]).map(&:text).map(&:tidy).join(';')
    end

    def absolute_link(rel)
      return if rel.to_s.empty?
      URI.join(url, URI.encode(URI.decode(rel)))
    end
  end
end
