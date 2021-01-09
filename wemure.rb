require 'faraday'
require "json"
require 'net/smtp'

$future_releases = []
$email = ""
$from = ""

# Make a request to the MusicBrainz API to get the artist's releases
def make_request(artist_id)
  base_url = "https://musicbrainz.org/ws/2/artist/"
  query_options = "?inc=release-groups&fmt=json"
  successful_request = false

  # Forge full request string
  full_request_url = base_url + artist_id + query_options

  while(!successful_request)
    resp = Faraday.get(full_request_url, { 'User-Agent' => 'anonymous' })
    if resp.status == 200
      successful_request = true
    else
      # API rate may be saturated, sleep a couple seconds before retry
      # With out User Agent (anonymous) we are allowed 50 requests per second
      sleep(2)
    end
  end

  data = JSON.parse(resp.body)
  return data
end

# Read the configuration options present in the file located in:
# /etc/wemure.conf
# The syntax of the file is explained in the Readme
def read_config_file()
  artist_ids = []
  File.open("/etc/wemure.conf", "r") do |file|
    file.each_line do |line|
      line = line.sub(/#.*$/, '')
      line_splitted = line.split(' ')
      case line_splitted[0]
      when "email"
        $email = line_splitted[1]
      when "from"
        $from = line_splitted[1]
      when "id"
        artist_ids += [line_splitted[1]]
      end
    end
  end
  return artist_ids
end

# Send an email to the user with the newest releases
# The next week will be separated from the rest of the releases
def send_future_releases(todays_date)
  # Change to true whenever the weekly releases have been added to the message
  # After changing the value to true, 
  finished_weekly_releases = false
  message = "From: #{$from}\n"
  message += "To: #{$email}\n"
  message += "Subject: Weekly Music Releases\n"

  if $future_releases.length() == 0
    message += "Sadly, there's no new music comming from your favorite artists.\n"
    message += "You may want to add more artists to your configuration file.\n"
  else
    if $future_releases[0][:date] - todays_date >= 7
      finished_weekly_releases = true
      message += "There's no new music coming out this week.\n"
      message += "\n"
      message += "Future releases:\n"
    else
      message += "\n"
      message += "Music that will be released this week:\n"
    end
    $future_releases.each {
      |release| if !finished_weekly_releases and release[:date] - todays_date >= 7
        finished_weekly_releases = true
        message += "\n"
        message += "Future releases:\n"
      end
        date = release[:date].to_i
        message += (date % 100).to_s + "/" + (date / 100 % 100).to_s + "/" + (date / 10000).to_s
        message += " \"" + release[:name] + "\" " + release[:format] + " by " + release[:artist]
        message += "\n"
    }
  end

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, $from, $email
  end
end

# Get an array of the MusicBrainz IDs of the artists
artist_ids = read_config_file()

# Get current date
time = Time.new
todays_date = time.year * 10000 + time.month * 100 + time.day

artist_ids.each {
  |id| data = make_request(id)
  data["release-groups"].each {
    |release| release_date = release["first-release-date"].tr('-', '').to_i
    if release_date >= todays_date
      $future_releases += [{ :name => release["title"], :date => release_date,
                             :artist => data["name"], :format => release["primary-type"]}]
    end
  }
}
$future_releases.sort_by!{ |hsh| hsh[:zip] }
send_future_releases(todays_date)
