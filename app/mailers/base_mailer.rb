# app/mailers/base_mailer.rb
class BaseMailer < ActionMailer::Base

  default(
    from: "hello@giv2giv.org",
    reply_to: "hello@giv2giv.org"
  )

  protected

  def send_mail(email, subject, body)
  	require "mandrill"
    mail(to: email, subject: subject, body: body, content_type: "text/html")
  end

  def mandrill_template(template_name, attributes)
  	require "mandrill"

    mandrill = Mandrill::API.new App.mailer["password"]

    merge_vars = attributes.map do |key, value|
      { name: key, content: value }
    end

    mandrill.templates.render(template_name, [], merge_vars)["html"]
  end
end

