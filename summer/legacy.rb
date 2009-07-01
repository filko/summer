#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

# max_by with block is new since ruby 1.9
if not Array.respond_to? :max_by
    module Enumerable
        def max_by
            (map { | a | [ a, yield(a) ] }.max { | a, b | a[1] <=> b[1] })[0]
        end
    end
end

# since ruby 1.9
unless Object.respond_to? :tap
    class Object
        def tap
            yield self
            self
        end
    end
end

