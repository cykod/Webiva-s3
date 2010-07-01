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

  def prefixed_filename(size)
    prefix = @df.version_count > 0 ? "#{@df.version_count}/" : ''
    @df.prefixed_filename(size, :prefix => prefix)
  end

  # Copy local files to the remote server
  def copy_remote!(size=nil)
    begin
      (size ? [ size ] : file_sizes).each do |size|
        @connection.store(self.prefixed_filename(size),
                                File.open(@df.local_filename(size)),
                                @df.private? ? 'private' : 'public-read') if File.exists?(@df.local_filename(size))
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
        @connection.delete(self.prefixed_filename(size)) if size 
      rescue Exception => e
        # Chomp all
      end
    end
  end

  def revision_support; true; end

  def create_remote_version!(version)
    @connection.store(version.prefixed_filename,File.open(version.abs_filename),'private')
    return true
  end
  
  def destroy_remote_version!(version)
    @connection.delete(version.prefixed_filename)
  end

  def version_url(version)
    self.url_for(version.prefixed_filename, :private => true)
  end

  # Download the files and put them in a regular directory
  def copy_local!(dest_size=nil)
    (dest_size ? [dest_size] : file_sizes).each do |size|
      filename = @df.local_filename(size)
      if(!File.exists?(filename)) # Only do it if the file doesn't exist locally
        dir_name = File.dirname(filename)
        FileUtils.mkpath(dir_name) if(!File.exists?(dir_name))
        @connection.copy_local! self.prefixed_filename(size), filename
      end
    end
  end
  
  def destroy_remote!()
    file_sizes.each do |size|
      begin
        @connection.delete(self.prefixed_filename(size))
      rescue Exception => e
        # Chomp
      end
    end  
  end

  def update_private!(value)
    # Get the bucket policy (which is owner read only)
    file_sizes.each do |size|
      if value
        @connection.make_private! self.prefixed_filename(size)
      else
        @connection.make_public! self.prefixed_filename(size)
      end
    end
    if value && !@df.private?
       FileUtils.rm_rf(@df.abs_storage_directory)
    end
    @df.update_attribute(:private,value)
  end

  
  def url(size=nil)
    self.url_for self.prefixed_filename(size), :private => @df.private?
  end
  
  def full_url(size=nil)
    self.url(size)
  end

  def url_for(key, options={})
    S3::AdminController.module_options.url_for(key, options)
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
