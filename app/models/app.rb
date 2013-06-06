class App
  cattr_accessor :settings

  class << self
    def load!
      my_file = Rails.root.join('config', 'app.yml')
      example_file = Rails.root.join('config', 'app.yml.example')
      file = File.exists?(my_file) ? my_file : example_file
      self.settings = YAML.load_file(file)
    end

    def reload!
      load!
    end

    def method_missing(name, *args, &block)
      load! if settings.nil?
      settings[name.to_s] || super
    end

  end # end class << self

end

App.load!
