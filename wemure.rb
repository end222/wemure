require 'faraday'
require "json"
require 'net/smtp'

$future_releases = []
$email = ""
$from = ""

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

def send_future_releases()
  message = <<MESSAGE_END
From: #{$from}
To: #{$email}
Subject: Weekly Music Releases

Weekly Music Releases
MESSAGE_END

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message message, $from, $email
  end
end

artist_ids = read_config_file()
time = Time.new
date = time.year * 10000 + time.month * 100 + time.day

artist_ids.each {
  |id| data = make_request(id)
  data["release-groups"].each {
    |release| release_date = release["first-release-date"].tr('-', '').to_i
    puts release["title"] + " - " + release["first-release-date"].tr('-', '')
    if release_date >= date
      $future_releases += [{ name: release["title"], date: release_date, artist: data["name"], format: release["primary-type"]}]
    end
  }
}
puts "Future releases"
puts $future_releases
send_future_releases()
