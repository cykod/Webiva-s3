require 'aws/s3'
require 'fileutils'

class S3::DomainFileSupport 
  

  def self.website_file_handler_info
    { :name => 'S3 File Support'  }
  end
  
  
  def initialize(df)
    self.class.connect
    @df = df
  end
  
  # Copy local files to the remote server
  def copy_remote!()
    begin
      file_sizes.each do |size|
        AWS::S3::S3Object.store(@df.filename_relative_path(size),
                                open(@df.filename_with_thumbs(size)),@@bucket, 
                                :access => @df.private? ? :private : :public_read )
      end
      return true
    rescue Exception => e
      raise e
      return false
    end
    
  end
  
  
  # Download the files and put them in a regular directory
  def copy_local!()
    file_sizes.each do |size|
      filename = @df.filename_with_thumbs(size)
      if(!File.exists?(filename)) # Only do it if the file doesn't exist locally
        dir_name = File.dirname(@df.absolute_file_path(size))
        FileUtils.mkpath(dir_name) if(!File.exists?(dir_name))
        open(@df.filename(size),'w') do |file|
          AWS::S3::S3Object.stream(@df.filename_relative_path(size),@@bucket) { |chunk| file.write chunk }
        end
      end
    end
  end
  
  def destroy_remote!()
    file_sizes.each do |size|
      AWS::S3::S3Object.delete(@df.filename_relative_path(size),@@bucket)
    end  
  end
  
  
  def make_private!(value)
    # TO DO - Change ACL
  end
  
  def url(size=nil)
    # return the normal directory structure  
    if @df.private?
      AWS::S3::S3Object.url_for(@df.filename_relative_path(size),@@bucket).gsub("http://s3.amazonaws.com/#{@@bucket}/","http://#{@@bucket}.s3.amazonaws.com/")
    else
      AWS::S3::S3Object.url_for(@df.filename_relative_path(size),@@bucket,:authenticated => false).gsub("http://s3.amazonaws.com/#{@@bucket}/","http://#{@@bucket}.s3.amazonaws.com/")
    end
  end
  
  def full_url(size=nil)
    self.url(size)
  end

  def self.validate_bucket(options=nil)
    begin
      self.connect(options)
      buckets = AWS::S3::Bucket.list.collect(&:name)
      if(!buckets.include?(@@bucket))
        AWS::S3::Bucket.create(@@bucket)
      end
      return true
    rescue Exception => e
      return false
    end
  end

  def self.connect(options = nil)
    opts = options || S3::AdminController.module_options
    AWS::S3::Base.establish_connection!(
      :access_key_id     => opts.access_key_id,
      :secret_access_key => opts.secret_access_key
    )
    @@bucket = opts.bucket

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
