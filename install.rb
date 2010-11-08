# Install TinyMCE
puts 'Installing TinyMCE...'
PluginAWeek::TinyMce.install(:version => ENV['VERSION'], :target => ENV['TARGET'])

# Update the configuration options
puts 'Updating TinyMCE configuration options...'
PluginAWeek::TinyMce.update_options
