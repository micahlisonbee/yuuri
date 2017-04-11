class YuuriServer
  @@temp_file_path = '/home/pi/yeti-pi/tmp/receipt.txt'
  @@config_file_path = '/home/pi/yeti-pi/config.yml'
  def listen
    File.write(@@temp_file_path, '')

    # params for serial port
    port_str = '/dev/ttyUSB0' # may be different for you
    baud_rate = 38_400
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE

    sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

    loop do
      while (i = sp.gets)
        puts i

        count = `wc -l #{@@temp_file_path}`.split.first.to_i
        if count.zero?
          puts 'Starting new transaction ...'
          Thread.new do
            sleep 10
            close_transaction
          end
        end

        open(@@temp_file_path, 'a') do |f|
          f << i
        end

      end
    end

    sp.close
  end

  def close_transaction
    puts 'Closing transaction ...'
    file = File.open(@@temp_file_path, 'rb')
    contents = file.read
    puts '-------- Begin File Data --------'
    puts contents
    puts '--------- End File Data ---------'

    config_file = YAML.load_file(@@config_file_path)
    puts "THE CONFIG FILE: #{config_file}"

    begin
      api_url = config_file['api_url']
      url_string = "https://#{config_file['api_url']}/transactions"
      puts "THE URL IS: #{url_string}"
      response = RestClient.post url_string, receipt: contents, company_id: 1, location_id: 1, yuuri_id: 1
      puts "THE RESPONSE IS: #{response}"
    rescue => e
      puts "Error sending data: #{e}"
    end

    File.write(@@temp_file_path, '')
    puts 'Transaction closed'
  end
end

server = YuuriServer.new
server.listen

# File.write(temp_file_path, "")
