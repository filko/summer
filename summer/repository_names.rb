#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

module Summer
    module RepositoryNames
        def repository_names
            @repositories.keys.sort_by do | repo_name |
                [ @repositories[repo_name]['status'] && @repositories[repo_name]['status'].value == "core" ? 0 : 1,
                    repo_name ]
            end
        end
    end
end
