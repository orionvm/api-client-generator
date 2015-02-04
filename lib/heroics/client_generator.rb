require 'fileutils'

module Heroics
  # Generate a static client that uses Heroics under the hood.  This is a good
  # option if you want to ship a gem or generate API documentation using Yard.
  #
  # @param module_name [String] The name of the module, as rendered in a Ruby
  #   source file, to use for the generated client.
  # @param schema [Schema] The schema instance to generate the client from.
  # @param url [String] The URL for the API service.
  # @param options [Hash] Configuration for links.  Possible keys include:
  #   - default_headers: Optionally, a set of headers to include in every
  #     request made by the client.  Default is no custom headers.
  #   - cache: Optionally, a Moneta-compatible cache to store ETags.  Default
  #     is no caching.
  PREPROCESSOR_FILENAME = 'view_preprocessor.rb'

  def self.generate_client(schema, view, output_folder, options)
    if Pathname.new(view).absolute?
      path = view
    else
      path = File.join(File.dirname(__FILE__), "views", view)
    end

    context = build_context(schema, options)
    pre_processor = File.join(path, PREPROCESSOR_FILENAME)
    if File.exists?(pre_processor)
      require pre_processor
      begin
        context = transform_context(context)
      rescue NoMethodError
        raise "view_preprocessor.rb must define method 'transform_context(context)' that returns a modified context hash"
      end
    end

    self.process_dir(schema, path, output_folder, context, "")
  end

  def self.process_dir(schema, input, output, context, current)
    FileUtils.mkdir_p File.join(output, current % context)
    Dir.foreach File.join(input, current) do |item|
      next if item == "." || item == ".." || (item == PREPROCESSOR_FILENAME && current == '')
      if File.directory?(File.join(input, current, item))
        self.process_dir(schema, input, output, context, File.join(current, item))
      else
        if item.end_with? ".erb"
          outfilename = item.sub(%r{\.erb\z}, "")
          outfile = File.join(output, current, outfilename) % context 
          File.open(outfile, 'w') do |file|
            file.write(self.process_erb(schema, File.join(input, current, item), context))
          end
        else
          outfile = File.join(output, current, item) % context 
          FileUtils.cp(File.join(input, current, item), outfile)
        end
      end
    end
  end

  def self.process_erb(schema, filename, context)
    eruby = Erubis::Eruby.new(File.read(filename))
    eruby.evaluate(context)
  end

  private

  # Process the schema to build up the context needed to render the source
  # template.
  def self.build_context(schema, options)
    resources = []
    schema.resources.each do |resource_schema|
      links = []
      resource_schema.links.each do |link_schema|
        params = link_schema.parameter_details.map {|p| "{" + p.name + "}" }
        path, _ = link_schema.format_path(params)
        links << GeneratorLink.new(link_schema.name.gsub('-', '_'),
                                   link_schema.method,
                                   path,
                                   link_schema.description,
                                   link_schema.parameter_details,
                                   link_schema.needs_request_body?)
        #require 'byebug'; byebug
      end
      resources << GeneratorResource.new(resource_schema.name.gsub('-', '_'),
                                         resource_schema.description,
                                         links)
    end

    context = options.merge({
               description: schema.description,
               schema: MultiJson.dump(schema.schema),
               resources: resources
    })
  end

  # A representation of a resource for use when generating source code in the
  # template.
  class GeneratorResource
    attr_reader :name, :description, :links

    def initialize(name, description, links)
      @name = name
      @description = description
      @links = links
    end

    # The name of the resource class in generated code.
    def class_name
      Heroics.camel_case(name)
    end
  end

  # A representation of a link for use when generating source code in the
  # template.
  class GeneratorLink
    attr_reader :name, :method, :path, :description, :parameters, :takes_body

    def initialize(name, method, path, description, parameters, takes_body)
      @name = name.gsub(/[()]/, "")
      @method = method
      @path = path
      @description = description
      @parameters = parameters
      if takes_body
        parameters << BodyParameter.new
      end
    end

    # The list of parameters to render in generated source code for the method
    # signature for the link.
    def parameter_names_string
      @parameters.map { |info| info.name }.join(', ')
    end
  end

  # Convert a lower_case_name to CamelCase.
  def self.camel_case(text)
    return text if text !~ /_/ && text =~ /[A-Z]+.*/
    text = text.split('_').map{ |element| element.capitalize }.join
    [/^Ssl/, /^Http/, /^Xml/].each do |replace|
      text.sub!(replace) { |match| match.upcase }
    end
    text
  end

  def build_link_path(schema, link)
    link['href'].gsub(%r|(\{\([^\)]+\)\})|) do |ref|
      ref = ref.gsub('%2F', '/').gsub('%23', '#').gsub(%r|[\{\(\)\}]|, '')
      ref_resource = ref.split('#/definitions/').last.split('/').first.gsub('-','_')
      identity_key, identity_value = schema.dereference(ref)
      if identity_value.has_key?('anyOf')
        '{' + ref_resource + '_' + identity_value['anyOf'].map {|r| r['$ref'].split('/').last}.join('_or_') + '}'
      else
        '{' + ref_resource + '_' + identity_key.split('/').last + '}'
      end
    end
  end

  # A representation of a body parameter.
  class BodyParameter
    attr_reader :name, :description

    def initialize
      @name = 'body'
      @description = 'the object to pass as the request payload'
    end
  end
end
