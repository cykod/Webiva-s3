
class S3::Connection
  attr_accessor :access_key_id, :secret_access_key, :bucket

  def initialize(opts={})
    self.access_key_id = opts[:access_key_id]
    self.secret_access_key = opts[:secret_access_key]
    self.bucket = opts[:bucket]
  end

  def connection
    @connection ||= AWS::S3::Connection.connect :access_key_id => self.access_key_id, :secret_access_key => self.secret_access_key
  end

  def request(verb, path, options={}, body=nil, attempts=0, &block)
    options.replace(RequestOptions.process(options, verb))
    @response = self.connection.request(verb, path, options, body, attempts, &block)
  end

  def buckets(res=nil, opts={})
    return @buckets if @buckets && opts[:reload].nil?
    self.request(:get, '/')
    return [] unless Net::HTTPSuccess === @response
    service_response = AWS::S3::Service::Response.new @response
    @buckets = service_response.buckets
  end

  def create_bucket(options={})
    self.request(:put, "/#{self.bucket}", options)
    return false unless Net::HTTPSuccess === @response
    AWS::S3::Bucket::Response.new(@response).success?
  end

  def delete_bucket(options={})
    self.objects.each { |obj| self.delete(obj.key) }
    self.request(:delete, "/#{self.bucket}", options)
    return false unless Net::HTTPSuccess === @response
    AWS::S3::Bucket::Response.new(@response).success?
  end

  def objects(options={})
    return @objects if @objects && options.delete(:reload).nil?
    self.request(:get, "/#{self.bucket}", options)
    return [] unless Net::HTTPSuccess === @response
    bucket = AWS::S3::Bucket.new(AWS::S3::Bucket::Response.new(@response).bucket)
    @objects = bucket.object_cache
  end

  def self.valid_bucket_name?(bucket)
    # expression taken from AWS::S3::Bucket.validate_name!
    bucket =~ /^[-\w.]{3,255}$/
  end

  def store(key, data, options={})
    return false unless self.valid_key?(key)
    self.class.infer_content_type!(key, options)
    self.request(:put, self.path(key), options, data)
    AWS::S3::S3Object::Response.new(@response)
  end

  def delete(key, options={})
    self.request(:delete, self.path(key), options)
    self.success?
  end

  def value(key, options={}, &block)
    self.request(:get, self.path(key), options, &block)
    AWS::S3::S3Object::Value.new(AWS::S3::S3Object::Response.new(@response))
  end

  def stream(key, options={}, &block)
    self.value(key, options) do |response|
      response.read_body(&block)
    end
  end

  def url_for(name, options={})
    connection.url_for(self.path(name), options)
  end

  def success?
    AWS::S3::S3Object::Response.new(@response).success?
  end

  def acl(name=nil, policy=nil)
    if name.is_a?(AWS::S3::ACL::Policy)
      policy = name
      name   = nil
    end

    path = name ? "/#{self.path(name)}?acl" : "/#{self.bucket}?acl"
    policy ? self.request(:put, path, {}, policy.to_xml) : self.request(:get, path)
    policy_response = AWS::S3::ACL::Policy::Response.new(@response)
    policy ? policy_response : AWS::S3::ACL::Policy.new(policy_response.policy)
  end

  def valid_key?(key)
    # take from AWS::S3::Object
    key && key.size <= 1024
  end

  def path(key)
    '/' << File.join(self.bucket, key)
  end

  def self.infer_content_type!(key, options)
    return if options.has_key?(:content_type)
    if mime_type = MIME::Types.type_for(key).first
      options[:content_type] = mime_type.content_type
    end
  end

  class RequestOptions < Hash #:nodoc:
    attr_reader :options, :verb
            
    class << self
      def process(*args, &block)
        new(*args, &block).process!
      end
    end
            
    def initialize(options, verb = :get)
      @options = options.to_normalized_options
      @verb    = verb
      super()
    end
            
    def process!
      set_access_controls! if verb == :put
      replace(options)
    end
            
    def set_access_controls!
      AWS::S3::ACL::OptionProcessor.process!(options)
    end
  end
end
