This is the supporting code for the article
[Pandigital Polydivisible Numbers](https://skirtlesden.com/articles/pandigital-polydivisible-numbers).

There are 5 Ruby files in `src`. These should have no dependencies apart from Ruby itself. Each is a standalone file 
that can be run in isolation.

If you have Ruby installed then any of these scripts can be run directly from the command line. e.g.

```text
> cd src
> ruby ppn-search.rb
```

Below is a brief introduction to what each file contains and how to configure it.

### ppn-search.rb

`ppn-search.rb` will generate a list of PPNs for all even bases from 2 to 44. The range can easily be changed but
larger bases will usually take longer to check.

Within the default range, the values 34, 38, 42 and 44 will take the longest time to complete. The time taken for 34
and 42 should be about the same and will likely be under a minute depending on hardware. For 38 it will take about 10
times as long and for 44 it'll be slightly more.

### server.rb and node.rb

A distributed search using `server.rb` and `node.rb` allows for searching in higher bases by spreading the load across
multiple CPUs or even multiple computers.

Configuration options are at the top of each file. The nodes use HTTP to talk to the server, requesting details of what
search to perform next. When a search is completed the results are sent back to the server via another HTTP request.

When a node requests details of the next search it will be sent the base and the first few digits of the potential PPN.
The node will then check all suitable combinations for the remaining digits. 

`server.rb` should be configured with the desired base. The setting `initial_length` is then used to determine how many
digits to send to the nodes each time they request a new search. Usually between 2 and 4 is suitable. If the value is
too large the search will be broken up into too many, tiny pieces. If the value is too small it will be broken up into
large chunks that each take a long time to check. Ideally a node should spend several seconds or minutes checking a
particular start point. Some trial and error is required when setting up a cluster to get this setting correct.

`node.rb` needs to be configured with the `host` and `port` of the server. If you're running both on the same machine
then the defaults should be fine. If you want to run nodes on separate machines you'll need to use a suitable IP address
or hostname. For maximum throughput you should aim for one node per processor. Use the process monitoring tools
available on your platform (e.g. `top` or `Task Manager`) to check that you're making the best use of the available
capacity.

If you need to send requests to the server manually it is recommended that you use a command-line tool like cURL. All
requests are `GET` requests, even those that modify server state. Web browsers will often prefetch URLs that you've
visited before so it's safest to avoid using a web browser to make these requests.

As searches can take a long time it's likely that at some point there'll be a problem. The nodes will retry HTTP
requests indefinitely if they fail. Putting computers to sleep mid-way through a search should be harmless though you
should probably confirm this at the start of a search and not several days in. If a node is stopped while it's
performing a search then the server should be sent a `reallocate` request, e.g. `http://localhost:5678/reallocate`. As
the name suggests, this tells the server that one of the searches has been dropped and should be reallocated to a
different node. There's no need to tell the server precisely which search was lost.

To check progress you can send a request to `http://localhost:5678/`, or whatever host and port combination you're using
for the server.

The code is cheap and cheerful. Using `GET` requests for state-changing actions is just the tip of the worst-practices
iceberg. There's also precious little validation on the data within a request. It isn't even using a proper HTTP server,
just some nonsense cobbled together using sockets. `server.rb` and `node.rb` are written to find PPNs, they won't stand
up to much scrutiny beyond that.

### partial-counts.rb

`partial-counts.rb` counts how many numbers successfully pass all the constraints as the length of the numbers is
increased. The final count in the array should be how many PPNs there are for the specified base.

These numbers are used to populated the 'real' line on the first chart in the article.

As well as configuring the desired base it is also possible to configure `max_length`. This will truncate the search at
a particular number of digits. While this hasn't been used in the article, it allows for the real values and the
estimated values to be compared for larger bases. However, the most interesting part of such a comparison is usually
around the peak, which involves doing most of the work of the full search.

The code is very similar to `ppn-search.rb` and the two could probably be merged without any significant performance
impact.

### estimates.rb

`estimates.rb` attempts to estimate the same values generated by `partial-counts.rb`. These estimates are much quicker
to calculate than the real counts and can be used to investigate much larger bases.

It outputs several examples:

1. The first chart in the article shows estimates for even bases 10 to 56. The script will output the values for
   base 56. Adjust accordingly if you want values for other bases.
2. Next it outputs the final estimates for bases 2 to 200. This is what's shown in the second chart.
3. Next it runs through the calculations used to generate the formula of the yellow line on the second chart. This
   process can be adjusted to use different bases in the calculations. Comments in the code outline the requirements for
   choosing suitable bases.

---

Copyright &copy; 2020 skirtle - skirtlesden.com
