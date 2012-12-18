require 'string'
require 'composite_option'
require 'array_option'
require 'option'
require 'event'

module CodeGen
    TYPES = ['Object',
             'Date',
             'Array',
             'String',
             'Number',
             'Boolean',
             'Function']

class Component
    attr_reader :name, :full_name, :options, :events

    def initialize(settings)
        @full_name = settings[:name]
        @name = @full_name.split('.').last
        @options = []
        @events = []
    end

    def import(metadata)
        metadata[:options].each do |option|

            @options.delete_if { |o| o.name == option[:name] }

            add_option(option)

        end
    end

    def composite_options
        @options.find_all { |option| option.composite? }.sort {|a, b| a.name <=> b.name }
    end

    def composite_option_class
        CompositeOption
    end

    def option_class
        Option
    end

    def event_class
        Event
    end

    def add_option(settings)
        name = settings[:name].strip.sub(/\s*type\s*[=:][^\.]*\.?/, '')

        recursive = settings[:recursive]

        description = settings[:description]

        types = settings[:type]

        return unless types

        parents = @options.find_all { |option| name.start_with?(option.name + '.') && option.type =~ /Object|Array/ }

        parents.map! { |parent| parent.to_composite }

        types.split('|').each do |type|
            type = type.strip

            next unless TYPES.include?(type)

            next if @options.any? { |option| option.name == name && option.type == type }

            if parents.any?

                parents.each do |parent|

                    parent.add_option(:name => name,
                                      :type => type,
                                      :recursive => recursive,
                                      :description => description)
                end

            else

                @options.push option_class.new(:name => name,
                                               :owner => self,
                                               :recursive => recursive,
                                               :type => type,
                                               :description => description)

            end
        end
    end

    def add_event(settings)
        settings[:owner] = self
        @events.push event_class.new(settings)
    end
end

end #module CodeGen
