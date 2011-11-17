module Rubydora

  # Provide low-level access to the Fedora Commons REST API
  module RestApiClient
    # Fedora API documentation available at {https://wiki.duraspace.org/display/FCR30/REST+API}
    API_DOCUMENTATION = 'https://wiki.duraspace.org/display/FCR30/REST+API'
    VALID_CLIENT_OPTIONS = [:user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key]
    # Create an authorized HTTP client for the Fedora REST API
    # @param [Hash] config
    # @option config [String] :url
    # @option config [String] :user
    # @option config [String] :password
    # @return [RestClient::Resource]
    def client config = {}
      config = self.config.merge(config)
      url = config[:url]
      config.delete_if { |k,v| not VALID_CLIENT_OPTIONS.include?(k) }
      config[:open_timeout] ||= config[:timeout]
      @client ||= RestClient::Resource.new(url, config)
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def next_pid options = {}
      options[:format] ||= 'xml'
      begin
        return client[url_for(object_url() + "/nextPID", options)].post nil
      rescue => e
        logger.error e.response
        raise "Error getting nextPID. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @return [String]
    def find_objects options = {}
      raise "" if options[:terms] and options[:query]
      options[:resultFormat] ||= 'xml'

      begin
        return client[object_url(nil, options)].get
      rescue => e
        logger.error e.response
        raise "Error finding objects. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object options = {}
      pid = options.delete(:pid)
      options[:format] ||= 'xml'
      begin
        return client[object_url(pid, options)].get
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue => e
        logger.error e.response
        raise "Error getting object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def ingest options = {}
      pid = options.delete(:pid) || 'new'
      file = options.delete(:file)
      begin
        return client[object_url(pid, options)].post file, :content_type => 'text/xml'
      rescue => e
        logger.error e.response
        raise "Error ingesting object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def modify_object options = {}
      pid = options.delete(:pid)
      begin
        return client[object_url(pid, options)].put nil
      rescue => e
        logger.error e.response
        raise "Error modifying object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_object options = {}
      pid = options.delete(:pid)
      begin
        return client[object_url(pid, options)].delete
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue => e
        logger.error e.response
        raise "Error purging object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_versions options = {}
      pid = options.delete(:pid)
      options[:format] ||= 'xml'
      raise "" unless pid
      begin
        return client[url_for(object_url(pid) + "/versions", options)].get
      rescue => e
        logger.error e.response
        raise "Error getting versions for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def object_xml options = {}
      pid = options.delete(:pid)
      raise "" unless pid
      options[:format] ||= 'xml'
      begin
        return client[url_for(object_url(pid) + "/objectXML", options)].get
      rescue => e
        logger.error e.response
        raise "Error getting objectXML for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      options[:format] ||= 'xml'
      begin
        return client[datastream_url(pid, dsid, options)].get
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue => e
        logger.error e.response
        raise "Error getting datastream '#{dsid}' for object #{pid}. See logger for details"
      end
    end

    alias_method :datastreams, :datastream

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def set_datastream_options options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      begin
        return client[datastream_url(pid, dsid, options)].put nil
      rescue => e
        logger.error e.response
        raise "Error setting datastream options on #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_versions options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      raise ArgumentError, "Must supply dsid" unless dsid
      options[:format] ||= 'xml'
      begin
        return client[url_for(datastream_url(pid, dsid) + "/versions", options)].get
      rescue => e
        logger.error e.response
        raise "Error getting versions for datastream #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def datastream_dissemination options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      raise "" unless dsid
      begin
        return client[url_for(datastream_url(pid, dsid) + "/content", options)].get
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue => e
        logger.error e.response
        raise "Error getting dissemination for datastream #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def add_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:content)
      content_type = options.delete(:content_type) || options[:mimeType] || (MIME::Types.type_for(file.path).first if file.respond_to? :path) || 'text/plain'
      begin
        return client[datastream_url(pid, dsid, options)].post file, :content_type => content_type.to_s, :multipart => true
      rescue => e
        logger.error e.response
        raise "Error adding datastream #{dsid} for object #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def modify_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      file = options.delete(:content)
      content_type = options.delete(:content_type) || options[:mimeType] || (MIME::Types.type_for(file.path).first if file.respond_to? :path) || 'text/plain'

      begin
        return client[datastream_url(pid, dsid, options)].put(file, {:content_type => content_type.to_s, :multipart => true})
      rescue => e
        logger.error e.response
        raise "Error modifying datastream #{dsid} for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :dsid
    # @return [String]
    def purge_datastream options = {}
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      begin
        client[datastream_url(pid, dsid, options)].delete
      rescue => e
        logger.error e.response
        raise "Error purging datastream #{dsid} for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def relationships options = {}
      pid = options.delete(:pid) || options[:subject]
      raise "" unless pid
      options[:format] ||= 'xml'
      begin
        return client[url_for(object_url(pid) + "/relationships", options)].get
      rescue => e
        logger.error e.response
        raise "Error getting relationships for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def add_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      begin
        return client[url_for(object_url(pid) + "/relationships/new", options)].post nil
      rescue => e
        logger.error e.response
        raise "Error adding relationship for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @return [String]
    def purge_relationship options = {}
      pid = options.delete(:pid) || options[:subject]
      begin
        return client[url_for(object_url(pid) + "/relationships", options)].delete
      rescue => e
        logger.error e.response
        raise "Error purging relationships for #{pid}. See logger for details"
      end
    end

    # {include:RestApiClient::API_DOCUMENTATION}
    # @param [Hash] options
    # @option options [String] :pid
    # @option options [String] :sdef
    # @option options [String] :method
    # @return [String]
    def dissemination options = {}
      pid = options.delete(:pid)
      sdef = options.delete(:sdef)
      method = options.delete(:method)
      options[:format] ||= 'xml' unless pid and sdef and method
      begin
        return client[dissemination_url(pid,sdef,method,options)].get
      rescue => e
        logger.error e.response
        raise "Error getting dissemination for #{pid}. See logger for details"
      end
    end
    
    # Generate a REST API compatible URI 
    # @param [String] base base URI
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def url_for base, options = nil
      return base unless options.is_a? Hash
      "#{base}" + (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')
    end

    # Generate a base object REST API endpoint URI
    # @param [String] pid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def object_url pid = nil, options = nil
      url_for("objects" + (("/#{CGI::escape(pid.to_s.gsub('info:fedora/', ''))}" if pid) || ''), options)
    end

    # Generate a base object dissemination REST API endpoint URI
    # @param [String] pid
    # @param [String] sdef
    # @param [String] method
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def dissemination_url pid, sdef = nil, method = nil, options = nil
      raise "" unless pid
      url_for(object_url(pid) + "/methods" +  (("/#{CGI::escape(sdef)}" if sdef) || '') +  (("/#{CGI::escape(method)}" if method) || ''), options)
    end

    # Generate a base datastream REST API endpoint URI
    # @param [String] pid
    # @param [String] dsid
    # @param [Hash] options to convert to URL parameters
    # @return [String] URI
    def datastream_url pid, dsid = nil, options = nil
      raise "" unless pid
      url_for(object_url(pid) + "/datastreams" + (("/#{CGI::escape(dsid)}" if dsid) || ''), options)
    end

  end
end
