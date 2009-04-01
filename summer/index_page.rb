#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'
require 'summer/columnify'
require 'summer/repository_summary.rb'
require 'summer/repository_common.rb'

class IndexPage < TemplatedPage
    include Summer::RepositorySummary
    include Summer::RepositoryCommon

    def initialize
        super ""
        @repositories = {}
        @categories = {}
    end

    def page_title
        return "Statically Updated Metadata Manifestation for Exherbo Repositories"
    end

    def self.content_template_filename
        return "summer/index_page.rhtml"
    end

    def self.get_template_variables_hash
        {
            :category_href       => :make_category_href,
            :category_names      => :category_names,
            :columnify           => :columnify,
        }.merge(Summer::RepositoryCommon.get_template_variables_hash)
    end

    def top_uri
        return ""
    end

    def add_repository repo
        @repositories[repo.name] = repo
    end

    def category_names
        @categories.keys.sort
    end

    def add_category_name cat_name
        @categories[cat_name] = nil
    end

    def columnify data, cols
        return Summer::columnify data, cols
    end
end

