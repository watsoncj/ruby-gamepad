#!/usr/bin/env ruby 
require 'usb'
require 'pp'

byte_format = "C*"
vendor_id = 0x1292
product_id = 0x4643

@@prev = [0,0]
@@prev_n = []
@@counts = Hash.new

def debounce(state) 
    if @@prev_n.size >= 5
      old = @@prev_n.delete_at(0)
      @@counts[old] = @@counts[old] - 1 
    end
    @@prev_n << state


    if @@counts[state]
      @@counts[state] = @@counts[state]+1
    elsif
      @@counts[state] = 1
    end

    return @@counts.invert.max.last
end

dev = USB.devices.select{|d| d.idVendor==vendor_id && d.idProduct==product_id}.first
fail "no device detected" unless dev

puts "device found"
dev.open { |h| 
  puts "device opened"

  h.usb_detach_kernel_driver_np(0,0) rescue nil
  data = [0,0].pack(byte_format)
  endpoint = dev.endpoints.first.bEndpointAddress

  actions = Array.new
  actions << Proc.new { |state| print 'left'   if state[0] == 0x06 }
  actions << Proc.new { |state| print 'right'  if state[0] == 0x05 }
  actions << Proc.new { |state| print 'up'     if state[0] == 0x0F }
  actions << Proc.new { |state| print 'down'   if state[0] == 0x04 }
  actions << Proc.new { |state| print 'A'       if state[1] == 0x03 }
  actions << Proc.new { |state| print 'B'       if state[1] == 0x02 }
  actions << Proc.new { |state| print 'Start'   if state[1] == 0x08 }
  actions << Proc.new { |state| print 'Select'  if state[1] == 0x04 }

  loop do
    begin
      h.usb_bulk_read(endpoint, data, 10)
      state = data.unpack(byte_format)
      most_common_state = debounce(state)
      if (most_common_state != @@prev)
        actions.each { |a| a.call(most_common_state) }
        pp most_common_state
        prev = Array.new(most_common_state)
      end
    rescue Errno::ETIMEDOUT => e
    rescue Interrupt
      exit 130
    end
  end

}


