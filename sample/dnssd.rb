# using the dnssd library to find running, local QLab instances

require 'rubygems'
require 'dnssd'

Thread.abort_on_exception = true

def row label, record
  puts "%-12s%s" % [label, record.send(label)]
end

def do_browse_on_service(b)
  DNSSD.resolve b.name, b.type, b.domain do |r|
    puts '*' * 40
    puts "FOUND QLAB:"

    puts
    puts '-- machine --'
    row :name, b
    row :type, b
    row :domain, b
    row :interface, b

    puts
    puts '-- resolved domain --'
    row :target, r
    row :port, r
    row :target, r
    puts '*' * 40
  end

end

browsers = []

browsers.push(DNSSD.browse('_qlab._udp.') do |b|
  do_browse_on_service(b)
  sleep 2
end)

# browsers.push(DNSSD.browse('_qlab._tcp.') do |b|
#   do_browse_on_service(b)
# end)

trap 'INT' do
  browsers.map(&:stop);
  exit
end

trap 'TERM' do
  browsers.map(&:stop);
  exit
end

sleep
