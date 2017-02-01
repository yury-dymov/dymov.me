require 'fileutils'
require 'digest'

TARGET_DIR = 'dist'
ENTRY = 'index.html'

FileUtils.rm_r(TARGET_DIR) if File.exists?(TARGET_DIR)
FileUtils.mkdir_p(TARGET_DIR)

def process_resource(file, content = nil)  
  basename = file[/.*?\./][0..-2]
  ext = file[/\..*/]
  target = "#{basename}-#{Digest::MD5.hexdigest(content || File.read(file))}#{ext}"
  dist_target = "#{TARGET_DIR}/#{target}"
  FileUtils.mkdir_p(File.dirname(dist_target))

  if content
    File.write(dist_target, content)
  else
    FileUtils.cp(file, dist_target)
  end

  target
end

def get_regex(file)  
  if file =~ /\.html?$/
    /(src|href)\s*=\s*('|")(.*?)('|")/
  elsif file =~ /\.css$/
    /(url)\s*(\()(.*?)(\))/
  end
end

def process_file(file)
  current_file = File.read(file)
  current_file.scan(get_regex(file)).each do |m|
    target = m[2]

    if !File.exists?(target)
      unless target =~ /^(http|\/\/|mailto)/
        p "Warning: #{target} is missing"
      end

      next
    end

    new_filename = target =~ /\.css$/ ? process_file(target) : process_resource(target)

    current_file.gsub!(target, new_filename)
  end

  if file != ENTRY
    return process_resource(file, current_file)
  end

  File.write("#{TARGET_DIR}/#{file}", current_file)
end

process_file(ENTRY)

