#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'
require 'summer/repository_summary.rb'
require 'summer/repository_common.rb'
require 'summer/package_common.rb'

class CategoryPage < TemplatedPage
    include Summer::RepositorySummary
    include Summer::RepositoryCommon
    include Summer::PackageCommon

    def initialize cat_name
        super "packages/" + cat_name
        @cat_name = cat_name
        @packages = {}
        @repositories = {}
    end

    def page_title
        return @cat_name
    end

    def self.content_template_filename
        return "summer/category_page.rhtml"
    end

    def self.get_template_variables_hash
        {
            :package_href        => :make_package_href,
            :package_names       => :package_names,
            :package_summary     => :make_package_summary,
        }.merge(Summer::RepositoryCommon.get_template_variables_hash)
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

    def add_repository repo
        @repositories[repo.name] = repo
    end
end

