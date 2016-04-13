module Deliver
  # used to maintain 2 set of MD5s one for local one for remotes
  class ScreenshotMD5s
    def initialize
      @checksums = {}
    end

    # index is implicitly computed
    def add_md5(language, device_type, md5)
      @checksums[language] ||= {}
      @checksums[language][device_type] ||= []
      @checksums[language][device_type] << md5
    end

    def matches_md5?(language, device_type, md5, index)
      @checksums[language] &&
      @checksums[language][device_type] &&
      @checksums[language][device_type].include?(md5) &&
      @checksums[language][device_type].index(md5) + 1 == index
    end
  end
end
