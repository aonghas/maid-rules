#  MAID RULES BY AONGHAS ANDERSON
#  2020-09-19
# 
#     maid clean -n   - test
#     maid clean -f   - execute
#     maid daemon     - watch folder


SORT_FOLDER = "/Volumes/photo/docker/new/"
SORTED_FOLDER = "/Volumes/photo/Photos/"
IGNORE_FOLDERS = ['@eaDir', 'ignore']
DELETE_FOLDERS = ['@eaDir', 'ignore']
IMAGE_TYPES = "DNG,JPG,JPEG"
LOG_FILE = SORTED_FOLDER + 'info.log'
ERROR_FILE = SORTED_FOLDER + 'error.log'

def log_file(message)
  puts message
  File.open(LOG_FILE, 'a') do |f|
    f.puts Time.new().to_s + ": " + message
  end
end

#  This method sorts images into YYYY/YY-MM-DD/ folders based on when the photo was taken (uses Exiftool)
def sort_images(directory)
  log_file("[START] sorting images...")

  Dir.glob(directory + "**/*.{DNG,JPG,JPEG,CR2,RW2}", File::FNM_CASEFOLD).each do |image|
    parent_folder =  File.basename(File.dirname(image))

    unless IGNORE_FOLDERS.include?(parent_folder) then
      puts `exiftool "-filemodifydate<DateTimeOriginal" "-filecreatedate<DateTimeOriginal" "#{image}" -v5 -q 2>> #{ERROR_FILE} 1>> #{LOG_FILE}`
      puts `exiftool "-directory<FilecreateDate" "-directory<createdate" "-directory<DateTimeOriginal" -d #{SORTED_FOLDER}%Y/%Y-%m-%d "#{image}" -v1 -q 2>> #{ERROR_FILE} 1>> #{LOG_FILE}`
    end
  end
  log_file("[COMPLETE] ...sorting images done.")
end

#  This method sorts images into YYYY/YY-MM-DD/ folders based on when the photo was taken (uses Exiftool)
def add_tags(directory)
  log_file("[START] adding tags...")

  Dir.glob(directory + "**/*.{DNG,JPG,JPEG,CR2,RW2}", File::FNM_CASEFOLD).each do |image|
    parent_folder =  File.basename(File.dirname(image))

    unless IGNORE_FOLDERS.include?(parent_folder) then
      make = `exiftool -b -make "#{image}"`
      if (make.length > 0) then
        puts `tag -a #{make} "#{image}"`
        puts "adding " + make + " to " + image
      end

      gps = `exiftool -b -gpslatitude "#{image}"`
      if (gps.length > 0) then
        puts `tag -a Geotagged "#{image}"`
        puts "adding Geotagged to " + image
      end

      if (['.dng', '.rw2', '.cr2'].include? File.extname(image).downcase) then
        puts `tag -a RAW "#{image}"`
      end
    end
  end

end

#  This method deletes empty folders and any folders that just contain nested empty folders.
def delete_empty(directory) 
  log_file("[START] running empty folder deletion...")

  dir(directory + '**/*').each do |path|
    if (File.directory?(path) && tree_empty?(path)) then
      log_file("This folder is empty and will be deleted: " + path)
      trash(path)
    end
  end
  log_file("[COMPLETE] ...empty folder deletion done.")

end

#  This method deletes any folders defined in DELETE_FOLDERS. Please check before running!  
def delete_folders(directory) 
   log_file("[START] running folder deletion...")
  dir(directory + '**/*').each do |path|
    if (File.directory?(path) && DELETE_FOLDERS.include?(File.basename(path))) then
      log_file("This folder will be deleted: " + path)
      puts `rm -rf "#{path}"`
    end
  end
  log_file("[COMPLETE] ...folder deletion done.")
end

Maid.rules do
  rule 'ingest photos into YYYY/YY-MM-DD/' do 
    sort_images(SORT_FOLDER)
    delete_folders(SORT_FOLDER)
    delete_empty(SORT_FOLDER)
    add_tags(SORTED_FOLDER)
    puts "All done."
  end
 
  watch SORT_FOLDER  do
    rule 'organize images by date' do
      sort_images(SORT_FOLDER)
      delete_folders(SORT_FOLDER)
      delete_empty(SORT_FOLDER)
      puts "All done."
    end
  end
end
