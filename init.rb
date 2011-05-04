
# Copyright (C) 2009 Pascal Rettig.

webiva_remove_load_paths(__FILE__)

config.gem 'right_aws', :version => '2.0.0'
if RAILS_ENV=='test'
  config.gem 'fakeweb'
end

