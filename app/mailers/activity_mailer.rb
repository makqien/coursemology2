# The mailer for activities. This is meant to be called by the activities framework alone.
#
# @api private
class ActivityMailer < ApplicationMailer
  # Emails a recipient, informing him of an activity.
  #
  # @param [User] recipient The recipient of the email.
  # @param object The object to be made available to the view, accessible using +@object+.
  # @param [String] view_path The path to the view which should be rendered.
  def email(recipient, object, view_path)
    @recipient = recipient
    @object = object
    mail(to: recipient.email, template: view_path)
  end

  protected

  # Adds support for the +template+ option, which specifies an absolute path.
  #
  # @option options [String] :template (nil) The absolute template path to render.
  # @see #{ActionMailer::Base#mail}
  def mail(options)
    template = options.delete(:template)
    if template
      prepend_view_path(File.dirname(template))
      options[:template_path] = ''
      options[:template_name] = File.basename(template)
    end

    super
  end
end