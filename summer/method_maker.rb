#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

class Class
    # Used to implement method_maker.
    def method_maker_1 arg
        self.class.send :define_method, arg do | *l_args |
            l_args.each do | l_arg |
                send "#{arg}_1".to_sym, l_arg
            end
        end
    end

    # method_maker :foo will create a class method named foo which, when called,
    # will call self.foo_1 for each of its arguments in turn.
    #
    # So if you want to implement something that behaves like attr, you'd
    # implement self.attr_1 and then call method_maker :attr.
    method_maker_1 :method_maker
end

