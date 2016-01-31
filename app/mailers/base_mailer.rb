# app/mailers/base_mailer.rb
class BaseMailer < ActionMailer::Base

  default(
    from: "hello@giv2giv.org",
    reply_to: "hello@giv2giv.org"
  )

  protected

  def send_mail2(email, subject, body)
  	require "mandrill"
    mail(to: email, subject: subject, body: body, content_type: "text/html")
  end

  def send_mandrill(recipient, subject, attributes, which_template)

    begin

      merge_vars = attributes.map do |key, value|
        { name: key, content: value }
      end

      require "mandrill"

      mandrill_handler = Mandrill::API.new App.mailer["password"]

      template_name = which_template
      template_content = []
      message = {
       "global_merge_vars"=>merge_vars,
       "from_email"=>App.giv["email_contact"],
       "to"=>
          [{"type"=>"to",
              "name"=>recipient.name,
              "email"=>recipient.email}],
       "html"=>"<p>Example HTML content</p>",
       "from_name"=>"giv2giv.org",
       "merge"=>true,
       "inline_css"=>true,
       "text"=>"Example text content",
       "auto_text"=>nil,
       "track_opens"=>nil,
       "headers"=>{"Reply-To"=>App.giv["email_contact"]},
       "subject"=> subject
      }
      async = true

      result = mandrill_handler.messages.send_template template_name, template_content, message, async
          # [{"_id"=>"abc123abc123abc123abc123abc123",
          #     "status"=>"sent",
          #     "reject_reason"=>"hard-bounce",
          #     "email"=>"recipient.email@example.com"}]
    rescue Mandrill::Error => e
        # Mandrill errors are thrown as exceptions
        puts "A mandrill error occurred: #{e.class} - #{e.message}"
        # A mandrill error occurred: Mandrill::UnknownSubaccountError - No subaccount exists with the id 'customer-123'    
        raise
    end
end


  def mandrill_template(template_name, attributes)
  	require "mandrill"

    mandrill_handler = Mandrill::API.new App.mailer["password"]

    merge_vars = attributes.map do |key, value|
      { name: key, content: value }
    end

    mandrill_handler.templates.render template_name, [], merge_vars
  end
end

