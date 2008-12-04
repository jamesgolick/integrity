module Integrity
  class Notifier
    include DataMapper::Resource
    
    property :id,      Integer,  :serial => true
    property :name,    String,   :nullable => false
    property :config,  Yaml,     :nullable => false, :lazy => false
    
    belongs_to :project, :class_name => "Integrity::Project"
    
    validates_is_unique :name, :scope => :project_id
    validates_present :project_id
    
    class << self
      def available
        @available ||= constants.map { |name| const_get(name) }.select { |notifier| valid_notifier?(notifier) }
      end
      
      def enable_notifiers(project, enabled, config={})
        all(:project_id => project).destroy!
        list_of_enabled_notifiers(enabled).each do |name|
          create! :project_id => project, :name => name, :config => config[name]
        end
      end
      
      private
        def list_of_enabled_notifiers(names)
          [*names].reject { |n| n.nil? }
        end

        def valid_notifier?(notifier)
          notifier.respond_to?(:to_haml) && notifier.respond_to?(:notify_of_build) && notifier != Notifier::Base
        end
    end
    
    def notify_of_build(build)
      to_const.notify_of_build(build, config)
    end
    
    private
      
      def to_const
        self.class.module_eval(name)
      end
  end
end

require File.dirname(__FILE__) / 'notifier' / 'base'

Dir["#{File.dirname(__FILE__)}/notifier/*.rb"].each &method(:require)
