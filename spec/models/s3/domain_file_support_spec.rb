require  File.expand_path(File.dirname(__FILE__) + '/../../s3_spec_helper')

describe S3::DomainFileSupport do

  reset_domain_tables :domain_files

  before(:each) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    fakeweb_s3_valid_credentials_response
    @bucket = S3::Bucket.new 'access_key', 'secret', 'my-bucket'
    @df = DomainFile.create :name => 'test.txt', :filename => fixture_file_upload('files/test.txt'), :processor => 'local'
    @support = S3::DomainFileSupport.new @bucket, @df
  end

  after(:each) do
    @df.destroy
  end

  it "copy files to s3" do
    fakeweb_s3_store_file_response('my-bucket', @df.prefixed_filename)
    @support.copy_remote!
  end

  it "delete s3 file" do
    fakeweb_s3_delete_file_response('my-bucket', @df.prefixed_filename)
    @support.destroy_remote!
  end

  it "private s3 file" do
    fakeweb_s3_make_file_private_response('my-bucket', @df.prefixed_filename)
    @support.update_private! true
  end

  it "public s3 file" do
    fakeweb_s3_make_file_public_response('my-bucket', @df.prefixed_filename)
    @support.update_private! false
  end

  it "should copy a file locally" do
    fakeweb_s3_get_file_response('my-bucket', @df.prefixed_filename)
    File.unlink(@df.local_filename)
    raise 'test file not removed' if File.exists?(@df.local_filename)
    @support.copy_local!
    raise 'test file not copyied locally' unless File.exists?(@df.local_filename)
  end
end
