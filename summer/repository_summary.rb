#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

module Summer
    module RepositorySummary
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
    end
end
