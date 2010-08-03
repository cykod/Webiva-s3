
class S3::RequestHandler

  def initialize(controller)
    @controller = controller
  end

  def post_process_stylesheet(css)
  @options = S3::AdminController.module_options
    if @controller.request.ssl?
      @options.secure_output(css)
    else
      css
    end
  end

  def post_process(output)
    if output.page? && @controller.request.ssl?
      @options = S3::AdminController.module_options

      output.head = @options.secure_output(output.head.to_s)
      
      for i in (0..output.body.length)
        if(output.body[i].is_a?(String))
          output.body[i] = @options.secure_output(output.body[i])
        elsif output.body[i].is_a?(Hash)
          hsh = output.body[i]
          for k in (0..hsh[:paragraphs].length)
            if hsh[:paragraphs][k].is_a?(String)
              hsh[:paragraphs][k] = @options.secure_output(hsh[:paragraphs][k])
            elsif hsh[:paragraphs][k].is_a?(ParagraphRenderer::ParagraphOutput)
              if hsh[:paragraphs][k].render_args[:text]
                hsh[:paragraphs][k].render_args[:text] = @options.secure_output(hsh[:paragraphs][k].render_args[:text])
              end
            end
          end
        end
      end
    end
    true
  end

end
