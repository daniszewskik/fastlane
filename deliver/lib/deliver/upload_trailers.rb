require 'pry'
module Deliver
  # upload video trailer to ITC
  class UploadTrailers
    def upload(options, videos)
      return if options[:skip_trailers]

      app = options[:app]

      v = app.edit_version
      UI.user_error!("Could not find a version to edit for app '#{app.name}'") unless v

      # We have to make sure that it's only one per device in lang
      indexed = {}

      UI.message("Uploading #{videos.length} video trailers")

      # Opposite to screenshots, video trailers do not divide per language.
      # Trailer uploaded for one device and one language will propagate on all active languages.
      # Though ITC will return trailers divided per language (v.trailers method). Don't be fooled. It doesn't mean anything.
      # You cant set two different trailers for the same device on two languages
      # ITC you are so consistent...
      videos.each do |trailer|
        indexed[trailer.language] ||= {}
        indexed[trailer.language][trailer.device_type] ||= 0
        indexed[trailer.language][trailer.device_type] += 1

        index = indexed[trailer.language][trailer.device_type]

        if index > 1
          UI.important("There can be only one trailer per device '#{trailer.device_type}'")
          next
        end
        # we have to delete before uploading - only if trailer already exists on ITC
        if trailer_remotely_exists?(v, trailer.language, trailer.device_type)
          UI.message("Deleting trailer for device #{trailer.device_type} from ITC...")
          v.upload_trailer!(nil,
                            trailer.language,
                            trailer.device_type,
                            trailer.timestamp)
        end
        # upload trailer
        UI.message("Uploading '#{trailer.video_path}'...")
        v.upload_trailer!(trailer.video_path,
                          trailer.language,
                          trailer.device_type,
                          trailer.timestamp,
                          trailer.poster_image_path)
      end

      # They are grouped by language. We need only one group
      remote_trailers = v.trailers.values.first

      if videos.count > 0
        UI.message("Saving changes")
        v.save!
      elsif remote_trailers.count > 0
        # Nothing to upload, delete existing on ITC
        remote_trailers.each do |trailer|
          UI.message("Deleting trailer for device #{trailer.device_type} from ITC...")
          v.upload_trailer!(nil,
                            trailer.language,
                            trailer.device_type,
                            trailer.timestamp)
        end
        UI.message("Saving changes")
        v.save!
      else
        UI.message("No trailers to upload. Skipping")
      end
    end

    def collect_trailers(options)
      return [] if options[:skip_trailers]

      # since there's no language division, we'll take default language
      # trailers will propagate to every active language
      app = options[:app]
      v = app.edit_version
      language = v.languages[0]['language']

      trailers = []
      extensions_trailer = '{mov,mv4,mp4}'

      path = options[:trailers_path]

      files = Dir.glob(File.join(path, "*.#{extensions_trailer}"), File::FNM_CASEFOLD)

      files.each do |file_path|
        trailers << AppTrailer.new(file_path, language)
      end
      return trailers
    end

    # Checks if trailer for given language and device type exists on ITC
    # @return (Boolean)
    def trailer_remotely_exists?(edit_version, language, device_type)
      @trailers ||= edit_version.trailers

      if @trailers[language]
        @trailers[language].each do |trailer|
          return true if trailer.device_type == device_type
        end
      end
      return false
    end
  end
end
