require 'right_aws'

class S3::Bucket
  attr_accessor :access_key_id, :secret_access_key, :name

  def initialize(access_key_id, secret_access_key, name)
    self.access_key_id = access_key_id
    self.secret_access_key = secret_access_key
    self.name = name
  end

  def s3
    # By default S3 connections are stored(:shared) in Thread.current[aws_service].
    # By setting connections to :dedicated they are stored per instance.
    # for details look in right_awsbase.rb module RightAws::RightAwsBaseInterface - get_connection
    @s3 ||= RightAws::S3.new self.access_key_id, self.secret_access_key, :connections => :dedicated
  end

  def bucket
    return @bucket if @bucket
    @bucket = self.s3.bucket(self.name)
    @bucket = self.s3.bucket(self.name, true) unless @bucket
    @bucket
  end

  def buckets
    self.s3.buckets
  end

  def self.valid_bucket_name?(name)
    # expression taken from AWS::S3::Bucket.validate_name!
    name =~ /^[-\w.]{3,255}$/ ? true : false
  end

  # Store data on S3
  #
  # The +perms+ param can take these values: 'private', 'public-read', 'public-read-write' and 'authenticated-read'. 
  def store(key, data, perm=nil, mime_type=nil)
    return false unless self.class.valid_key?(key)
    self.bucket.put(key, data, {}, perm, { 'content-type' => mime_type})
  end

  def delete(key)
    item = self.bucket.key(key)
    item ? item.delete : false
  end

  def copy_local!(key, filename)
    begin
      File.open(filename, 'w') do |file|
        file.write self.bucket.get(key)
      end
      return true
    rescue RightAws::AwsError => e
      FileUtils.rm(filename)
      return false
    end
  end

  def url_for(key, options={})
    if options[:private]
      self.s3.interface.get_link(self.name, key)
    else
      "http://#{self.host}/#{key}"
    end
  end

  def host
    "#{self.name}.s3.amazonaws.com"
  end

  def make_public!(key)
    item = self.bucket.key key
    return false unless item
    grant = RightAws::S3::Grantee.new(item, 'http://acs.amazonaws.com/groups/global/AllUsers')
    grant.grant('READ')
  end

  def make_private!(key)
    item = self.bucket.key key
    return false unless item

    # remove all grants that are not the owners
    item.grantees.each do |grant|
      next if item.owner.id == grant.id
      grant.drop
    end
  end

  def self.valid_key?(key)
    # take from AWS::S3::Object
    key && key.size <= 1024
  end

  def path(key)
    '/' << File.join(self.bucket, key)
  end

end
