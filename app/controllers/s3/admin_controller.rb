
class S3::AdminController < ModuleController


  component_info 'S3', :description => 'Adds support for S3 as a data store', 
                              :access => :private 
           
  register_handler :website, :file,  "S3::DomainFileSupport"
                  
  

  def options
  
   cms_page_info [ ["Options",url_for(:controller => '/options') ], ["Modules",url_for(:controller => "/modules")], "S3 Options "], "options"
    
    @options = Configuration.get_config_model(ModuleOptions,params[:options])
    
    if request.post? && params[:options] && @options.valid? 
      if S3::DomainFileSupport.validate_bucket(@options)
        Configuration.set_config_model(@options)
        flash[:notice] = "Updated S3 module settings".t 
        redirect_to :controller => '/modules'
        return
      else
        @options.errors.add(:access_key_id,'is invalid - could not connect to AWS')
      end
    end
    
  end
  
  class ModuleOptions < HashModel
    default_options :access_key_id => nil,:secret_access_key => nil,:bucket => nil
    
    validates_presence_of :access_key_id,:secret_access_key,:bucket
  end
  
  def self.module_options
    Configuration.get_config_model(ModuleOptions)
  end
end

