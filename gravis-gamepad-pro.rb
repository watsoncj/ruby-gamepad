#!/usr/bin/env ruby 
require 'usb'

dev = USB.devices.select{|d| d.idVendor==0x0428 && d.idProduct==0x4001}.first
dev.open { |h| 

  h.usb_detach_kernel_driver_np(0,0) rescue nil
  data = (0..3).to_a.pack("C*")
  endpoint = dev.endpoints.first.bEndpointAddress

  # clear anything in the buffer
  loop do
    begin
      size = handle.usb_interrupt_read(endpoint, data, -1)
    rescue
      break
    end
  end

  actions = Array.new
  actions << Proc.new { |state| print 'left'   if state[0] == 0x00 }
  actions << Proc.new { |state| print 'right'  if state[0] == 0xFF }
  actions << Proc.new { |state| print 'up'     if state[1] == 0x00 }
  actions << Proc.new { |state| print 'down'   if state[1] == 0xFF }
  actions << Proc.new { |state| print 'red'    if (state[2] & 0x01) == 0x01 }
  actions << Proc.new { |state| print 'yellow' if (state[2] & 0x02) == 0x02 }
  actions << Proc.new { |state| print 'green'  if (state[2] & 0x04) == 0x04 }
  actions << Proc.new { |state| print 'blue'   if (state[2] & 0x08) == 0x08 }
  actions << Proc.new { |state| print 'l1'     if (state[2] & 0x10) == 0x10 }
  actions << Proc.new { |state| print 'r1'     if (state[2] & 0x20) == 0x20 }
  actions << Proc.new { |state| print 'l2'     if (state[2] & 0x40) == 0x40 }
  actions << Proc.new { |state| print 'r2'     if (state[2] & 0x80) == 0x80 }
  actions << Proc.new { |state| print 'select' if (state[3] & 0x01) == 0x01 }
  actions << Proc.new { |state| print 'start'  if (state[3] & 0x02) == 0x02 }

  loop do
    begin
      h.usb_bulk_read(endpoint, data, 10)
      state_array = data.unpack("C*")
      #pp state_array
      actions.each { |a| a.call(state_array) }
    rescue Errno::ETIMEDOUT => e
    rescue Interrupt
      exit 130
    end
  end

}
