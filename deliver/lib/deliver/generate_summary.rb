module Deliver
  class GenerateSummary
    def run(options)
      screenshots = UploadScreenshots.new.collect_screenshots(options)
      trailers = UploadTrailers.new.collect_trailers(options)
      UploadMetadata.new.load_from_filesystem(options)
      HtmlGenerator.new.render(options, screenshots, trailers, '.')
    end
  end
end
