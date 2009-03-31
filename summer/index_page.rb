#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'
require 'summer/columnify'

class IndexPage < TemplatedPage
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
            :repository_href     => :make_repository_href,
            :repository_names    => :repository_names,
            :repository_class    => :make_repository_class,
            :repository_summary  => :make_repository_summary
        }
    end

    def top_uri
        return ""
    end

    def repository_names
        @repositories.keys.sort
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

    def make_repository_href repo_name
        return top_uri + "repositories/" + repo_name + "/index.html"
    end

    def make_category_href cat_name
        return top_uri + "packages/" + cat_name + "/index.html"
    end

    def make_repository_summary repo_name
        repo = @repositories[repo_name]
        summary_key = repo['summary']
        if summary_key
            status_key = repo['status']
            if status_key
                summary_key.value + " (" + status_key.value + ")"
            else
                summary_key.value
            end
        else
            "The #{repo_name} repository"
        end
    end

    def make_repository_class repo_name
        repo = @repositories[repo_name]
        status_key = repo['status']
        if status_key
            "repo-status-" + status_key.value
        else
            ""
        end
    end
end
