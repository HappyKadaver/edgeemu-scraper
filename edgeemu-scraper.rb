#!/urb/bin/env ruby

require 'uri'
require 'open-uri'
require 'nokogiri'

DOWNLOAD_URL = 'https://edgeemu.net/download.php?id='
HOST = 'https://' + URI.parse(DOWNLOAD_URL).host + '/'

def main
  if ARGV.length < 1
    puts "Wrong number of arguments #{ARGV.length} expected 1 or more"
    print_help
    exit 1
  end

  if ARGV.include? '--help' or ARGV.include? '-h'
    print_help
    exit 0
  end

  rom_overviews = get_rom_overviews ARGV[0]
  roms = get_roms_with_names rom_overviews
  roms = select_roms_by_country(roms, ARGV[1..-1])

  puts roms.map { |rom| "#{DOWNLOAD_URL}#{rom[:id]}"}
end

def select_roms_by_country(roms, countries)
  return roms if countries.empty?

  countries = countries.map &:downcase

  roms.select do |rom|
    countries.length != (countries - rom[:countries]).length
  end
end

def get_roms_with_names(overview_urls)
  id_regex = /https:\/\/edgeemu.net\/details-(\d+)\.htm/
  result = []

  overview_urls[0..0].each do |url|
    STDERR.puts "Loading roms from: #{url}"
    sleep 2

    doc = Nokogiri::HTML(open(url))

    elements = doc.css('table.roms a')

    elements.each do |element|
      countries = extract_countries_from_rom_name element.text
      url = "#{HOST}#{element['href']}"
      id = id_regex.match(url)[1]


      result << {
          url: url,
          id: id,
          name: element.text,
          countries: countries
      }
    end
  end

  result
end

def extract_countries_from_rom_name(rom_name)
  regex = /\(([^(]+)\)\s*$/
  countries = []

  match = regex.match rom_name

  while match
    countries << match[1].downcase
    rom_name.gsub! match[0], ''
    match = regex.match rom_name
  end

  countries
end

def get_rom_overviews(url)
  doc = Nokogiri::HTML(open(url))
  doc.css('div#content > p[align=center] a').map { |a| "#{HOST}#{a['href']}" }
end

def print_help
  puts "Usage #{$PROGRAM_NAME} <edgeemu.net system overview url> [country1 country2...]"
  puts "Example #{$PROGRAM_NAME} https://edgeemu.net/browse-snes.htm Europe Germany"
end

main