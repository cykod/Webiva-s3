
class S3::AdminController < ModuleController


  component_info 'S3', :description => 'Adds support for S3 as a data store', 
                              :access => :private 
           
  register_handler :website, :file,  "S3::DomainFileSupport"
                  
  register_handler :page, :post_process, "S3::RequestHandler"

  def options
   cms_page_info [ ["Options",url_for(:controller => '/options') ], ["Modules",url_for(:controller => "/modules")], "S3 Options"], "options"
    
    @options = Configuration.get_config_model(ModuleOptions,params[:options])
    
    if request.post? && params[:options] && @options.valid?
      if @options.enable_cloud_front
        @options.save_cloud_front_settings
        Configuration.set_config_model(@options)
        redirect_to :action => 'cloud_front_setup'
        return
      else
        @options.clear_cloud_front_settings
      end

      Configuration.set_config_model(@options)
      flash[:notice] = "Updated S3 module settings".t
      redirect_to :controller => '/modules'
      return
    end
  end

  def cloud_front_setup
    cms_page_info [ ["Options",url_for(:controller => '/options') ], ["Modules",url_for(:controller => "/modules")], ["S3 Options", url_for(:action => 'options')], "Cloud Front Setup"], "options"

    @options = Configuration.get_config_model(ModuleOptions,params[:options])

    return redirect_to :action => 'options' unless @options.enable_cloud_front

    unless @options.valid?
      flash[:notice] = "Invalid S3 settings".t 
      redirect_to :action => 'options' 
      return
    end

    if @options.cloud_front_distribution_info && @options.cloud_front_distribution_info[:status] == 'InProgress' && @options.cloud_front.deployed?
      @options.cloud_front_distribution_info = @options.cloud_front.distribution
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated S3 module settings".t
      redirect_to :controller => '/modules'
      return
    end

    if request.post? && params[:options] && @options.valid?
      if @options.save_cloud_front_settings
        Configuration.set_config_model(@options)
        redirect_to :action => 'cloud_front_setup'
        return
      else
        @options.errors.add(:cname, 'is invalid or already in use')
      end
    end
  end

  class ModuleOptions < HashModel
    default_options :access_key_id => nil, :secret_access_key => nil, :bucket => nil, :enable_cloud_front => nil,
      :cloud_front_distribution_info => nil, :cname => nil

    boolean_options :enable_cloud_front

    validates_presence_of :access_key_id, :secret_access_key, :bucket

    def validate
      if self.access_key_id && self.secret_access_key && self.bucket
        # test the connection by making a request for the buckets
        buckets = nil
        begin
          buckets = self.connection.buckets
        rescue RightAws::AwsError
          self.errors.add(:access_key_id, 'is invalid')
          self.errors.add(:secret_access_key, 'is invalid')
        end

        if buckets
          if S3::Bucket.valid_bucket_name?(self.bucket)
            begin
              self.connection.bucket
            rescue RightAws::AwsError
              self.errors.add(:bucket, 'failed to create bucket')
            end
          else
            self.errors.add(:bucket, 'name is invalid')
          end

          if self.enable_cloud_front
            begin
              self.cloud_front.distributions
            rescue RightAws::AwsError
              self.errors.add(:enable_cloud_front, 'failed. Cloud Front subscription is required for this access key')
            end
          end
        end
      end
    end

    def system_options
      @system_options ||= Configuration.system_module_configuration 's3'
    end

    def access_key_id
      if self.system_options
        self.system_options['access_key_id']
      else
        @access_key_id
      end
    end

    def secret_access_key
      if self.system_options
        self.system_options['secret_access_key']
      else
        @secret_access_key
      end
    end

    def bucket
      if self.system_options
        self.system_options['bucket']
      else
        @bucket
      end
    end

    def connection
      @connection ||= S3::Bucket.new self.access_key_id, self.secret_access_key, self.bucket
    end

    def cloud_front
      return @cloud_front if @cloud_front
      aws_id = self.cloud_front_distribution_info ? self.cloud_front_distribution_info[:aws_id] : nil
      @cloud_front = S3::CloudFront.new self.connection, aws_id
    end

    def cloud_front_distribution_id
      self.cloud_front.distribution[:aws_id] if self.cloud_front.distribution
    end

    def cloud_front_domain_name
      self.cloud_front.distribution[:domain_name] if self.cloud_front.distribution
    end

    def cloud_front_origin
      self.cloud_front.distribution[:origin] if self.cloud_front.distribution
    end

    def cloud_front_status
      self.cloud_front.distribution[:status] if self.cloud_front.distribution
    end

    def cloud_front_cname
      if self.cloud_front.distribution && self.cloud_front.distribution[:cnames]
        self.cloud_front.distribution[:cnames][0]
      else
        ''
      end
    end

    def cnames
      self.cname.blank? ? [] : [self.cname]
    end

    def save_cloud_front_settings
      if self.cloud_front.save(self.cnames)
        self.cloud_front_distribution_info = self.cloud_front.distribution
        true
      else
        self.errors.add_to_base('Failed to save cloud front settings')
        false
      end
    end

    def clear_cloud_front_settings
      self.cloud_front_distribution_info = nil
      self.cname = nil
    end

    def valid_cloud_front_settings?
      begin
        # Access Key has a cloud front subscription
        self.cloud_front.distributions
      rescue RightAws::AwsError
        return false
      end

      # make sure the bucket name is the same
      self.cloud_front.origin == self.cloud_front_origin
    end

    def host(opts={})
      return @host if @host

      if ! self.cname.blank?
        @host = self.cname
      elsif self.cloud_front_distribution_info && ! self.cloud_front_distribution_info[:domain_name].blank?
        @host = self.cloud_front_distribution_info[:domain_name]
      else
        @host = self.connection.host
      end
    end

    def secure_host
      @secure_host ||= self.connection.host
    end

    def url_for(key, options={})
      if options[:private]
        self.connection.url_for(key, options)
      else
        "http://#{self.host}/#{key}"
      end
    end

    def secure_output(str)
      str = str.gsub("http://#{self.cname}", "https://#{self.secure_host}") if self.cname
      str = str.gsub("http://#{self.cloud_front_distribution_info[:domain_name]}", "https://#{self.secure_host}") if self.cloud_front_distribution_info && self.cloud_front_distribution_info[:domain_name]
      str = str.gsub("http://#{self.connection.host}", "https://#{self.secure_host}")
      str
    end
  end

  def self.module_options
    Configuration.get_config_model(ModuleOptions)
  end
end

