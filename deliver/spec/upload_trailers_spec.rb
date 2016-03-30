require 'spec_helper'
require 'stubs/upload_stubbing'

describe Deliver::UploadTrailers do
  let(:ipad_trailer_poster_path) { "path_to_trailer_poster.jpg" }

  let(:options) { { app: FakeApp.new } }
  let(:deliver) { Deliver::UploadTrailers.new }

  before do |example|
    unless example.metadata[:skip_before]
      allow_any_instance_of(Deliver::AppTrailer).to receive(:discover_poster_image).and_return(ipad_trailer_poster_path)
    end
  end

  # local upload
  def local(path)
    @local ||= []
    file = Deliver::AppTrailer.new(path, 'en-US')
    @local << file
  end

  it "should delete trailer from ITC if exists before uploading new" do
    local('ipad_path_to_trailer.mov')
    expect do
      deliver.upload(options, @local)
    end.to output(/Deleting trailer for device ipad\nUploading 'ipad_path_to_trailer.mov' for device ipad/).to_stdout
  end

  it "should upload trailer without deleting if no trailer for that device on ITC" do
    allow(deliver).to receive(:trailer_remotely_exists?).and_return(false)
    local('ipad_path_to_trailer.mov')
    expect do
      deliver.upload(options, @local)
    end.to_not output(/Deleting trailer for device ipad/).to_stdout
  end

  it "should skip second trailer when trying to upload two trailers for the same device" do
    local('ipad_path_to_trailer.mov')
    local('ipad_path_to_trailer2.mov')
    # second trailer for ipad should be skipped
    expect do
      deliver.upload(options, @local)
    end.to_not output(/Uploading 'ipad_path_to_trailer2.mov' for device ipad/).to_stdout
  end

  it "should delete ITC trailer when nothing is uploaded" do
    @local = []
    expect do
      deliver.upload(options, @local)
    end.to output(/Deleting trailer for device ipad/).to_stdout
  end

  it "should do nothing when no trailers to upload and no trailers on ITC" do
    allow_any_instance_of(EditVersion).to receive(:trailers).and_return({'en-US' => []})
    @local = []
    expect do
      deliver.upload(options, @local)
    end.to output('').to_stdout
  end

  it "should raise error when file not prefixed with device name" do
    expect { local('path_to_trailer.mov') }.to raise_error(FastlaneCore::Interface::FastlaneError)
  end

  it "should raise error when file prefixed with unrecognized device name" do
    expect { local('iphone99_path_to_trailer.mov') }.to raise_error(FastlaneCore::Interface::FastlaneError)
  end

  it "should raise error when invalid file extension" do
    expect { local('ipad_path_to_trailer.mp5') }.to raise_error(FastlaneCore::Interface::FastlaneError)
  end

  it "should use default timestamp if not given in filename" do
    file = Deliver::AppTrailer.new('ipad_path_to_trailer.mp4', 'en-US')

    expect(file.timestamp).to eq('05.00')
  end

  it "should extract timestamp if given in filename" do
    file = Deliver::AppTrailer.new('ipad_0630_path_to_trailer.mp4', 'en-US')

    expect(file.timestamp).to eq('06.30')
  end

  it "should not allow timestamps greater than 3000 (30sec)" do
    file = Deliver::AppTrailer.new('ipad_3001_path_to_trailer.mp4', 'en-US')

    expect(file.timestamp).to eq('05.00')
  end

  it "should discover poster image" do
    file = Deliver::AppTrailer.new('ipad_path_to_trailer.mp4', 'en-US')

    expect(file.poster_image_path).to eq(ipad_trailer_poster_path)
  end

  it "should raise error when no poster image", skip_before: true do
    # allow_any_instance_of(Deliver::AppTrailer).to_not receive(:discover_poster_image)
    expect { Deliver::AppTrailer.new('ipad_path_to_trailer.mp4', 'en-US') }.to raise_error
  end
end
