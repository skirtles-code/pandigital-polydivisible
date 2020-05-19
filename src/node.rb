# Start config
host = 'localhost'
port = 5678
# End config

require 'net/http'

@base_url = "http://#{host}:#{port}/"

def get_with_retries (url)
  uri = URI("#{@base_url}#{url}")

  response = nil
  try_again = true

  while try_again
    begin
      response = Net::HTTP.get(uri)
      try_again = false
    rescue => ex
      puts "#{ex.class}: #{ex.message}"
      sleep 10
    end
  end

  response
end

def poly_for(base, starting_point)
  allowed_digits = []

  1.upto(base - 1) do |n|
    allowed_digits[n] = [false] * base
    gcd = n.gcd base

    1.upto(base - 1) do |m|
      if m.gcd(base) == gcd
        allowed_digits[n][m] = true
      end
    end
  end

  digits = starting_point.map {|digit| digit}
  cumulative = [0]
  cumulative_bases = [0]
  used_digits = [false] * base

  accumulator = 0

  digits.each do |digit|
    accumulator = accumulator * base + digit
    cumulative << accumulator
    cumulative_bases << accumulator * base
    used_digits[digit] = true
  end

  position = starting_point.size + 1

  digits << -(cumulative_bases[position - 1] % position)

  while position != starting_point.size
    current = digits[position - 1]
    used_digits[current] = false if current > 0

    while current < base
      current += position # position tells us the current target divisor, so jump in multiples of it

      if allowed_digits[position][current] && !used_digits[current]
        break
      end
    end

    if current >= base
      position -= 1
      digits[position] = nil

      next
    end

    digits[position - 1] = current
    used_digits[current] = true

    if position == base - 1
      puts "*********************** #{digits.join(', ')} ***********************"

      get_with_retries("found?#{digits.join(',')}")

      next
    end

    cumulative[position] = cumulative_bases[position - 1] + current
    cb = cumulative_bases[position] = cumulative[position] * base

    position += 1

    # This will be negative, so the next loop round will increase to the actual lowest value
    next_digit = -(cb % position)

    # No need to add this to used_digits as it will be non-positive
    digits[position - 1] = next_digit
  end

  get_with_retries("done?#{starting_point.join(',')}")
end

while true
  response = get_with_retries 'next'

  if response && response.length > 1
    base, digits = response.split(':')
    base = base.to_i
    digits = digits.split(',').map {|n| n.to_i}

    puts "Checking #{digits}"
    poly_for base, digits
    puts "Finished checking #{digits}"
  else
    sleep 10
  end
end
