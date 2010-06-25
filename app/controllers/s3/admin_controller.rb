
class S3::AdminController < ModuleController


  component_info 'S3', :description => 'Adds support for S3 as a data store', 
                              :access => :private 
           
  register_handler :website, :file,  "S3::DomainFileSupport"
                  
  register_handler :page, :after_request, "S3::RequestHandler"

  def options
   cms_page_info [ ["Options",url_for(:controller => '/options') ], ["Modules",url_for(:controller => "/modules")], "S3 Options "], "options"
    
    @options = Configuration.get_config_model(ModuleOptions,params[:options])
    
    if request.post? && params[:options] && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated S3 module settings".t 
      redirect_to :controller => '/modules'
      return
    end
  end
  
  class ModuleOptions < HashModel
    default_options :access_key_id => nil, :secret_access_key => nil, :bucket => nil
    
    validates_presence_of :access_key_id, :secret_access_key, :bucket

    def validate
      if self.access_key_id && self.secret_access_key && self.bucket
        # test the connection by making a request for the buckets
        res = self.connection.request(:get, '/')
        if Net::HTTPSuccess === res
          bucket_info = self.buckets(res).find { |info| info['name'] == self.bucket }
          unless bucket_info
            if S3::Connection.valid_bucket_name?(self.bucket)
              if self.create_bucket
                self.errors.add(:bucket, 'was not found') unless self.buckets(nil, :reload => true).find { |info| info['name'] == self.bucket }
              else
                self.errors.add(:bucket, 'failed to create bucket')
              end
            else
              self.errors.add(:bucket, 'name is invalid')
            end
          end
        else
          self.errors.add(:access_key_id, 'is invalid')
          self.errors.add(:secret_access_key, 'is invalid')
        end
      end
    end

    def connection
      @connection ||= S3::Connection.new :access_key_id => self.access_key_id, :secret_access_key => self.secret_access_key, :bucket => self.bucket
    end

    def buckets(res=nil, opts={})
      self.connection.buckets(res, opts)
    end

    def create_bucket(options={})
      self.connection.create_bucket(options)
    end
  end

  def self.module_options
    Configuration.get_config_model(ModuleOptions)
  end
end

