# frozen_string_literal: true

require "action_dispatch/routing/polymorphic_routes"
# ActionViewはRailsの中でViewの役割を中心に取り持つ。MVCの中でVCをつなぐのがイメージに近いのかな。
module ActionView
  module RoutingUrlFor
    # Returns the URL for the set of +options+ provided. This takes the
    # same options as +url_for+ in Action Controller (see the
    # documentation for <tt>ActionController::Base#url_for</tt>). Note that by default
    # <tt>:only_path</tt> is <tt>true</tt> so you'll get the relative "/controller/action"
    # instead of the fully qualified URL like "http://example.com/controller/action".
    #
    # ==== Options
    # * <tt>:anchor</tt> - Specifies the anchor name to be appended to the path.
    # * <tt>:only_path</tt> - If true, returns the relative URL (omitting the protocol, host name, and port) (<tt>true</tt> by default unless <tt>:host</tt> is specified).
    # * <tt>:trailing_slash</tt> - If true, adds a trailing slash, as in "/archive/2005/". Note that this
    #   is currently not recommended since it breaks caching.
    # * <tt>:host</tt> - Overrides the default (current) host if provided.
    # * <tt>:protocol</tt> - Overrides the default (current) protocol if provided.
    # * <tt>:user</tt> - Inline HTTP authentication (only plucked out if <tt>:password</tt> is also present).
    # * <tt>:password</tt> - Inline HTTP authentication (only plucked out if <tt>:user</tt> is also present).
    #
    # ==== Relying on named routes
    #
    # Passing a record (like an Active Record) instead of a hash as the options parameter will
    # trigger the named route for that record. The lookup will happen on the name of the class. So passing a
    # Workshop object will attempt to use the +workshop_path+ route. If you have a nested route, such as
    # +admin_workshop_path+ you'll have to call that explicitly (it's impossible for +url_for+ to guess that route).
    #
    # ==== Implicit Controller Namespacing
    #
    # Controllers passed in using the +:controller+ option will retain their namespace unless it is an absolute one.
    #
    # ==== Examples
    #   <%= url_for(action: 'index') %>
    #   # => /blogs/
    #
    #   <%= url_for(action: 'find', controller: 'books') %>
    #   # => /books/find
    #
    #   <%= url_for(action: 'login', controller: 'members', only_path: false, protocol: 'https') %>
    #   # => https://www.example.com/members/login/
    #
    # => このanchorって便利だなぁ。
    #   <%= url_for(action: 'play', anchor: 'player') %>
    #   # => /messages/play/#player
    #
    #   <%= url_for(action: 'jump', anchor: 'tax&ship') %>
    #   # => /testing/jump/#tax&ship
    #
    #   <%= url_for(Workshop.new) %>
    #   # relies on Workshop answering a persisted? call (and in this case returning false)
    #   # => /workshops
    #
    #   <%= url_for(@workshop) %>
    #   # calls @workshop.to_param which by default returns the id
    #   # => /workshops/5
    #
    #   # to_param can be re-defined in a model to provide different URL names:
    #   # => /workshops/1-workshop-name
    #
    #   <%= url_for("http://www.example.com") %>
    #   # => http://www.example.com
    #
    #   <%= url_for(:back) %>
    #   # if request.env["HTTP_REFERER"] is set to "http://www.example.com"
    #   # => http://www.example.com
    #
    #   <%= url_for(:back) %>
    #   # if request.env["HTTP_REFERER"] is not set or is blank
    #   # => javascript:history.back()
    #
    #   <%= url_for(action: 'index', controller: 'users') %>
    #   # Assuming an "admin" namespace
    #   # => /admin/users
    #
    #   <%= url_for(action: 'index', controller: '/users') %>
    #   # Specify absolute path with beginning slash
    #   # => /users
    # url_forを定義している。
    # options = nilって基本的にはオプションは取らない想定でいるのか。
    # options = nil ってkey: :valueで与えられるときに使われる気がする。
    def url_for(options = nil)
      case options
      # Stringだったとき。これは、文字列をそのまま返すから、正直意味ないやつ
      when String
        options
      when nil
        super(only_path: _generate_paths_by_default)
      when Hash
        # symbolize_keys　でHASH化だよね。
        # てかRails内部で、撮ったhashをシンボル化しているので、この処理は無駄なので、最初からシンボルで書くようにしましょうね。
        options = options.symbolize_keys
        unless options.key?(:only_path)
          options[:only_path] = only_path?(options[:host])
        end
        # このsuperってなんだよぉおぉ。俺の理解だと、superに引数を取らないはず。superは、オーバーライド対象のメソッドの中身を呼ぶものだから
        super(options)
      when ActionController::Parameters
        # .key?は普通に使えるな。 puts hoge[:sage] if hoge.key?(:sage) みたいに。
        unless options.key?(:only_path)
          options[:only_path] = only_path?(options[:host])
        end

        super(options)
      when :back
        # _back_urlはなぜ、action_view/helperに定義されているのに、ここで読み込めているんだ？？
        # requireはどこでされている・・・
        _back_url
      when Array
        components = options.dup
        if _generate_paths_by_default
          polymorphic_path(components, components.extract_options!)
        else
          polymorphic_url(components, components.extract_options!)
        end
      else
        method = _generate_paths_by_default ? :path : :url
        builder = ActionDispatch::Routing::PolymorphicRoutes::HelperMethodBuilder.send(method)

        case options
        when Symbol
          builder.handle_string_call(self, options)
        when Class
          builder.handle_class_call(self, options)
        else
          builder.handle_model_call(self, options)
        end
      end
    end

    # return superってやばいな.....
    def url_options #:nodoc:
      return super unless controller.respond_to?(:url_options)
      controller.url_options
    end

    private
      def _routes_context
        controller
      end

      def optimize_routes_generation?
        controller.respond_to?(:optimize_routes_generation?, true) ?
          controller.optimize_routes_generation? : super
      end

      # これをメソッド化するのは可読性のためだと言い切れる。
      def _generate_paths_by_default
        true
      end

      def only_path?(host)
        _generate_paths_by_default unless host
      end
  end
end
