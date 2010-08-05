require  File.expand_path(File.dirname(__FILE__) + '/../../s3_spec_helper')

describe DomainFile do

  reset_domain_tables :domain_file, :domain_file_version, :configuration
  reset_system_tables :server

  before(:each) do
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false

    @options = S3::AdminController.module_options
    @options.access_key_id = 'access'
    @options.secret_access_key = 'secret'
    @options.bucket = 'my-bucket'
    Configuration.set_config_model(@options)

    @server1 = Server.create :hostname => 'server1.test.dev', :web => true, :workling => true
    @server2 = Server.create :hostname => 'server2.test.dev', :workling => true
    @server3 = Server.create :hostname => 'server3.test.dev', :web => true

    fdata = fixture_file_upload("files/rails.png",'image/png')
    @file1 = DomainFile.create(:filename => fdata)
    @file1.update_attributes(:server_id => @server1.id, :processor => 's3/domain_file_support')

    fdata = fixture_file_upload("files/test.txt",'text/plain')
    @file2 = DomainFile.create(:filename => fdata)
    @file2.update_attributes(:server_id => @server2.id, :processor => 's3/domain_file_support')

    fdata = fixture_file_upload("files/system_domains.gif",'image/gif')
    @file3 = DomainFile.create(:filename => fdata, :private => true)
    @file3.update_attributes(:server_id => @server3.id, :processor => 's3/domain_file_support')

    @file_types = Configuration.file_types :processors => ['s3/domain_file_support', 'local'], :default => 's3/domain_file_support'
    Configuration.should_receive(:file_types).any_number_of_times.and_return(@file_types)
  end

  after(:each) do
    if @file1
      @file1 = DomainFile.find @file1.id
      @file1.server_hash = nil
      @file1.processor = 'local'
      @file1.destroy
    end

    if @file2
      @file2 = DomainFile.find @file2.id
      @file2.server_hash = nil
      @file2.processor = 'local'
      @file2.destroy
    end

    if @file3
      @file3 = DomainFile.find @file3.id
      @file3.server_hash = nil
      @file3.processor = 'local'
      @file3.destroy
    end
  end

  it "should be able to return the local processor" do
    @processor = @file1.processor_handler
    @processor.should_not be_nil
    @processor.class.should == S3::DomainFileSupport
  end

  it "should be able to copy a file locally" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_get_file_response('my-bucket', @file2.prefixed_filename)

    File.unlink @file2.local_filename
    File.exists?(@file2.local_filename).should be_false

    @processor = @file2.processor_handler
    @processor.copy_local!.should be_true

    File.exists?(@file2.local_filename).should be_true
  end

  it "should be able to copy a file locally" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_get_file_response('my-bucket', @file2.prefixed_filename)

    File.unlink @file2.local_filename
    File.exists?(@file2.local_filename).should be_false

    @file2.filename

    File.exists?(@file2.local_filename).should be_true
  end

  it "should be able to create a file and copy it to s3" do
    fakeweb_s3_valid_credentials_response
    DomainFile.should_receive(:generate_prefix).once.and_return('fake/fake')
    # the 5 is the id of file4
    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/fake/fake/5/test.txt")

    fdata = fixture_file_upload("files/test.txt",'text/plain')
    @file4 = DomainFile.create(:filename => fdata, :process_immediately => true)
    @file4.id.should_not be_nil
    @file4.processor.should == 's3/domain_file_support'

    @file4 = DomainFile.find @file4.id
    @file4.processor = 'local'
    @file4.server_hash = nil
    @file4.destroy
  end

  it "should delete remote copies" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_delete_file_response('my-bucket', @file2.prefixed_filename)

    File.unlink @file2.local_filename
    File.exists?(@file2.local_filename).should be_false

    @processor = @file2.processor_handler
    @processor.destroy_remote!.should be_true
  end

  it "should delete remote copies" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_delete_file_response('my-bucket', @file2.prefixed_filename)

    @file2.destroy
    File.exists?(@file2.local_filename).should be_false
    @file2 = nil
  end

  it "should be able create a private file" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_make_file_private_response('my-bucket', @file2.prefixed_filename)

    @processor = @file2.processor_handler
    @processor.update_private! true

    @file2.private.should be_true
  end

  it "should be able create a public file" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_make_file_public_response('my-bucket', @file2.prefixed_filename)

    @processor = @file2.processor_handler
    @processor.update_private! false

    @file2.private.should be_false
  end

  it "should be able to copy a remote version" do
    fakeweb_s3_valid_credentials_response
    fakeweb_s3_make_file_public_response('my-bucket', @file2.prefixed_filename)
    fakeweb_s3_make_file_public_response('my-bucket', @file3.prefixed_filename)

    DomainFileVersion.should_receive(:generate_version_hash).once.and_return('XXXXXXX')
    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/#{@file2.prefix}/v/XXXXXXX/test.txt")

    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/#{@file2.prefix}/1/#{@file3.name}")
    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/#{@file2.prefix}/1/icon/#{@file3.name}")
    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/#{@file2.prefix}/1/thumb/#{@file3.name}")
    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/#{@file2.prefix}/1/preview/#{@file3.name}")
    fakeweb_s3_store_file_response('my-bucket', "#{DomainFile.storage_subdir}/#{@file2.prefix}/1/small/#{@file3.name}")

    fakeweb_s3_delete_file_response('my-bucket', @file2.prefixed_filename)
    fakeweb_s3_delete_file_response('my-bucket', @file3.prefixed_filename)
    fakeweb_s3_delete_file_response('my-bucket', @file3.prefixed_filename('icon'))
    fakeweb_s3_delete_file_response('my-bucket', @file3.prefixed_filename('thumb'))
    fakeweb_s3_delete_file_response('my-bucket', @file3.prefixed_filename('preview'))
    fakeweb_s3_delete_file_response('my-bucket', @file3.prefixed_filename('small'))

    assert_difference 'DomainFileVersion.count', 1 do
      @file2.replace @file3
      @file3 = nil
    end

    @file2.version_count.should == 1

    @version = DomainFileVersion.find :last
    @version.domain_file_id.should == @file2.id

    # need this because it tries to delete the version file from s3 when we destroy file2
    fakeweb_s3_delete_file_response 'my-bucket', @version.prefixed_filename
  end
end
