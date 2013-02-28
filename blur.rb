require 'json'
require 'logger'
require 'sinatra'
require 'ffi'

# Make our POST data limits really big to accomodate the image data
# serialized to JSON
Rack::Utils.key_space_limit = 1000000

get '/' do
  redirect '/index.html'
end

post '/blur/ruby' do
  blur { |w, h, d| blur_ruby(w, h, d) }
end

post '/blur/rust' do
  blur { |w, h, d| blur_rust(w, h, d) }
end

def blur
  msg = request.body.read
  msg = JSON.parse msg

  width = msg['width']
  height = msg['height']
  data = msg['data']

  if (data.length != width * height)
    return
  end

  start_time = Time.now()
  newdata = yield(width, height, data)
  end_time = Time.now() - start_time
  logger.info end_time

  response = { :data => newdata, :time => end_time }
  JSON.generate(response)
end

def blur_ruby(width, height, data)

  filter = [[0.011, 0.084, 0.011],
            [0.084, 0.619, 0.084],
            [0.011, 0.084, 0.011]]

  newdata = []             

  # Iterate through the pixels of the image
  (0...height).each do |y|
    (0...width).each do |x|
      new_value = 0
      # Iterate through the values in the filter
      (0...filter.length).each do |yy|
        (0...filter.length).each do |xx|
          x_sample = x - (filter.length - 1) / 2 + xx
          y_sample = y - (filter.length - 1) / 2 + yy
          sample_value = data[width * (y_sample % height) + (x_sample % width)]
          weight = filter[yy][xx]
          new_value += sample_value * weight
        end
      end
      newdata[width * y + x] = new_value
    end
  end

  newdata
end

def blur_rust(width, height, data)
  packed_data = data.pack("C*")
  raw_data = FFI::MemoryPointer.from_string(packed_data)
  RustBlur.blur(width, height, raw_data)
  
  raw_data.get_bytes(0, width * height).unpack("C*")
end

module RustBlur
  extend FFI::Library
  ffi_lib 'libblur-68a2c114141ca-0.0'

  attach_function :blur, :blur, [ :uint, :uint, :pointer ], :void
end
