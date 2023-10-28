require 'fileutils'
require 'rmagick'

class Image < ActiveRecord::Base
  attr_writer :tempfile, :orig_filename

  scope :unused, ->{ where(entry_id: nil) }

  def self.update_unused(entry)
    Image.unused.update!(entry_id: entry.id)
  end

  def public_local_path
    File.expand_path("#{__dir__}/../../public")
  end

  def orig_file_path
    orig_path.sub("public", public_local_path)
  end

  def thumb_file_path
    thumb_path.sub("public", public_local_path)
  end

  def orig_html_path
    orig_path.sub("public", "")
  end

  def thumb_html_path
    thumb_path.sub("public", "")
  end

  before_save do
    if @path_base.nil?
      @path_base = Time.now.strftime(NLog2.config[:image_path])
      FileUtils.mkdir_p(File.dirname(@path_base))
    end
    if @tempfile
      write_orig_file
      write_thumbnail
    end
  end

  after_destroy do
    File.delete(self.orig_path) if File.exist?(self.orig_path)
    File.delete(self.thumb_path) if File.exist?(self.thumb_path)
  end

  private

  def write_orig_file
    self.orig_path = "#{@path_base}#{@orig_filename}"
    @tempfile.rewind
    File.write(self.orig_path, @tempfile.read)
  end

  MAX_WIDTH = 600
  def write_thumbnail
    extname = File.extname(@orig_filename)
    filename = "#{File.basename(@orig_filename, extname)}.thumb#{extname}"
    self.thumb_path = "#{@path_base}#{filename}"
    img = Magick::Image.read(self.orig_path).first
    if img.columns > MAX_WIDTH
      factor = MAX_WIDTH.to_f / img.columns
      NLog2.logger.debug("Resizing #{@orig_filename} (columns: #{img.columns}, MAX_WIDTH: #{MAX_WIDTH}, factor: #{factor}")
      thumb = img.scale(factor)
      thumb.write(self.thumb_path)
    else
      NLog2.logger.debug("Not resizing #{@orig_filename} (columns: #{img.columns}, MAX_WIDTH: #{MAX_WIDTH}")
      FileUtils.copy(self.orig_path, self.thumb_path)
    end
  end
end
