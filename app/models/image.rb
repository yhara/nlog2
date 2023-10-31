require 'fileutils'
require 'rmagick'

class Image < ActiveRecord::Base
  # These should be given from the controller
  attr_writer :tempfile
  def posted_filename=(s)
    @posted_extname = File.extname(s)
    @posted_filename_base = File.basename(s, @posted_extname)
  end

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
      # Calculate path base
      # Note that this is NOT a directory but contains filename prefix too
      @path_base = Time.now.strftime(NLog2.config[:image_path])
      FileUtils.mkdir_p(File.dirname(@path_base))
    end
    if @tempfile
      write_orig_file(fresh_orig_path)
      write_thumbnail
    end
  end

  after_destroy do
    File.delete(self.orig_path) if File.exist?(self.orig_path)
    File.delete(self.thumb_path) if File.exist?(self.thumb_path)
  end

  private

  def write_orig_file(path)
    self.orig_path = path
    @tempfile.rewind
    File.write(self.orig_path, @tempfile.read)
  end

  # Find filename that are not used yet
  def fresh_orig_path
    i = 1
    loop do
      suffix = (i == 1 ? "" : i.to_s)
      path = "#{@path_base}#{@posted_filename_base}#{suffix}#{@posted_extname}"
      return path if not File.exist?(path)
      i += 1
    end
  end

  MAX_WIDTH = 600
  def write_thumbnail
    self.thumb_path = self.orig_path.sub(/#{@posted_extname}\z/, ".thumb#{@posted_extname}")
    img = Magick::Image.read(self.orig_path).first
    if img.columns > MAX_WIDTH
      factor = MAX_WIDTH.to_f / img.columns
      NLog2.logger.debug("Resizing #{self.orig_path} (columns: #{img.columns}, MAX_WIDTH: #{MAX_WIDTH}, factor: #{factor}")
      thumb = img.scale(factor)
      thumb.write(self.thumb_path)
    else
      NLog2.logger.debug("Not resizing #{self.orig_path} (columns: #{img.columns}, MAX_WIDTH: #{MAX_WIDTH}")
      FileUtils.copy(self.orig_path, self.thumb_path)
    end
  end
end
