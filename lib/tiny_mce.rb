require 'tiny_mce/tiny_mce_helper'

module PluginAWeek #:nodoc:
  # Adds helper methods for generating the TinyMCE initialization script
  # within your views
  module TinyMce
    # The path to the file which contains all valid options that can be used
    # to configure TinyMCE
    OPTIONS_FILE_PATH = "#{Rails.root}/config/tiny_mce_options.yml"
    
    # A regular expression matching options that are dynamic (i.e. they can
    # vary on an integer or string basis)
    DYNAMIC_OPTIONS = /theme_advanced_buttons|theme_advanced_container/
    
    # Whether or not to use verbose output
    mattr_accessor :verbose
    @@verbose = true
    
    # A list of all valid options that can be used to configure TinyMCE
    mattr_accessor :valid_options
    @@valid_options = File.exists?(OPTIONS_FILE_PATH) ? File.open(OPTIONS_FILE_PATH) {|f| YAML.load(f.read)} : []
    
    class << self
      # Installs TinyMCE by downloading it and adding it to your application's
      # javascripts folder.
      # 
      # Configuration options:
      # * +version+ - The version of TinyMCE to install. Default is the latest version.
      # * +target+ - The path to install TinyMCE to, relative to the project root. Default is "public/javascripts/tiny_mce"
      # * +force+ - Whether to install TinyMCE, regardless of whether it already exists on the filesystem.
      # 
      # == Versions
      # 
      # By default, this will install the latest version of TinyMCE.  You can
      # install a specific version of TinyMCE (if you are using an old API) by
      # passing in the version number.
      # 
      # For example,
      #   PluginAWeek::TinyMCEHelper.install                      # Installs the latest version
      #   PluginAWeek::TinyMCEHelper.install(:version => '2.0.8') # Installs version 2.0.8
      # 
      # An exception will be raised if the specified version cannot be found.
      # 
      # == Target path
      # 
      # By default, this will install TinyMCE into Rails.root/public/javascripts/tiny_mce.
      # If you want to install it to a different directory, you can pass in a
      # parameter with the relative path from Rails.root.
      # 
      # For example,
      #   PluginAWeek::TinyMCEHelper.install(:target => 'public/javascripts/richtext')
      # 
      # == Conflicting paths
      # 
      # If TinyMCE is found to already be installed on the filesystem, a prompt
      # will be displayed for whether to overwrite the existing directory.  This
      # prompt can be automatically skipped by passing in the :force option.
      def install(options = {})
        options.assert_valid_keys(:version, :target, :force)
        options.reverse_merge!(:force => false)
        
        version = options[:version]
        base_target = options[:target] || 'public/javascripts/tiny_mce'
        source_path = 'tinymce'
        target_path = File.expand_path(File.join(Rails.root, base_target))
        
        # If TinyMCE is already installed, make sure the user wants to continue
        if !options[:force] && File.exists?(target_path)
          print "TinyMCE already installed in #{target_path}. Overwrite? (y/n): "
          while !%w(y n).include?(option = STDIN.gets.chop)
            print "Invalid option. Overwrite #{target_path}? (y/n): "
          end
          return if option == 'n'
        end
        
        # Get the url of the TinyMCE version
        require 'hpricot'
        require 'open-uri'
        
        doc = Hpricot(open('http://sourceforge.net/project/showfiles.php?group_id=103281&package_id=111430'))
        if version
          version.gsub!('.', '_')
          file_element = (doc/'tr[@id*="rel0_"] a').detect {|file| file.innerHTML =~ /#{version}.zip$/}
          raise ArgumentError, "Could not find TinyMCE version #{version}" if !file_element
        else
          file_element = (doc/'tr[@id^="pkg0_1rel0_"] a').detect {|file| file.innerHTML.to_s =~ /\d\.zip$/}
          raise ArgumentError, 'Could not find latest TinyMCE version' if !file_element
        end
        
        filename = file_element.innerHTML
        file_url = file_element['href']
        
        # Download the file
        puts 'Downloading TinyMCE source...' if verbose
        file = open(file_url).path
        
        # Extract and install
        puts 'Extracting...' if verbose
        
        require 'zip/zip'
        require 'zip/zipfilesystem'
        
        Zip::ZipFile::open(file) do |zipfile|
          zipfile.entries.each do |entry|
            if match = /tinymce\/jscripts\/tiny_mce\/(.*)/.match(entry.name)
              FileUtils.mkdir_p("#{target_path}/#{File.dirname(match[1])}")
              entry.extract("#{target_path}/#{match[1]}") { true }
            end
          end
        end
        
        puts 'Done!' if verbose
      end
      
      # Uninstalls the TinyMCE installation and optional configuration file
      # 
      # Configuration options:
      # * +target+ - The path that TinyMCE was installed to. Default is "public/javascripts/tiny_mce"
      def uninstall(options = {})
        # Remove the TinyMCE configuration file
        File.delete(OPTIONS_FILE_PATH)
        
        # Remove the TinyMCE installation
        FileUtils.rm_rf(options[:target] || "#{Rails.root}/public/javascripts/tiny_mce")
      end
      
      # Updates the list of possible configuration options that can be used
      # when initializing the TinyMCE script.  These are always installed to
      # the application folder, config/tiny_mce_options.yml.  If this file
      # does not exist, then the TinyMCE helper will not be able to verify
      # that all of the initialization options are valid.
      def update_options
        require 'hpricot'
        require 'open-uri'
        require 'yaml'
        
        puts 'Downloading configuration options from TinyMCE Wiki...' if verbose
        doc = Hpricot(open('http://wiki.moxiecode.com/index.php/TinyMCE:Configuration'))
        options = (doc/'a[@title*="Configuration/"]/').collect {|option| option.to_s}.sort
        options.reject! {|option| option =~ DYNAMIC_OPTIONS}
        
        File.open(OPTIONS_FILE_PATH, 'w') do |out|
          YAML.dump(options, out)
        end
        puts 'Done!' if verbose
      end
    end
    
  end
end
