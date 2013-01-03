require 'dm-core'
require 'dm-types'

module DataMapper
  module Is
    module Locatable
      def is_locatable(options = {})
        extend  DataMapper::Is::Locatable::ClassMethods
        include DataMapper::Is::Locatable::InstanceMethods

        @locatable_options = {
          by: :id
        }.merge(options)

        # needed to generate nested paths
        protected :relationships

        # we need to make sure that locatable models will inherit the options
        after_class_method :inherited do |retval, target|
          target.instance_variable_set(:@locatable_options, @locatable_options.dup)
        end
      end

      module InstanceMethods

        private

        # many-to-one relationships
        def mto_relationships
          rset = []
          self.relationships.each { |r|
            if r.is_a?(DataMapper::Associations::ManyToOne::Relationship)
              rset << r if r.instance_variable_get('@required')
            end
          }
          rset
        end

        public

        def is_locatable?
          true
        end

        # Accepted options:
        # => shallow: Boolean
        #    When true, the url of this resource will skip nesting within its parent's (if any)
        def url_for(options = {})
          p = []

          shallow = model.locatable_options[:shallow]
          shallow = options[:shallow] if options.has_key?(:shallow)

          unless shallow
            mto_relationships.each { |r|
              parent = self.send(r.name)
              if parent && parent.is_locatable?
                p << parent.url_for(shallow: true)# model.locatable_options[:shallow])
                break
              end
            }
          end

          p << self.class.url_for
          p << attribute_get(options[:by] || model.locatable_options[:by]).to_s
          p
        end
      end

      module ClassMethods
        attr_reader :locatable_options

        def url_for()
          DataMapper::Inflector.pluralize(self.name.split('::').last.downcase)
        end
      end
    end
  end

  Model.append_extensions(Is::Locatable)
end