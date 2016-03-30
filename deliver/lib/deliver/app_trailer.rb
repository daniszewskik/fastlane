module Deliver
  # AppTrailer represents one video trailer for one specific locale and
  # device type.
  class AppTrailer

    attr_accessor :device_type

    attr_accessor :video_path

    attr_accessor :language

    attr_accessor :timestamp

    attr_accessor :poster_image_path

    # @param video_path (String) path to the video file
    # @param language (String) Language of this trailer (e.g. en-US)
    def initialize(video_path, language)
      self.video_path = video_path
      self.language = language

      # should be given as video file name prefix since we can't determine device by resolution
      self.device_type = discover_device_type(video_path)
      self.timestamp = discover_timestamp(video_path)
      # should be in the same directory as video file and also prefixed with device type
      self.poster_image_path = discover_poster_image(video_path, device_type)

      # check if file extension is valid
      ensure_valid_extension(video_path)
    end

    def formatted_name
      pattern = {
        'iphone4' => 'iPhone 4',
        'iphone6' => 'iPhone 6',
        'iphone6Plus' => 'iPhone 6 Plus',
        'ipad' => 'iPad',
        'ipadPro' => 'iPad Pro',
        'appleTV' => 'apple TV'
      }
      return pattern[self.device_type]
    end

    private

    # Validates file extension
    def ensure_valid_extension(video_path)
      UI.user_error!("The extension of given video (#{video_path}) does not match the requirements (mov, m4v, mp4)") unless [".mov", ".m4v", ".mp4"].include?(File.extname(video_path).downcase)
    end

    # Let's agree that device type is a prefix eg. iphone4_filename.mov
    def discover_device_type(video_path)
      filename = File.basename(video_path)
      dev = filename.split('_').first.downcase
      # Trailers available only for those device types
      dev_types = ['iphone4', 'iphone6', 'iphone6plus', 'ipad', 'ipadpro', 'appletv']

      UI.user_error!("Unrecognized device type for path '#{video_path}'") unless dev_types.include?(dev)

      # further dev types have to be case sensitive, so convert
      proper_dev_types = {
        'iphone4' => 'iphone4',
        'iphone6' => 'iphone6',
        'iphone6plus' => 'iphone6Plus',
        'ipad' => 'ipad',
        'ipadpro' => 'ipadPro',
        'appletv' => 'appleTV'
      }
      return proper_dev_types[dev]
    end

    # extracts timestamp from file name. Timestamp is used go get frame to poster screen
    def discover_timestamp(path)
      filename = File.basename(path)

      # max trailer length is 30sec so let's check if given timestamp is valid
      matched = filename.match(/_([0-2]{1}\d{1}\d{2})_/)

      # in case if it's last second of trailer
      matched = filename.match(/_(3000)_/) unless matched

      if matched
        return matched[1].insert(2, '.')
      end

      # return default if no timestamp in file name
      return '05.00'
    end

    # Finds preview image matching to the given video, assuming that preview is also prefixed with device type
    def discover_poster_image(video_path, device_type)
      poster_path = File.dirname(video_path)
      poster_extensions = '{png,jpg,jpeg}'
      files = Dir.glob(File.join(poster_path, "*.#{poster_extensions}"), File::FNM_CASEFOLD)

      files.each do |file|
        return file if file.downcase.include?(device_type.downcase)
      end
      UI.user_error!("Poster image not found for device #{device_type}")
    end
  end
end
