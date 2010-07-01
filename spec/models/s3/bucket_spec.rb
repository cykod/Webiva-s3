require  File.expand_path(File.dirname(__FILE__) + '/../../s3_spec_helper')

describe S3::Bucket do

  before(:each) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
  end

  it "should be able to test for invalid credentials" do
    fakeweb_s3_invalid_credentials_response

    @bucket = S3::Bucket.new 'access_key', 'secret', 'my-bucket'
    @bucket.s3
    lambda{ @bucket.buckets }.should raise_error(RightAws::AwsError)
  end

  it "should be able to test for valid credentials" do
    fakeweb_s3_valid_credentials_response

    @bucket = S3::Bucket.new 'access_key', 'secret', 'my-bucket'
    @bucket.buckets
  end

  it "should be able to fetch a bucket" do
    fakeweb_s3_valid_credentials_response

    @bucket = S3::Bucket.new 'access_key', 'secret', 'my-bucket'
    @bucket.bucket.name.should == 'my-bucket'
    @bucket.host.should == 'my-bucket.s3.amazonaws.com'
  end

  it "should be able to create a bucket if it is missing" do
    fakeweb_s3_create_bucket_response('bucket-to-create')

    @bucket = S3::Bucket.new 'access_key', 'secret', 'bucket-to-create'
    @bucket.bucket.name.should == 'bucket-to-create'
    @bucket.host.should == 'bucket-to-create.s3.amazonaws.com'
    @bucket.url_for('test.txt', :private => false).should == 'http://bucket-to-create.s3.amazonaws.com/test.txt'
    @bucket.url_for('test.txt', :private => true).should include('https://bucket-to-create.s3.amazonaws.com:443/test.txt')
  end

  it "test for valid bucket names" do
    S3::Bucket.valid_bucket_name?('my-bucket').should be_true
    S3::Bucket.valid_bucket_name?('my bucket').should be_false
  end

  describe "Working with a bucket" do
    before(:each) do
      fakeweb_s3_valid_credentials_response
      @bucket = S3::Bucket.new 'access_key', 'secret', 'my-bucket'      
    end

    it "should be able to store a file" do
      fakeweb_s3_store_file_response('my-bucket', 'test.txt')
      @bucket.store('test.txt', fixture_file_upload("files/test.txt",'text/plain'), 'public-read')
    end

    it "should be able to delete a file" do
      fakeweb_s3_delete_file_response('my-bucket', 'test.txt')
      @bucket.delete('test.txt')
    end

    it "should be able to fetch a file" do
      fakeweb_s3_get_file_response('my-bucket', 'test.txt')
      @bucket.bucket.get('test.txt').should == "Test\n"
    end

    it "should be able to make a file public" do
      fakeweb_s3_make_file_public_response('my-bucket', 'test.txt')
      @bucket.make_public!('test.txt')
    end

    it "should be able to make a file private" do
      fakeweb_s3_make_file_private_response('my-bucket', 'test.txt')
      @bucket.make_private!('test.txt')
    end
  end

end
