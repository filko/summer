#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'

class CategoryPage < TemplatedPage
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
            :repository_href     => :make_repository_href,
            :repository_names    => :repository_names,
            :repository_class    => :make_repository_class,
            :repository_summary  => :make_repository_summary
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

    def add_repository repo
        @repositories[repo.name] = repo
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

    def repository_names
        @repositories.keys.sort_by do | repo_name |
            [ @repositories[repo_name]['status'] && @repositories[repo_name]['status'].value == "core" ? 0 : 1,
                repo_name ]
        end
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

