#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/basic_page'

class TemplatedPage < BasicPage
    def initialize name
        super
    end

    def get_content_template
        result = self.class.instance_variable_get :@content_template_cache
        unless result
            filename = self.class.content_template_filename
            File.open(filename, "r") do | file |
                result = ERB.new(file.read)
            end
            self.class.instance_variable_set :@content_template_cache, result
        end
        result
    end

    def generate_content
        get_content_template.result(methods_from_instance_methods(self, {
            :title => :page_title,
            :top_uri => :top_uri,
            :h => :escape_html
        }.merge(self.class.get_template_variables_hash)))
    end

    abstract_self_method :content_template_filename, :get_template_variables_hash
end

