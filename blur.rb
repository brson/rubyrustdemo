require 'json'
require 'logger'
require 'sinatra'
require 'base64'
require 'matrix'
require 'ffi'
require 'RMagick'

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

  data = translate_image_data(width, height, data)

  newdata = blur_ruby(width, height, data)

  response = { :data => newdata }
  JSON.generate(response)
end

def translate_image_data(width, height, data)
  logger.info data
  image = data.split(',')
  image = Base64.decode64(image[1])

  ilist = Magick::ImageList.new
  ilist.from_blob(image)
  ilist.display

  Array.new(width * height) { 0 }
end

def blur_ruby(width, height, data)

  def pixel(width, height, data, x, y)
    data[width * (y % height) + (x % width)]
  end

  mat = Matrix.rows([[0.1, 0.1, 0.1],
                     [0.1, 0.2, 0.1],
                     [0.1, 0.1, 0.1]])

  newdata = []

  0.upto (height - 1) do |y|
    0.upto (width - 1) do |x|
      # Calculate the pixel value
      total = 0
      0.upto mat.row_size - 1 do |yy|
        0.upto mat.column_size - 1 do |xx|
          pixel_value = pixel(width, height, data,
                              x - (mat.row_size - 1) / 2 + xx,
                              y - (mat.column_size - 1) / 2 + yy)
          pixel_value = pixel_value * mat[yy, xx]
          total = total + pixel_value
        end
      end
      newdata[width * y + x] = total
    end
  end

  newdata
end

def old_blur_ruby(width, height, data)
  newdata = []
  0.upto (height - 1) do |y|
    0.upto (width - 1) do |x|
      current = data[width * y + x]
      newdata[width * y + x] = 255 - current
    end
  end
  newdata
end

def blur_rust(width, height, data)


  data
end
