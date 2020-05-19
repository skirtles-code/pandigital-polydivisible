# Start config
base = 32

max_length = base - 1
# End config

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

puts "Number of allowed digits (gcd filtering): #{allowed_digits.map {|k| k && k.count(true)}.join(', ')}"

digits = [0]
cumulative = [0]
cumulative_bases = [0]
position = 1
used_digits = [false] * base

counts = [0] * max_length

while position != 0
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

    if position == 1
      puts "Checked first digit #{digits[0]}"
    end

    next
  end

  digits[position - 1] = current

  counts[position - 1] += 1

  if position == max_length
    next
  end

  used_digits[current] = true

  cumulative[position] = cumulative_bases[position - 1] + current
  cb = cumulative_bases[position] = cumulative[position] * base

  position += 1

  # This will be negative, so the next loop round will increase to the actual lowest value
  next_digit = -(cb % position)

  # No need to add this to used_digits as it will be non-positive
  digits[position - 1] = next_digit
end

puts counts.join(', ')
