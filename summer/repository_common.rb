#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

module Summer
    module RepositoryCommon
        def repository_names
            @repositories.keys.sort_by do | repo_name |
                [ @repositories[repo_name]['status'] && @repositories[repo_name]['status'].value == "core" ? 0 : 1,
                    repo_name ]
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

        def make_repository_href repo_name
            return top_uri + "repositories/" + repo_name + "/index.html"
        end

        def make_category_href cat_name
            return top_uri + "packages/" + cat_name + "/index.html"
        end

        def self.get_template_variables_hash
            {
                :repository_href     => :make_repository_href,
                :repository_names    => :repository_names,
                :repository_class    => :make_repository_class,
                :repository_summary  => :make_repository_summary
            }
        end
    end
end
