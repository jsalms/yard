module YARD
  module Generators
    class TagsGenerator < Base
      before_section :header,  :has_tags?
      before_section :option, :has_options?
      
      def sections_for(object)
        [:header, [:param, :option, :yieldparam, :return, :raise, :author, :version, :since, :see]]
      end
      
      def param(object)
        render_tags :param
      end
      
      def yieldparam(object)
        render_tags :yieldparam
      end
      
      def return(object)
        render_tags :return
      end
      
      def raise(object)
        render_tags :raise, :no_names => true
      end
      
      def author(object)
        render_tags :author, :no_types => true, :no_names => true
      end

      def version(object)
        render_tags :version, :no_types => true, :no_names => true
      end

      def since(object)
        render_tags :since, :no_types => true, :no_names => true
      end
      
      protected
      
      def has_tags?(object)
        object.tags.size > 0
      end
      
      def has_options?(object)
        object.has_tag?(:option)
      end
      
      def render_tags(name, opts = {})
        opts = { :name => name }.update(opts)
        render(current_object, 'tags', opts)
      end
    end
  end
end