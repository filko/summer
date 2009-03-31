#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

module Summer
    def self.columnify data, cols
        result = [[]]
        data.each do | d |
            result << [] if result.last.length == cols
            result.last << d
        end
        result.last << nil while result.last.length < cols
        result
    end
end

