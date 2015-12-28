#!/usr/bin/env ruby
# require 'rubygems'
require 'rake'

desc 'Crop and repack the image files'
task :crop_repack do
  # convert weather.png -crop 240x240 +repage weather_%d.png
  # convert weather_*.png -shave 48x48 weather_%d.png
  # montage weather_*.png -tile 8 -geometry 144x144 -background none weather_resized.png

  pictures = FileList.new('*.png')
  pictures.each do |pic|
    pic_dir = pic.pathmap('%n')
    mkdir pic_dir
    sh %Q(convert #{pic} -crop 240x240 +repage #{pic_dir}/tmp_%d.png)
    sh %Q(convert #{pic_dir}/tmp_*.png -shave 48x48 #{pic_dir}/tmp_%d.png)
    sh %Q(montage #{pic_dir}/tmp_*.png -tile 8 -geometry 144x144 -background none resized_#{pic}.png)
  end
end

desc'Reduce the size of all icons'
task :resize, [:size] do |t, args|
  pictures = FileList.new('*.png')
  size = args[:size] || 64
  pictures.each do |pic|
    pic_dir = pic.pathmap('%n')
    mkdir "#{pic_dir}_#{size}"
    sh %Q(convert #{pic} -crop 240x240 +repage #{pic_dir}_#{size}/tmp_%d.png)
    sh %Q(convert #{pic_dir}_#{size}/tmp_*.png -shave 48x48 -resize #{size}x#{size} #{pic_dir}_#{size}/#{pic_dir}_#{size}_%d.png)
  end
end

desc 'Crop the icons but dont repack'
task :crop do
  pictures = FileList.new('*.png')
  pictures.each do |pic|
    pic_dir = pic.pathmap('%n')
    mkdir pic_dir
    sh %Q(convert #{pic} -crop 240x240 +repage #{pic_dir}/#{pic_dir}_%d.png)
    sh %Q(convert #{pic_dir}/#{pic_dir}_*.png -shave 48x48 #{pic_dir}/#{pic_dir}_%d.png)
  end
end

desc 'Rename fucked up files part 2'
task :rename_fucked_2 do
  pictures = FileList.new('*.png')
  pictures.each do |f|
    mv f, f.gsub(/(\.png)+/, '.png')
  end
end

desc 'Rename fucked up files'
task :rename_fucked do
  pictures = FileList.new('*.png')
  pictures.each_with_index do |p, i|
    mv p, p[/(?:shaved_)?[^_]+/i]+'_'+(i%3+1).to_s+'.png'
  end
end

desc 'Shave {x}x{y} pixels from the crawled large file. (rake shave[picture.png,x,y]). Shave will cut the picture from 0x0'
task :shave, [:file, :x, :y] do |t, args|
  to_be_shaved_pictures = FileList.new(args[:file]) # Accepts glob pattern
  raise 'No picture was found' if to_be_shaved_pictures.to_a.empty?
  x = args[:x] || 64
  y = args[:y] || 64

  to_be_shaved_pictures.each do |picture|
    %x(convert #{picture} -shave '#{x}x#{y}' shaved_#{picture})
  end
end

desc '\'Slice\' the picture into the specific format. (rake slice[picture.png,x,y])'
task :slice, [:file, :x, :y] do |t, args|
  to_be_sliced_pictures = FileList.new(args[:file]) # Accepts glob pattern
  raise 'No picture was found' if to_be_sliced_pictures.to_a.empty?
  x = args[:x] || 64
  y = args[:y] || 64
  to_be_sliced_pictures.each do |p|
    file_name = p.pathmap('%n')
    file_extension = p.pathmap('%x')

    %x(convert #{p} -crop '#{x}x#{y}' +repage #{file_name}_%d#{file_extension})
  end
end

desc 'Clean up residue from the sliced picture set, may or may not apply to your case'
task :clean do

end

desc 'Rename from hash_file to file_hash'
task :rename do
  Dir.foreach('.') do |file|
    if file =~ /[^_]+_[\w]+\.png/
      %x(mv #{file} #{file[/([^_]+)_([\w]+)\.png/, 2] + '_' + file[/([^_]+)_([\w]+)\.png/, 1] + '.png'})
    end
  end
end

desc 'Curl the file from the css file...'
task :curl do
  url = 'https://daks2k3a4ib2z.cloudfront.net'
  File.open('./icons-css.txt', 'r') do |f|
    links = f.map do |line|
      line[/#{url}.*\.png/i]
    end

    links.compact.each do |asset|
      %x(wget #{asset})
    end
  end
end
