

class S3::RequestHandler


  def initialize(controller)
    @controller = controller
  end

  def after_request(output)
    if output.page? && @controller.request.ssl?
      
      for i in (0..output.body.length)
        if(output.body[i].is_a?(String))
          output.body[i] = output.body[i].gsub(/http\:\/\/([a-z\-0-9A-Z]+)\.s3\.amazonaws\.com/,"https://\\1.s3.amazonaws.com")
        elsif output.body[i].is_a?(Hash)
          hsh = output.body[i]
          for k in (0..hsh[:paragraphs].length)
            if hsh[:paragraphs][k].is_a?(String)
              hsh[:paragraphs][k] = hsh[:paragraphs][k].gsub(/http\:\/\/([a-z\-0-9A-Z]+)\.s3\.amazonaws\.com/,"https://\\1.s3.amazonaws.com")
            elsif hsh[:paragraphs][k].is_a?(ParagraphRenderer::ParagraphOutput)
              if hsh[:paragraphs][k].render_args[:text]
                hsh[:paragraphs][k].render_args[:text] = hsh[:paragraphs][k].render_args[:text].gsub(/http\:\/\/([a-z\-0-9A-Z]+)\.s3\.amazonaws\.com/,"https://\\1.s3.amazonaws.com")
              end
            end
          end
        end
      end
    end
    true
  end

end
