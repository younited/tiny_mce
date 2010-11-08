module PluginAWeek #:nodoc:
  # Adds helper methods for generating the TinyMCE initialization script
  # within your views
  module TinyMce
    
    module TinyMceHelper
      
      # Is TinyMCE being used?
      def using_tiny_mce?
        @uses_tiny_mce
      end
    
      # Create the TinyMCE initialization scripts.  The default configuration
      # is for a simple theme that replaces all textareas on the page.  For
      # example, the default initialization script will generate the following:
      # 
      #  tinyMCE.init({
      #    'mode' : 'textareas',
      #    'theme' : 'simple'
      #  });
      # 
      # == Customizing initialization options
      # 
      # To customize the options to be included in the initialization script,
      # you can pass in a hash to +tiny_mce_init_script+.  For example,
      # 
      #   tiny_mce_init_script(
      #     :theme => 'advanced',
      #     :editor_selector => 'rich_text',
      #     :content_css => '/stylesheets/tiny_mce_content.css',
      #     :editor_css => '/stylesheets/tiny_mce_editor.css',
      #     :auto_reset_designmode => true
      #   )
      # 
      # will generate:
      # 
      #  tinyMCE.init({
      #    'mode' : 'textareas',
      #    'theme' : 'advanced',
      #    'editor_selected' : 'rich_text',
      #    'content_css' : '/stylesheets/tiny_mce_content.css'
      #  });
      # 
      # == Validating options
      # 
      # If additional options are passed in to initialize TinyMCE, they will be
      # validated against the list of valid options in PluginAWeek::TinyMCEHelper#valid_options.
      # These options are configured in the file config/tiny_mce_options.yml.
      # You can generate this file by invoke the rake task tiny_mce:update_options.
      def tiny_mce_init_script(options = @tiny_mce_options)
        options ||= {}
        options.stringify_keys!.reverse_merge!(
          'mode' => 'textareas',
          'theme' => 'simple'
        )
      
        # Check validity
        plugins = options['plugins']
        options_to_validate = options.reject {|option, value| plugins && plugins.include?(option.split('_')[0]) || option =~ TinyMce::DYNAMIC_OPTIONS}
        options_to_validate.assert_valid_keys(TinyMce.valid_options) if TinyMce.valid_options && TinyMce.valid_options.any?
      
        init_script = 'tinyMCE.init({'
      
        options.sort.each do |key, value|
          init_script += "\n#{key} : "
        
          case value
            when String, Symbol, Fixnum
              init_script << "'#{value}'"
            when Array
              init_script << "'#{value.join(',')}'"
            when TrueClass
              init_script << 'true'
            when FalseClass
              init_script << 'false'
            else
              raise ArgumentError, "Cannot parse value of type #{value.class} passed for TinyMCE option #{key}"
          end
        
          init_script << ','
        end
      
        init_script.chop << "\n});"
      end
    
      # Generate the TinyMCE. Any arguments will be passed to tiny_mce_init_script.
      def tiny_mce(*args)
        javascript_tag tiny_mce_init_script(*args)
      end
    
      # The name of the TinyMCE javascript file to use.  In development, this
      # will use the source (uncompressed) file in order to help with debugging
      # issues that occur within TinyMCE.  In production, the compressed version
      # of TinyMCE will be used in order to increased download speed.
      def tiny_mce_file_name
        Rails.env == 'development' ? 'tiny_mce/tiny_mce_src' : 'tiny_mce/tiny_mce'
      end
    
      # Generates the javascript include for TinyMCE.  For example,
      # 
      #   javascript_include_tiny_mce
      # 
      # will generate:
      # 
      #   <script type="text/javascript" src="/javascripts/tiny_mce/tiny_mce.js"></script>
      def javascript_include_tiny_mce
        javascript_include_tag tiny_mce_file_name
      end
    
      # Conditionally includes the TinyMCE javascript file if the variable
      # @uses_tiny_mce has been set to true.
      def javascript_include_tiny_mce_if_used
        javascript_include_tiny_mce if using_tiny_mce?
      end
    end
  end
end

ActionController::Base.class_eval do
  helper PluginAWeek::TinyMce::TinyMceHelper
end
