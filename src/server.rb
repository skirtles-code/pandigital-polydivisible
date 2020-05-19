# Start config
base = 46
initial_length = 2

port = 5678
# End config

require 'socket'

allowed_digits = []

1.upto(base - 1) do |n|
  allowed_digits[n] = {}
  gcd = n.gcd base

  1.upto(base - 1) do |m|
    if m.gcd(base) == gcd
      allowed_digits[n][m] = true
    end
  end
end

puts "Number of allowed digits (gcd filtering): #{allowed_digits.map {|k| k&.length}.join(', ')}"

starting_points = [[]]

while starting_points[0].length < initial_length
  new_starting_points = []
  position = starting_points[0].length + 1

  starting_points.each do |point|
    cumulative = 0

    point.each do |digit|
      cumulative = (cumulative + digit) * base
    end

    1.upto(base - 1) do |n|
      if allowed_digits[position][n] && (cumulative + n) % position == 0 && !point.include?(n)
        new_point = point.map {|m| m}
        new_point << n
        new_starting_points << new_point
      end
    end
  end

  starting_points = new_starting_points
end

puts "#{starting_points.size} #{initial_length}-digit starting points"

remaining_points = starting_points.map {|m| m}

point_status = {}
solutions = []

server = TCPServer.new port

loop do
  Thread.start(server.accept) do |session|
    request = session.gets

    unless request
      puts 'Closing empty request'
      session.close
      next
    end

    puts request

    method, full_path = request.split(' ')
    path, query = full_path.split('?')

    status = 404
    headers = { 'Content-Type': 'text/plain', 'Connection': 'close' }
    body = 'Not found'

    if path == '/next'
      status = 200
      body = ''

      while remaining_points.size > 0
        point = remaining_points.shift.join(',')

        if point_status[point] != 'done'
          body = "#{base}:#{point}"
          point_status[point] = 'allocated'
          break
        end
      end
    elsif path == '/done' && query
      point_status[query] = 'done'
      status = 200
      body = query
    elsif path == '/found' && query
      puts "Solution found! #{query}"
      solutions << query
      status = 200
      body = query
    elsif path == '/reallocate'
      status = 200
      body = 'Done'

      new_rp = remaining_points.map {|m| m}

      starting_points.each do |point|
        p = point.join(',')

        unless new_rp.include?(point) || point_status[p] == 'done'
          new_rp << point
          point_status[p] = 'pending reallocation'
        end
      end

      remaining_points = new_rp
    elsif path == '/'
      status = 200
      body = "Solutions:\r\n"

      solutions.each do |solution|
        body += "#{solution}\r\n"
      end

      body += "\r\n"
      body += "Progress:\r\n"
      body += "\r\n"

      allocated = 0
      done = 0

      starting_points.each do |point|
        st = point_status[point.join(',')] || ''

        allocated += 1 if st == 'allocated'
        done += 1 if st == 'done'

        unless ['done', ''].include? st
          body += point.join(', ') + ' - '
          body += st
          body += "\r\n"
        end
      end

      stats = "#{starting_points.size} #{initial_length}-digit starting points\r\n"
      stats += "#{allocated} allocated\r\n"
      stats += "#{done} done\r\n"
      stats += "#{((done + allocated / 2.0) * 10000 / starting_points.size).floor / 100.0}% complete\r\n\r\n"

      body = stats + body
    end

    begin
      session.print "HTTP/1.1 #{status}\r\n"

      headers.each do |key, value|
        session.print "#{key}: #{value}\r\n"
      end

      session.print "\r\n"

      session.print body

      session.flush

      session.close
    rescue Errno::EPIPE
      puts 'Attempting to rescue broken pipe'
      session.close
    end
  end
end
