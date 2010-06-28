require 'aws/s3'
require 'fileutils'

class S3::DomainFileSupport 
  

  def self.website_file_handler_info
    { 
      :name => 'S3 File Support',
    }
  end

  def self.create_connection(cls=nil, opts=nil)
    S3::AdminController.module_options.connection
  end
  
  
  def initialize(connection,df)
    @connection = connection
    @df = df
  end
  
  # Copy local files to the remote server
  def copy_remote!(size=nil)
    begin
      (size ? [ size ] : file_sizes).each do |size|
        @connection.store(@df.prefixed_filename(size),
                                File.open(@df.local_filename(size)), 
                                :access => @df.private? ? :private : :public_read )
      end
      return true
    rescue Exception => e
      raise e
      return false
    end
    
  end

  def destroy_thumbs!(size=nil)
     (size ? [ size ] : file_sizes).each do |size|
      # don't destroy the original(yet)
      begin
        @connection.delete(@df.prefixed_filename(size)) if size 
      rescue Exception => e
        # Chomp all
      end
    end
  end

  def revision_support; true; end

  def create_remote_version!(version)
    @connection.store(version.prefixed_filename,File.open(version.abs_filename),:access => :private)
    return true
  end
  
  def destroy_remote_version!(version)
    @connection.delete(version.prefixed_filename)
  end

  def version_url(version)
    @connection.url_for(version.prefixed_filename).gsub("http://s3.amazonaws.com/#{@connection.bucket}/","http://#{@connection.bucket}.s3.amazonaws.com/")
  end

  # Download the files and put them in a regular directory
  def copy_local!(dest_size=nil)
    (dest_size ? [dest_size] : file_sizes).each do |size|
      filename = @df.local_filename(size)
      if(!File.exists?(filename)) # Only do it if the file doesn't exist locally
        dir_name = File.dirname(filename)
        FileUtils.mkpath(dir_name) if(!File.exists?(dir_name))
        File.open(filename,'w') do |file|
          @connection.stream(@df.prefixed_filename(size)) { |chunk| file.write chunk }
        end
      end
    end
  end
  
  def destroy_remote!()
    file_sizes.each do |size|
      begin
        @connection.delete(@df.prefixed_filename(size))
      rescue Exception => e
        # Chomp
      end
    end  
  end
  
  
  
  def update_private!(value)
    # Get the bucket policy (which is owner read only)
    policy = @connection.acl
    if !value
      policy.grants << AWS::S3::ACL::Grant.grant(:public_read)
    end
    file_sizes.each do |size|
      @connection.acl(@df.prefixed_filename(size),policy)
    end
    if value && !@df.private?
       FileUtils.rm_rf(@df.abs_storage_directory)
    end
    @df.update_attribute(:private,value)
  end

  
  def url(size=nil)
    # return the normal directory structure  
    if @df.private?
      @connection.url_for(@df.prefixed_filename(size)).gsub("http://s3.amazonaws.com/#{@connection.bucket}/","http://#{@connection.bucket}.s3.amazonaws.com/")
    else
      # "http://#{@connection.bucket}.s3.amazonaws.com/#{@df.prefixed_filename(size)}" 
      @connection.url_for(@df.prefixed_filename(size),:authenticated => false).gsub("http://s3.amazonaws.com/#{@connection.bucket}/","http://#{@connection.bucket}.s3.amazonaws.com/")
    end
  end
  
  def full_url(size=nil)
    self.url(size)
  end

  def self.validate_bucket(options=nil)
    conn = create_connection(AWS::S3::Bucket, options)
    buckets = conn.list.collect(&:name)
    conn.create(options.bucket) unless buckets.include?(options.bucket)
    return true
  end

  protected
  
  def file_sizes
   # Get the original size
    sizes = [nil] 
    # Add in any additional image sizes of necessary
    sizes += DomainFile.image_sizes.collect() { |sz| sz[0].to_s } if(@df.file_type == 'img' || @df.file_type == 'thm')
    
    sizes
  end
end
