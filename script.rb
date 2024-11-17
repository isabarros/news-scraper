require 'nokogiri'
require 'open-uri'
require 'robotex'
require 'set'
require 'mail'
require 'letter_opener'
require 'dotenv'

# Load environment variables from .env file
Dotenv.load

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

      # String to hold all the headlines
      headlines_output = ""

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
            headlines_output += "Section #{unique_titles.size}:\n"
            headlines_output += "Title: #{title}\n"
            headlines_output += "Short Description: #{short_description}\n"
            headlines_output += "-" * 50 + "\n"
          end
        end
      else
        # Extract and print the headlines using the provided CSS selector
        headlines = document.css(css_selector)
        headlines_output += "Headlines from #{url}:\n"
        headlines.each_with_index do |headline, index|
          headline_text = headline.text.strip
          # Avoid duplicate headlines
          unless unique_titles.include?(headline_text)
            unique_titles.add(headline_text)
            headlines_output += "#{unique_titles.size}. #{headline_text}\n"
          end
        end
      end

      # Send the collected headlines to email
      send_email(headlines_output)

    rescue StandardError => e
      puts "Error fetching from #{url}: #{e.message}"
    end
  else
    puts "Scraping not allowed for #{url} as per robots.txt."
  end
  puts "\n"
end

# Email sending function
def send_email(body)
  Mail.defaults do
    if ENV['ENV'] == 'development'
      puts "Email content for development environment:"
      puts "Subject: Latest Headlines"
      puts body

      # In development, use letter_opener to preview emails in the browser
      delivery_method LetterOpener::DeliveryMethod, location: File.expand_path('../tmp/letter_opener', __FILE__)
  else
      # In other environments, use SMTP
      delivery_method :smtp, {
        address: 'smtp.mailgun.org',
        port: 587,
        domain: ENV['DOMAIN'],
        user_name: ENV['EMAIL_ADDRESS'],  # Using environment variable for email
        password: ENV['EMAIL_PASSWORD'],  # Using environment variable for password
        authentication: 'plain',
        enable_starttls_auto: true
      }
    end
  end

  mail = Mail.new do
    from     ENV['EMAIL_ADDRESS']        # Using environment variable for from address
    to       ENV['RECIPIENT_EMAIL']      # Using environment variable for recipient email
    subject  'Latest Headlines'
    body     body
  end

  mail.deliver!
  puts "Email sent successfully!"
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
