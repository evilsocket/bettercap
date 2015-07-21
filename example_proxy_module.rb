class HackTitle < Proxy::Module
    def initialize

    end

    def is_enabled?
        return true
    end

    def on_request request, response
        # is an html page?
        if response.content_type == "text/html"
            url = "http://#{request.host}#{request.url}"
            url = url.slice(0..50) + "..." unless url.length <= 50
            Logger.info "Hacking #{url} title tag"

            # make sure to use sub! or gsub! to update the instance
            response.body.sub!( "<title>", "<title> !!! HACKED !!! " )
        end
    end
end
