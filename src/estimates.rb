def estimates(even_base)
  # We have 1 candidate of length 0
  est = [1]
  gcd_counts = [0] * even_base

  1.upto(even_base - 1) do |n|
    gcd = n.gcd even_base
    gcd_counts[gcd] += 1
  end

  1.upto(even_base - 2) do |n|
    gcd = n.gcd even_base

    denominator = n / gcd
    factor = gcd_counts[gcd].quo denominator

    est << est.last * factor

    gcd_counts[gcd] -= 1
  end

  # The final digit always works assuming base is even
  est << est.last

  est
end

# This calculates the expected number of PPNs for a given base.
# The base must be semi-prime as the algorithm uses several shortcuts that only apply in that case.
# The returned value is log2 of the actual estimate.
def estimate_log2(semi_prime_base)
  est = 0
  even = (semi_prime_base / 2) - 1
  odd = (semi_prime_base / 2) - 1
  midpoint = semi_prime_base / 2

  1.upto(semi_prime_base - 2) do |n|
    if n == midpoint
      factor = 1
    elsif n % 2 == 0
      factor = even.quo(n / 2)
      even -= 1
    else
      factor = odd.quo(n)
      odd -= 1
    end

    est += Math.log2(factor)
  end

  est
end

puts 'Expected number of candidate PPNs of different lengths, base 56'
puts estimates(56).map {|est| est * 1.0}.join(', ')
puts

expected_counts = (1..100).map do |k|
  estimates(k * 2).last * 1.0
end

puts 'Expected number of PPNs for even bases 2 to 200:'
puts expected_counts.join(', ')
puts

puts 'Assuming equation: y = c * (base ^ v) * (w ^ base)'
puts 'Calculating an estimate for w, please wait...'

# You can change these values if you wish, however...
# - All three values must be 2 * prime.
# - The first two values must be close together for the calculation of w to make sense.
# - The third value should be a long way from the other two, preferably a different order of magnitude, to calculate v.
base_2000074 = 2_000_074
base_2000078 = 2_000_078
base_20000038 = 20_000_038

log_y_2000074 = estimate_log2(base_2000074)
log_y_2000078 = estimate_log2(base_2000078)

# Divide and take logs:
#
# log(y_2000078) - log(y_2000074) = v * log(2000078 / 2000074) + (2000078 - 2000074) * log(w)
#
# As log(2000078 / 2000074) is tiny we assume that disappears, giving:

log_w = (log_y_2000078 - log_y_2000074) / (base_2000078 - base_2000074)

# Logs were taken to base 2....
w = 2 ** log_w

puts "w = #{w}"

puts "Which is very close to sqrt(0.5) = #{Math.sqrt(0.5)}"
puts "Let's assume that w is actually sqrt(0.5)"

puts 'Calculating v'

log_y_20000038 = estimate_log2(base_20000038)

# Using the same formula as the previous calculation but for different bases:
#
# log(y_20000038) - log(y_2000074) = v * log(20000038 / 2000074) + (20000038 - 2000074) * log(w)
#
# This time log(20000038 / 2000074) is about 3, so it doesn't disappear. We know log(w) = -0.5, giving:

v = (log_y_20000038 - log_y_2000074 + 0.5 * (base_20000038 - base_2000074)) / (Math.log2(base_20000038) - Math.log2(base_2000074))

puts "v = #{v}"
puts "Let's assume that v is actually 1.5"

log_c = log_y_20000038 - 1.5 * Math.log2(base_20000038) + 0.5 * base_20000038

c = 2 ** log_c

puts "c = #{c}"
puts "Now observe that: 2 * c * c = #{2 * c * c}"
