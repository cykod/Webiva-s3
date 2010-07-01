require  File.expand_path(File.dirname(__FILE__) + '/../../s3_spec_helper')

describe S3::CloudFront do

  before(:each) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    @bucket = S3::Bucket.new 'access_key', 'secret', 'my-bucket'
  end

  it "should be able to list all the distributions" do
    fakeweb_cloudfront_distributions_response
    @cloud_front = S3::CloudFront.new @bucket
    @cloud_front.distributions
    @cloud_front.origin.should == "my-bucket.s3.amazonaws.com"
  end

  it "should be able to find the distribution from the origin" do
    fakeweb_cloudfront_distributions_response "my-bucket.s3.amazonaws.com", '11111111111'
    fakeweb_cloudfront_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'Deployed')
    @cloud_front = S3::CloudFront.new @bucket
    @cloud_front.distribution[:origin].should == "my-bucket.s3.amazonaws.com"
    @cloud_front.distribution[:e_tag].should_not be_nil
  end

  it "should be able to find the distribution from the id" do
    fakeweb_cloudfront_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'Deployed')
    @cloud_front = S3::CloudFront.new @bucket, '11111111111'
    @cloud_front.distribution[:status].should == 'Deployed'
    @cloud_front.distribution[:origin].should == "my-bucket.s3.amazonaws.com"
    @cloud_front.distribution[:e_tag].should_not be_nil
    @cloud_front.deployed?.should be_true
  end

  it "should be able to create a distribution" do
    fakeweb_cloudfront_distributions_response
    fakeweb_cloudfront_create_distribution_response 'my-bucket.s3.amazonaws.com', '11111111111'
    fakeweb_cloudfront_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'InProgress')
    @cloud_front = S3::CloudFront.new @bucket
    @cloud_front.save
    @cloud_front.distribution[:status].should == 'InProgress'
    @cloud_front.distribution[:origin].should == "my-bucket.s3.amazonaws.com"
    @cloud_front.distribution[:e_tag].should_not be_nil
    @cloud_front.deployed?.should be_false
  end

  it "should be able to update a distribution" do
    fakeweb_cloudfront_update_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'static.test.dev')
    @cloud_front = S3::CloudFront.new @bucket, '11111111111'
    @cloud_front.save ['static.test.dev']
    @cloud_front.distribution[:status].should == 'InProgress'
    @cloud_front.distribution[:origin].should == "my-bucket.s3.amazonaws.com"
    @cloud_front.distribution[:e_tag].should_not be_nil
    @cloud_front.distribution[:cnames].should == ['static.test.dev']
    @cloud_front.deployed?.should be_false
  end
end
