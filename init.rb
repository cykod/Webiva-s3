load_paths.each do |path|
  Dependencies.load_once_paths.delete(path)
end

#config.gem 'aws-s3', :lib =>  'aws/s3'
