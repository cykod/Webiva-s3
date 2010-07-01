require  File.expand_path(File.dirname(__FILE__) + '/../../s3_spec_helper')

describe S3::AdminController do

  reset_domain_tables :configurations

  before(:each) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
  end

  describe 'Editor Tests' do
    before(:each) do
      mock_editor
    end

    it "should render the options page" do
      get 'options'
      response.should render_template('options')
    end

    it "should not accept invalid options" do
      fakeweb_s3_invalid_credentials_response
      post 'options', :options => {:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'my-bucket', :enable_cloud_front => false}
      response.should render_template('options')
    end

    it "should accept valid options" do
      fakeweb_s3_valid_credentials_response
      post 'options', :options => {:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'my-bucket', :enable_cloud_front => false}
      response.should redirect_to(:controller => '/modules')
    end

    it "should accept valid options and create the bucket" do
      fakeweb_s3_create_bucket_response('bucket-to-create')
      post 'options', :options => {:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'bucket-to-create', :enable_cloud_front => false}
      response.should redirect_to(:controller => '/modules')
    end

    it "should accept valid options and create the bucket and the cloud front" do
      fakeweb_s3_create_bucket_response('bucket-to-create')
      fakeweb_cloudfront_distributions_response
      fakeweb_cloudfront_create_distribution_response 'bucket-to-create.s3.amazonaws.com', '11111111111'
      fakeweb_cloudfront_distribution_response('bucket-to-create.s3.amazonaws.com', '11111111111', 'InProgress')
      post 'options', :options => {:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'bucket-to-create', :enable_cloud_front => true}
      response.should redirect_to(:action => 'cloud_front_setup')
    end

    it "should not turn on cloud front if it is not available" do
      fakeweb_s3_valid_credentials_response
      # this test is only working becuase FakeWeb is throwing an exception for cloud front url.
      # test is still valid because normally cloud front throws an exception saying that you need to register for cloud front support.
      post 'options', :options => {:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'my-bucket', :enable_cloud_front => true}
      response.should render_template('options')
    end

    it "should render cloud front setup" do
      fakeweb_s3_valid_credentials_response
      fakeweb_cloudfront_distributions_response
      fakeweb_cloudfront_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'Deployed')

      @options = Configuration.get_config_model(S3::AdminController::ModuleOptions,{:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'my-bucket', :enable_cloud_front => true, :cloud_front_distribution_info => {:aws_id => '11111111111', :origin => 'my-bucket.s3.amazonaws.com', :cnames => [], :domain_name => 'dcm11y1e1j1bu.cloudfront.net', :e_tag => 'E1VXM1A1PG1JQK', :comment => 'Webiva Cloud Front Support', :status => 'Deployed'}})
      raise @options.errors.inspect unless @options.valid?
      Configuration.set_config_model(@options)

      get 'cloud_front_setup'
      response.should render_template('cloud_front_setup')
    end

    it "should redirect to modules page when done" do
      fakeweb_s3_valid_credentials_response
      fakeweb_cloudfront_distributions_response
      fakeweb_cloudfront_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'Deployed')

      @options = Configuration.get_config_model(S3::AdminController::ModuleOptions,{:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'my-bucket', :enable_cloud_front => true, :cloud_front_distribution_info => {:aws_id => '11111111111', :origin => 'my-bucket.s3.amazonaws.com', :cnames => [], :domain_name => 'dcm11y1e1j1bu.cloudfront.net', :e_tag => 'E1VXM1A1PG1JQK', :comment => 'Webiva Cloud Front Support', :status => 'InProgress'}})
      raise @options.errors.inspect unless @options.valid?
      Configuration.set_config_model(@options)

      get 'cloud_front_setup'
      response.should redirect_to(:controller => '/modules')
    end

    it "should setup a cname for cloud front" do
      fakeweb_s3_valid_credentials_response
      fakeweb_cloudfront_distributions_response
      fakeweb_cloudfront_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'Deployed')

      @options = Configuration.get_config_model(S3::AdminController::ModuleOptions,{:access_key_id => 'access_key', :secret_access_key => 'secret', :bucket => 'my-bucket', :enable_cloud_front => true, :cloud_front_distribution_info => {:aws_id => '11111111111', :origin => 'my-bucket.s3.amazonaws.com', :cnames => [], :domain_name => 'dcm11y1e1j1bu.cloudfront.net', :e_tag => 'E1VXM1A1PG1JQK', :comment => 'Webiva Cloud Front Support', :status => 'Deployed'}})
      raise @options.errors.inspect unless @options.valid?
      Configuration.set_config_model(@options)

      FakeWeb.clean_registry
      fakeweb_s3_valid_credentials_response
      fakeweb_cloudfront_distributions_response
      fakeweb_cloudfront_update_distribution_response('my-bucket.s3.amazonaws.com', '11111111111', 'static.test.dev')

      post 'cloud_front_setup', :options => {:cname => 'static.test.dev'}
      response.should redirect_to(:action => 'cloud_front_setup')

      @options = Configuration.get_config_model(S3::AdminController::ModuleOptions,nil)
      @options.cname.should == 'static.test.dev'
    end
  end
end
