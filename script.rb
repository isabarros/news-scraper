require 'nokogiri'
require 'open-uri'
require 'robotex'

# Define a method to fetch and parse headlines
def fetch_headlines(url, css_selector, robotex)
  # Check if the URL allows crawling
  if robotex.allowed?(url)
    begin
      # Open the URL and parse its HTML
      document = Nokogiri::HTML(URI.open(url))
      # Extract and print the headlines using the provided CSS selector
      headlines = document.css(css_selector)
      puts "Headlines from #{url}:"
      headlines.each_with_index do |headline, index|
        puts "#{index + 1}. #{headline.text.strip}"
      end
    rescue StandardError => e
      puts "Error fetching from #{url}: #{e.message}"
    end
  else
    puts "Scraping not allowed for #{url} as per robots.txt."
  end
  puts "\n"
end

# Initialize Robotex
robotex = Robotex.new

# List of websites with their respective headline CSS selectors
websites = {
  'https://www.cnn.com' => 'h3.cd__headline a',
  'https://www.bbc.com' => 'h3.media__title a',
  'https://www.nytimes.com' => 'h2.css-1vvhd4r' # Example selector for NYT
}

# Fetch headlines from all websites
websites.each do |url, selector|
  fetch_headlines(url, selector, robotex)
end
