
class S3::CloudFront
  def initialize(bucket, aws_id=nil)
    @bucket = bucket
    @aws_id = aws_id
  end

  def acf
    @acf ||= RightAws::AcfInterface.new(@bucket.access_key_id, @bucket.secret_access_key, :connections => :dedicated)
  end

  def distributions
    self.acf.list_distributions
  end

  def origin
    "#{@bucket.name}.s3.amazonaws.com"
  end

  def distribution
    return @distribution if @distribution

    begin
      @distribution = self.acf.get_distribution(@aws_id) if @aws_id
      unless @distribution
        # search for distribution with the same origin
        @distribution = self.distributions.find { |dis| dis[:origin] == self.origin }
        if @distribution
          @aws_id = @distribution[:aws_id]
          # get_distribution returns additional information required for updating the distribution, i.e. :e_tag
          @distribution = self.acf.get_distribution(@aws_id)
        end
      end
    rescue RightAws::AwsError
    end

    @distribution
  end

  def save(cnames=[])
    begin
      return self.acf.set_distribution_config(self.distribution[:aws_id], self.distribution.merge(:cnames => cnames, :enabled => true)) if self.distribution

      @distribution = self.acf.create_distribution(self.origin, 'Webiva Cloud Front Support', true, cnames)
      return true
    rescue RightAws::AwsError => e
      Rails.logger.error e.to_s
      return false
    end
  end

  def deployed?
    self.distribution && self.distribution[:status] == 'Deployed'
  end

  def remove_all
    self.distributions.each do |dis|
      next unless dis[:origin] == self.origin
      next unless dis[:status] == 'Deployed'

      config = self.acf.get_distribution dis[:aws_id]
      if config[:enabled]
        self.acf.set_distribution_config config[:aws_id], config.merge(:enabled => false)
      else
        self.acf.delete_distribution config[:aws_id], config[:e_tag]
      end
    end
  end
end
