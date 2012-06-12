require 'trollop'

module SimpleDeploy
  module CLI
    def self.start
      @opts = Trollop::options do
        banner <<-EOS

Deploy and manage resources in AWS

simple_deploy list -e ENVIRONMENT
simple_deploy create -n STACK_NAME -e ENVIRONMENT -a ATTRIBUTES -t TEMPLATE_PATH
simple_deploy update -n STACK_NAME -e ENVIRONMENT -a ATTRIBUTES
simple_deploy deploy -n STACK_NAME -e ENVIRONMENT
simple_deploy destroy -n STACK_NAME -e ENVIRONMENT
simple_deploy instances -n STACK_NAME -e ENVIRONMENT
simple_deploy status -n STACK_NAME -e ENVIRONMENT
simple_deploy attributes -n STACK_NAME -e ENVIRONMENT
simple_deploy events -n STACK_NAME -e ENVIRONMENT
simple_deploy resources -n STACK_NAME -e ENVIRONMENT
simple_deploy outputs -n STACK_NAME -e ENVIRONMENT
simple_deploy template -n STACK_NAME -e ENVIRONMENT

EOS
        opt :help, "Display Help"
        opt :attributes, "CSV list of updates attributes", :type => :string
        opt :environment, "Set the target environment", :type => :string
        opt :name, "Stack name to manage", :type => :string
        opt :template, "Path to the template file", :type => :string
      end

      @cmd = ARGV.shift

      case @cmd
      when 'create', 'delete', 'deploy', 'destroy', 'instances',
           'status', 'attributes', 'events', 'resources',
           'outputs', 'template', 'update'
        @stack = Stack.new :environment => @opts[:environment],
                           :name        => @opts[:name]
      end

      read_attributes

      case @cmd
      when 'attributes'
        @stack.attributes.each_pair { |k, v| puts "#{k}: #{v}" }
      when 'create'
        @stack.create :attributes => attributes,
                      :template => @opts[:template]
        puts "#{@opts[:name]} created."
      when 'delete', 'destroy'
        @stack.destroy
        puts "#{@opts[:name]} destroyed."
      when 'deploy'
        @stack.deploy
        puts "#{@opts[:name]} deployed."
      when 'update'
        @stack.update :attributes => attributes
        puts "#{@opts[:name]} updated."
      when 'instances'
        @stack.instances.each { |s| puts s }
      when 'list'
        s = StackLister.new @opts[:environment]
        puts s.all
      when 'template'
        jj @stack.template
      when 'events', 'outputs', 'resources', 'status'
        puts (@stack.send @cmd.to_sym).to_yaml
      else
        puts "Unknown command.  Use -h for help."
      end
    end

    def self.attributes
      attrs = []
      read_attributes.each do |attribs|
        a = attribs.split('=')
        attrs << { a.first => a.last }
      end
      attrs
    end

    def self.read_attributes
      @opts[:attributes].nil? ? [] :  @opts[:attributes].split(',')
    end                                         
  end
end
