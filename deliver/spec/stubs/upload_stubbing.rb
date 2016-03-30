# Our fake application
class FakeApp
  def edit_version
    @ev ||= EditVersion.new
  end
end

# Screenshot class shared between ITC Sceenshot and Deliver Screenshot
class Screenshot

  def initialize(args)
    self.path = args[:file_path]
    self.device_type = "iphone4"
    self.language = args[:language]
    self.screen_size = 'iOS-4-in'
    self.original_file_name = args[:original_file_name]
    self.sort_order = args[:sort_order]
  end
  attr_accessor :sort_order, :original_file_name, :path, :language, :device_type, :screen_size
end

# Fake EditEversion with necessary methods stubbed
class EditVersion

  def screenshots
    @ret ||= init_screenshots
  end

  def trailers
    @trailers ||= init_trailer
  end

  # we don't have to really upload. It's enoguth to know if we are uploading or deleting
  def upload_screenshot!(path, order, lang, device)
    if path
      puts "Uploading '#{path}' for device #{device}"
    else
      puts "Deleting #{order} for device #{device}"
    end
  end

  # the same as with screenshot - real upload is tested in spaceship module
  def upload_trailer!(path, language, device_type, timestamp, poster_image_path = nil)
    if path
      puts "Uploading '#{path}' for device #{device_type}"
    else
      puts "Deleting trailer for device #{device_type}"
    end
  end

  def save!
  end

  private

  def init_screenshots
    @ret = {}
    @ret['en-US'] ||= []
    root = '/tmp/screenshots/'
    (1..4).each do |i|
      file_path = File.join(root, "scr_#{i}.jpg")
      md5 = Spaceship::Utilities.md5digest(file_path)
      file = Screenshot.new({file_path: file_path, language: 'en-US', original_file_name: "ftl_#{md5}_scr_#{i}.jpg", sort_order: i})
      @ret['en-US'] << file
    end
    @ret
  end

  def init_trailer
    @trailer = {}
    @trailer['en-US'] ||= []
    video = Deliver::AppTrailer.new('ipad_path_to_trailer.mov', 'en-US')
    @trailer['en-US'] << video
    @trailer
  end
end
