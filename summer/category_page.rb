#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'
require 'summer/columnify'

class CategoryPage < TemplatedPage
    def initialize cat_name
        super "packages/" + cat_name
        @cat_name = cat_name
        @packages = {}
    end

    def page_title
        return @cat_name
    end

    def self.content_template_filename
        return "summer/category_page.rhtml"
    end

    def self.get_template_variables_hash
        {
            :columnify           => :columnify,
            :package_href        => :make_package_href,
            :package_names       => :package_names,
            :package_summary     => :make_package_summary
        }
    end

    def top_uri
        return "../../"
    end

    def package_names
        @packages.keys.sort
    end

    def add_id id
        (@packages[id.name] ||= []) << id
    end

    def columnify data, cols
        return Summer::columnify data, cols
    end

    def make_package_href name
        return top_uri + "packages/" + name + "/index.html"
    end

    def make_package_summary name
        best_id = best_id_for name
        if best_id.short_description_key
            best_id.short_description_key.value.sub(/\.$/, '')
        else
            name.to_s
        end
    end

    def best_id_for name
        @packages[name].max_by do | id |
            [ id.version.is_scm? ? 0 : 1 , id.version ]
        end
    end
end

