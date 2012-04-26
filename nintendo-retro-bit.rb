#!/usr/bin/env ruby 
require 'usb'
require 'pp'

# This is an example of reading input from an NES controller throught the RetroBit USB adapter. At the moment, the device seems pretty flakey. However, it could just be the old controllers that are causing the issue.

byte_format = "C*"
vendor_id = 0x1292
product_id = 0x4643

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

  prev = [0,0]
  loop do
    begin
      h.usb_bulk_read(endpoint, data, 10)
      state = data.unpack(byte_format)
      if (prev != state)
        actions.each { |a| a.call(state) }
        pp state
        prev = Array.new(state)
      end
    rescue Errno::ETIMEDOUT => e
    rescue Interrupt
      exit 130
    end
  end

}
