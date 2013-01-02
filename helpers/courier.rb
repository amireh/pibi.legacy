module Sinatra
  module Courier

    module Helpers
      def dispatch_email_verification(u, &cb)
        dispatch_email(u.email, "emails/verification", "Please verify your email '#{u.email}'", &cb)
      end

      def dispatch_temp_password(u, &cb)
        dispatch_email(u.email, "emails/temp_password", "Temporary account password", &cb)
      end
    end

    def self.registered(app)
      app.helpers Courier::Helpers
      app.set :courier_service_enabled, true
    end
  end

  register Courier

  class Base
    def dispatch_email(addr, tmpl, title, &cb)
      if !@courier_service_enabled
        cb.call(false, 'Courier service is currently turned off.') if block_given?
        return
      end

      sent = true
      error_msg = 'Mail could not be delivered, please try again later.'
      begin
        Pony.mail :to => addr,
                  :from => "noreply@#{AppURL}",
                  :subject => "[#{AppName}] #{title}",
                  :html_body => erb(tmpl.to_sym, layout: "layouts/mail".to_sym)
      rescue Exception => e
        error_msg = "Mail could not be delivered: #{e.message}"
        sent = false
      end

      cb.call(sent, error_msg) if block_given?
    end
  end
end