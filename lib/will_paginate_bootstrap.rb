module WillPaginate
  module Sinatra
    class BootstrapLinkRenderer < LinkRenderer
      protected

      def html_container(html)
        tag :nav, tag(:ul, html, class: ul_class)
      end

      def page_number(page)
        tag :li, link(page, page, rel: rel_value(page)), class: ('active' if page == current_page)
      end

      def gap
        tag :li, link('&hellip;'.html_safe, '#'), class: 'disabled'
      end

      def previous_or_next_page(page, text, classname)
        tag :li, link(text, page || '#'), class: [(classname[0..3] if  @options[:page_links]), (classname if @options[:page_links]), ('disabled' unless page)].join(' ')
      end

      def ul_class
         ["pagination", container_attributes[:class]].compact.join(" ")
      end
    end

    class Bootstrap4LinkRenderer < LinkRenderer
      protected
      def html_container(html)
        tag :nav, tag(:ul, html, class: ul_class)
      end

      def page_number(page)
        item_class = if(page == current_page)
          'active page-item'
        else
          'page-item'
        end

        tag :li, link(page, page, rel: rel_value(page), class: 'page-link'), class: item_class
      end

      def gap
        tag :li, link('&hellip;'.html_safe, '#', class: 'page-link'), class: 'page-item disabled'
      end

      def previous_or_next_page(page, text, classname)
        tag :li, link(text, page || '#', class: 'page-link'), class: [(classname[0..3] if  @options[:page_links]), (classname if @options[:page_links]), ('disabled' unless page), 'page-item'].join(' ')
      end

      def ul_class
         ["pagination", container_attributes[:class]].compact.join(" ")
      end
    end
  end
end
