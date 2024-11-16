require 'nokogiri'
require 'open-uri'
require 'robotex'
require 'set'

# Define a method to fetch and parse headlines
def fetch_headlines(url, css_selector, robotex)
  # Check if the URL allows crawling
  if robotex.allowed?(url)
    begin
      # Open the URL and parse its HTML
      document = Nokogiri::HTML(URI.open(url))

      # Track unique titles to avoid duplicates
      unique_titles = Set.new

      # Titles to exclude for New York Times
      excluded_titles = ['Wordle', 'Connections', 'Strands', 'Spelling Bee', 'The Crossword', 'The Mini Crossword']

      if url == 'https://www.nytimes.com'
        # Extract all sections containing headlines and descriptions
        document.css('div, section').each_with_index do |section, index|
          # Extract the title (first <p> with 'indicate-hover' class)
          title = section.at_css('p.indicate-hover')&.text&.strip

          # Extract the short description (first <p> with 'summary-class' class)
          short_description = section.at_css('p.summary-class')&.text&.strip

          # Skip excluded titles
          next if title && excluded_titles.include?(title)

          # Ensure the title is unique and print if both title and description are found
          if title && short_description && !unique_titles.include?(title)
            unique_titles.add(title)
            puts "Section #{unique_titles.size}:"
            puts "Title: #{title}"
            puts "Short Description: #{short_description}"
            puts "-" * 50
          end
        end
      else
        # Extract and print the headlines using the provided CSS selector
        headlines = document.css(css_selector)
        puts "Headlines from #{url}:"
        headlines.each_with_index do |headline, index|
          headline_text = headline.text.strip
          # Avoid duplicate headlines
          unless unique_titles.include?(headline_text)
            unique_titles.add(headline_text)
            puts "#{unique_titles.size}. #{headline_text}"
          end
        end
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
  'https://www.nytimes.com' => 'section'
}

# Fetch headlines from all websites
websites.each do |url, selector|
  fetch_headlines(url, selector, robotex)
end
