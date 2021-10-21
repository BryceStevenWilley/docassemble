---
layout: docs
title: Recipes
short_title: Recipes
---

This section contains miscellaneous recipes for solving problems in
**docassemble**.

# <a name="require checkbox"></a>Require a checkbox to be checked

## Using `validation code`

{% highlight yaml %}
question: |
  You must agree to the terms of service.
fields:
  - I agree to the terms of service: agrees_to_tos
    datatype: yesnowide
validation code: |
  if not agrees_to_tos:
    validation_error("You cannot continue until you agree to the terms of service.")
---
mandatory: True
need: agrees_to_tos
question: All done.
{% endhighlight %}

## Using `datatype: checkboxes`

{% highlight yaml %}
question: |
  You must agree to the terms of service.
fields:
  - no label: agrees_to_tos
    datatype: checkboxes
    minlength: 1
    choices:
      - I agree to the terms of service
    validation messages:
      minlength: |
        You cannot continue unless you check this checkbox.
---
mandatory: True
need: agrees_to_tos
question: All done
{% endhighlight %}

# <a name="completion"></a>Use a variable to track when an interview has been completed

One way to track whether an interview is completed is to set a
variable when the interview is done.  That way, you can inspect the
interview answers and test for the presence of this variable.

{% highlight yaml %}
objects:
  - user: Individual
---
question: |
  What is your name?
fields:
  - First name: user.name.first
  - Last name: user.name.last
---
mandatory: True
code: |
  user.name.first
  user_finish_time
  final_screen
---
code: |
  user_finish_time = current_datetime()
---
event: final_screen
question: |
  Goodbye, user!
buttons:
  Exit: exit
{% endhighlight %}

You could also use Redis to store the status of an interview.

{% highlight yaml %}
objects:
  - user: Individual
  - r: DARedis
---
question: |
  What is your name?
fields:
  - First name: user.name.first
  - Last name: user.name.last
---
mandatory: True
code: |
  interview_marked_as_started
  user.name.first
  interview_marked_as_finished
  final_screen
---
code: |
  redis_key = user_info().filename + ':' + user_info().session
---
code: |
  r.set(redis_key, 'started')
  interview_marked_as_started = True
---
code: |
  r.set(redis_key, 'finished')
  interview_marked_as_finished = True
---
event: final_screen
question: |
  Goodbye, user!
buttons:
  Exit: exit
{% endhighlight %}

# <a name="exit hyperlink"></a>Exit interview with a hyperlink rather than a redirect

Suppose you have a final screen in your interview that looks like this:

{% highlight yaml %}
mandatory: True
code: |
  kick_out
---
event: kick_out
question: Bye
buttons:
  - Exit: exit
    url: https://example.com
{% endhighlight %}

When the user clicks the "Exit" button, an Ajax request is sent to the
**docassemble** server, the interview logic is run again, and then
when the browser processes the response, the browser is redirected
by JavaScript to the url (https://example.com).

If you would rather that the button act as a hyperlink, where clicking
the button sends the user directly to the URL, you can make the button
this way:

{% highlight yaml %}
mandatory: True
code: |
  kick_out
---
event: kick_out
question: Bye
subquestion: |
  ${ action_button_html("https://example.com", size='md', color='primary', label='Exit', new_window=False) }
{% endhighlight %}

# <a name="two fields match"></a>Ensure two fields match

{% highlight yaml %}
question: |
  What is your e-mail address?
fields:
  - E-mail: email_address_first
    datatype: email
  - note: |
      Please enter your e-mail address again.
    datatype: email
  - E-mail: email_address
    datatype: email
  - note: |
      Make sure the e-mail addresses match.
    js hide if: |
      val('email_address') != '' && val('email_address_first') == val('email_address')
  - note: |
      <span class="text-success">E-mail addresses match!</span>
    js show if: |
      val('email_address') != '' && val('email_address_first') == val('email_address')
validation code: |
  if email_address_first != email_address:
    validation_error("You cannot continue until you confirm your e-mail address")
---
mandatory: True
question: |
  Your e-mail address is ${ email_address }.
{% endhighlight %}

# <a name="progressive disclosure"></a>Progressive disclosure

{% include demo-side-by-side.html demo="progressive-disclosure" %}

Add `progressivedisclosure.css` to the "static" data folder of your package.

{% highlight css %}
a span.pdcaretopen {
    display: inline;
}

a span.pdcaretclosed {
    display: none;
}

a.collapsed .pdcaretopen {
    display: none;
}

a.collapsed .pdcaretclosed {
    display: inline;
}
{% endhighlight %}

Add `progressivedisclosure.py` as a Python module file in your
package.

{% highlight python %}
import re

__all__ = ['prog_disclose']

def prog_disclose(template, classname=None):
    if classname is None:
        classname = ' bg-light'
    else:
        classname = ' ' + classname.strip()
    the_id = re.sub(r'[^A-Za-z0-9]', '', template.instanceName)
    return u"""\
<a class="collapsed" data-toggle="collapse" href="#{}" role="button" aria-expanded="false" aria-controls="collapseExample"><span class="pdcaretopen"><i class="fas fa-caret-down"></i></span><span class="pdcaretclosed"><i class="fas fa-caret-right"></i></span> {}</a>
<div class="collapse" id="{}"><div class="card card-body{} pb-1">{}</div></div>\
""".format(the_id, template.subject_as_html(trim=True), the_id, classname, template.content_as_html())
{% endhighlight %}

This uses the [collapse feature] of [Bootstrap].

# <a name="new or existing"></a>New object or existing object

The [`object` datatype] combined with the [`disable others`] can be
used to present a single question that asks the user either to select
an object from a list or to enter information about a new object.

Another way to do this is to use `show if` to show or hide fields.

This recipe gives an example of how to do this in an interview that
asks about individuals.

{% include demo-side-by-side.html demo="new-or-existing" %}

This recipe keeps a master list of individuals in an object called
`people`.  Since this list changes throughout the interview, it is
re-calculated whenever a question is asked that uses `people`.

When individuals are treated as unitary objects, you can do things
like use Python's `in` operator to test whether an individual is a
part of a list.  This recipe illustrates this by testing whether
`boss` is part of `customers` or `employee` is part of `customers`.

# <a name="resume via email"></a>E-mailing the user a link for resuming the interview later

If you want users to be able to resume their interviews later, but you
don't want to use the username and password system, you can e-mail
your users a URL created with [`interview_url()`].

{% include demo-side-by-side.html demo="save-continue-later" %}

# <a name="hybrid"></a>E-mailing or texting the user a link for purposes of using the touchscreen

Using a desktop computer is generally very good for answering
questions, but it is difficult to write a signature using a mouse.

Here is an example of an interview that allows the user to use a
desktop computer for answering questions, but use a mobile device with
a touchscreen for writing the signature.

{% include demo-side-by-side.html demo="food-with-sig" %}

This interview includes a [YAML] file called
[`signature-diversion.yml`], the contents of which are:

{% highlight yaml %}
mandatory: True
code: |
  multi_user = True
---
question: |
  Sign your name
subquestion: |
  % if not device().is_touch_capable:
  Please sign your name below with your mouse.
  % endif
signature: user.signature
under: |
  ${ user }
---
sets: user.signature
code: |
  signature_intro
  if not device().is_touch_capable and user.has_mobile_device:
    if user.can_text:
      sig_diversion_sms_message_sent
      sig_diversion_post_sms_screen
    elif user.can_email:
      sig_diversion_email_message_sent
      sig_diversion_post_email_screen
---
question: |
  Do you have a mobile device?
yesno: user.has_mobile_device
---
question: |
  Can you receive text messages on your mobile device?
yesno: user.can_text
---
question: |
  Can you receive e-mail messages on your mobile device?
yesno: user.can_email
---
code: |
  send_sms(user, body="Click on this link to sign your name: " + interview_url_action('mobile_sig'))
  sig_diversion_sms_message_sent = True
---
code: |
  send_email(user, template=sig_diversion_email_template)
  sig_diversion_email_message_sent = True
---
template: sig_diversion_email_template
subject: Sign your name with your mobile device
content: |
  Make sure you are using your
  mobile device.  Then
  [click here](${ interview_url_action('mobile_sig') })
  to sign your name with
  the touchscreen.
---
question: |
  What is your e-mail address?
fields:
  - E-mail: user.email
---
question: |
  What is your mobile number?
fields:
  - Number: user.phone_number
---
event: sig_diversion_post_sms_screen
question: |
  Check your text messages.
subquestion: |
  We just sent you a text message containing a link.  Click the link
  and sign your name.

  Once we have your signature, you will move on automatically.
reload: 5
---
event: sig_diversion_post_email_screen
question: |
  Check your e-mail on your mobile device.
subquestion: |
  We just sent you an email containing a link.  With your mobile
  device, click the link and sign your name.

  Once we have your signature, you will move on automatically.
reload: 5
---
event: mobile_sig
need: user.signature
question: |
  Thanks!
subquestion: |
  We got your signature:

  ${ user.signature }

  You can now resume the interview on your computer.
{% endhighlight %}

The above interview requires setting `multi_user = True`.  To avoid
this you can use the following pair of interviews.

First interview:

{% highlight yaml %}
objects:
  - r: DARedis
---
mandatory: True
code: |
  email_sent
  reconsider('signature_obtained')
  if signature_obtained:
    final_screen
  elif r.get_data(redis_key) is None:
    timeout_screen
  else:
    waiting_screen
---
code: |
  send_email(to=email_address, template=email_template)
  email_sent = True
---
question: |
  What is your e-mail address?
fields:
  - E-mail address: email_address
    datatype: email
---
template: email_template
subject: |
  Your signature needed
content: |
  [Click here](${ interview_url(i=user_info().package + ':second-interview.yml', c=redis_key, new_session=1) })
  to sign your name with a touchscreen device.
---
code: |
  need(r)
  import random
  import string
  redis_key = ''.join(random.choice(string.ascii_lowercase) for i in range(15))
  r.set_data(redis_key, 'waiting', expire=60*60*24)
---
event: final_screen
question: Your signature
subquestion: |
  ${ signature }
---
event: timeout_screen
question: |
  Sorry, you didn't sign in time.
buttons:
  - Restart: restart
---
prevent going back: True
event: waiting_screen
question: |
  Waiting for signature
subquestion: |
  Open your e-mail on a touchscreen device.

  You should get an e-mail soon asking you
  to provide a signature.  Click the link
  in the e-mail.
reload: 5
---
code: |
  if r.get_data(redis_key) not in ('waiting', None):
    signature = DAFile('signature')
    signature.initialize(filename="signature.png")
    signature.write(r.get_data(redis_key), binary=True)
    signature.commit()
    r.delete(redis_key)
    signature_obtained = True
  else:
    signature_obtained = False
{% endhighlight %}

Second interview (referenced in the first as `second-interview.yml`):

{% highlight yaml %}
objects:
  - r: DARedis
---
mandatory: True
code: |
  signature_saved
  final_screen
---
code: |
  if 'c' not in url_args or r.get_data(url_args['c']) != 'waiting':
    message('Unauthorized', show_restart=False, show_exit=False)
  r.set_data(url_args['c'], signature.slurp(auto_decode=False), expire=600)
  signature_saved = True
---
question: Sign your name
signature: signature
---
prevent going back: True
event: final_screen
question: |
  Thanks!
subquestion: |
  You can now resume your interview.
{% endhighlight %}

# <a name="document signing"></a>Multi-user interview for getting a client's signature

This is an example of a multi-user interview where one person (e.g.,
an attorney) writes a document that they want a second person (e.g, a
client) to sign.  It is a multi-user interview (with [`multi_user`] set
to `True`).  The attorney inputs the attorney's e-mail address and
uploads a DOCX file containing:

> {% raw %}{{ signature }}{% endraw %}

where the client's signature should go.  The attorney then receives a
hyperlink that the attorney can send to the client.

When the client clicks on the link, the client can read the unsigned
document, then agree to sign it, then sign it, then download the
signed document.  After the client signs the document, it is e-mailed
to the attorney's e-mail address.

{% include demo-side-by-side.html demo="sign" %}

[Here](https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/examples/signdoc.yml)
is a more complex version that handles multiple documents in Word
or PDF format and integrates with the Legal Server case management
system.  It requires login and expects the [Configuration] to contain
the Legal Server domain name in the directive `legal server domain`.

# <a name="upload validation"></a>Validating uploaded files

Here is an interview that makes the user upload a different file if
the file the user uploads is too large.

{% include demo-side-by-side.html demo="upload-file-size" %}

# <a name="mail merge"></a>Mail merge

Here is an example interview that assembles a document for every row
in a Google Sheet.

{% include demo-side-by-side.html demo="google-sheet-3" %}

# <a name="generic document"></a>Documents based on objects

This example is similar to the [mail merge example] in that it uses a
single template to create multiple documents.  In this case, however,
the same template is used to generate a document for two different
objects.

{% include demo-side-by-side.html demo="generic-document" %}

This makes use of the [`generic object` modifier].  The template file
[generic-document.docx] refers to the person using the variable `x`.

# <a name="docxproperties"></a>Altering metadata of generated DOCX files

This example demonstrates using the [docx] package to modify the
[core document properties] of a generated DOCX file.

{% include demo-side-by-side.html demo="docxproperties" %}

Note that this interview uses [Python] code in a [`code`] block that
should ideally go into a module file.  The `docx` variable is an
object from a third party module and is not able to be [pickled].  The
code works this way in this interview because the [`code`] block
ensures that the variable `user_name` is defined before the `docx`
variable is created, and it deletes the `docx` variable with `del
docx` before the [`code`] block finishes.  If the variable `user_name`
was undefined, **docassemble** would try to save the variable `docx`
in the interview answers before asking about `user_name`, and this
would result in a pickling error.  If the `docx` variable only existed
inside of a function in a module, there would be no problem with
[pickling].

# <a name="idle"></a>Log out a user who has been idle for too long

Create a static file called `idle.js` with the following contents.

{% highlight javascript %}
var idleTime = 0;
var idleInterval;
$(document).on('daPageLoad', function(){
    idleInterval = setInterval(idleTimerIncrement, 60000);
    $(document).mousemove(function (e) {
        idleTime = 0;
    });
    $(document).keypress(function (e) {
        idleTime = 0;
    });
});

function idleTimerIncrement() {
    idleTime = idleTime + 1;
    if (idleTime > 60){
        url_action_perform('log_user_out');
        clearInterval(idleInterval);
    }
}
{% endhighlight %}

In your interview, include `idle.js` in a [`features`] block.

{% highlight yaml %}
features:
  javascript: idle.js
---
mandatory: True
code: |
  welcome_screen_seen
  final_screen
---
question: |
  Welcome to the interview.
field: welcome_screen_seen
---
event: final_screen
question: |
  You are done with the interview.
---
event: log_user_out
code: |
  command('logout')
{% endhighlight %}

This logs the user out after 60 minutes of inactivity in the browser.
To use a different number of minutes, edit the line
`if (idleTime > 60){`.

# <a name="background tail"></a>Seeing the progress of a running background task

Since [background tasks] run in a separate [Celery] process, there is
no simple way to get information from them while they are running.

However, [Redis] lists provide a helpful mechanism for keeping track
of log messages.

Here is an example that uses a [`DARedis`] object to store log
messages about a long-running [background task].  It uses [`check in`]
to poll the server for new log messages.

{% include demo-side-by-side.html demo="background-tail" %}

Since the task in this case (adding one number to another) is not
actually long-running, the interview uses `time.sleep()` to make it
artificially long-running.

# <a name="python to javascript"></a>Sending information from Python to JavaScript

If you use [JavaScript] in your interviews, and you want your
[JavaScript] to have knowledge about the interview answers, you can
use [`get_interview_variables()`], but it is slow because it uses
[Ajax].  If you only want a few pieces of information to be available
to your [JavaScript] code, there are a few methods you can use.

One method is to use the [`script` modifier].

{% include demo-side-by-side.html demo="pytojs-script" %}

Note that the variable is only guaranteed to be defined on the screen
showing the [`question`] that includes the [`script` modifier].  While
the value will persist from screen to screen, this is only because
screen loads use [Ajax] and the [JavaScript] variables are not cleared
out when a new screen loads.  But a browser refresh will clear the
[JavaScript] variables.

Another method is to use the `"javascript"` form of the [`log()`] function.

{% include demo-side-by-side.html demo="pytojs-log" %}

In this example, the [`log()`] function is called from a [`code`]
block that has [`initial`] set to `True`.  Thus, you can rely on the
`myColor` variable being defined on every screen of the interview
after `favorite_color` gets defined.

Another method is to pass the values of [Python] variables to the
browser using the [DOM], and then use [JavaScript] to retrieve the values.

{% include demo-side-by-side.html demo="pytojs-dom" %}

All of these methods are read-only.  If you want to be able to change
variables using [JavaScript], and also have the values saved to the
interview answers, you can insert `<input type="hidden">` elements
onto a page that has a "Continue" button.

{% include demo-side-by-side.html demo="pytojs-hidden" %}

This example uses the [`encode_name()`] function to convert the
variable name to the appropriate field name.  For more information on
manipulating the **docassemble** front end, see the section on [custom
front ends].  The example above works for easily for text fields, but
other data types will require more work.  Also, the example above only
works if the [Configuration] contains `restrict input variables: false`.

# <a name="ajax"></a>Running actions with Ajax

Here is an example of using [JavaScript] to run an action using [Ajax].

{% include demo-side-by-side.html demo="ajax" %}

The features used in this example include:

* [`action_button_html()`] to insert the HTML of a button.
* [Running Javascript at page load time] using the `daPageLoad` event.
* Setting an [`id`] and using the [CSS custom class] that results.
* [`flash()`] to flash a message at the top of the screen.
* [`action_call()`] to call an action using [Ajax].
* [`val()`] to obtain the value of a field on the screen using [JavaScript].
* [`set_save_status()`] to prevent the interview answers from being
  saved after an action completes.
* [`action_argument()`] to obtain the argument that was passed to [`action_call()`].
* [`json_response()`] to return [JSON] back to the web browser.

# <a name="collate"></a>Collating assembled and uploaded documents

Here is an interview that uses [`pdf_concatenate()`] to bring
assembled documents and user-provided documents in a single PDF file.

{% include demo-side-by-side.html demo="collate" %}

The Exhibit labeling sheets are generated by the template
[`exhibit_insert.docx`].

# <a name="stripe"></a>Payment processing with [Stripe]

First, sign up for a [Stripe] account.

From the dashboard, obtain your test API keys.  There are two keys: a
"publishable key" and a "secret key."  Put these into your
[Configuration] as follows:

{% highlight yaml %}
stripe public key: pk_test_ZjkQYPUU0pjQibxamUq28PlM00381Pd25e
stripe secret key: sk_test_YW41CYyivW0Vo7EN0mFD5i4P01ZLeQAPS8
{% endhighlight %}

The `stripe public key` is the "publishable key."  The `stripe secret
key` is the "secret key."

Confirm that you have the `stripe` package installed by checking the
list of packages under "Package Management".  If `stripe` is not
listed, follow the directions for [installing a package].  `stripe` is
available on [PyPI].

Create a Python module called `dastripe.py` with the following contents:

{% highlight python %}
import stripe
import json
from docassemble.base.util import word, get_config, action_argument, DAObject, prevent_going_back
from docassemble.base.standardformatter import BUTTON_STYLE, BUTTON_CLASS

stripe.api_key = get_config('stripe secret key')

__all__ = ['DAStripe']

class DAStripe(DAObject):
  def init(self, *pargs, **kwargs):
    if get_config('stripe public key') is None or get_config('stripe secret key') is None:
      raise Exception("In order to use a DAStripe object, you need to set stripe public key and stripe secret key in your Configuration.")
    super().init(*pargs, **kwargs)
    if not hasattr(self, 'button_label'):
      self.button_label = "Pay"
    if not hasattr(self, 'button_color'):
      self.button_color = "primary"
    if not hasattr(self, 'error_message'):
      self.error_message = "Please try another payment method."
    self.is_setup = False

  def setup(self):
    float(self.amount)
    str(self.currency)
    self.intent = stripe.PaymentIntent.create(
      amount=int(float('%.2f' % self.amount)*100.0),
      currency=self.currency,
    )
    self.is_setup = True

  @property
  def html(self):
    if not self.is_setup:
      self.setup()
    return """\
<div id="stripe-card-element" class="mt-2"></div>
<div id="stripe-card-errors" class="mt-2 mb-2 text-alert" role="alert"></div>
<button class="btn """ + BUTTON_STYLE + self.button_color + " " + BUTTON_CLASS + '"' + """ id="stripe-submit">""" + word(self.button_label) + """</button>"""

  @property
  def javascript(self):
    if not self.is_setup:
      self.setup()
    billing_details = dict()
    try:
      billing_details['name'] = str(self.payor)
    except:
      pass
    address = dict()
    try:
      address['postal_code'] = self.payor.billing_address.zip
    except:
      pass
    try:
      address['line1'] = self.payor.billing_address.address
      address['line2'] = self.payor.billing_address.formatted_unit()
      address['city'] = self.payor.billing_address.city
      if hasattr(self.payor.billing_address, 'country'):
        address['country'] = address.billing_country
      else:
        address['country'] = 'US'
    except:
      pass
    if len(address):
      billing_details['address'] = address
    try:
      billing_details['email'] = self.payor.email
    except:
      pass
    try:
      billing_details['phone'] = self.payor.phone_number
    except:
      pass
    return """\
<script>
  var stripe = Stripe(""" + json.dumps(get_config('stripe public key')) + """);
  var elements = stripe.elements();
  var style = {
    base: {
      color: "#32325d",
    }
  };
  var card = elements.create("card", { style: style });
  card.mount("#stripe-card-element");
  card.addEventListener('change', ({error}) => {
    const displayError = document.getElementById('stripe-card-errors');
    if (error) {
      displayError.textContent = error.message;
    } else {
      displayError.textContent = '';
    }
  });
  var submitButton = document.getElementById('stripe-submit');
  submitButton.addEventListener('click', function(ev) {
    stripe.confirmCardPayment(""" + json.dumps(self.intent.client_secret) + """, {
      payment_method: {
        card: card,
        billing_details: """ + json.dumps(billing_details) + """
      }
    }).then(function(result) {
      if (result.error) {
        flash(result.error.message + "  " + """ + json.dumps(word(self.error_message)) + """, "danger");
      } else {
        if (result.paymentIntent.status === 'succeeded') {
          action_perform(""" + json.dumps(self.instanceName + '.success') + """, {result: result})
        }
      }
    });
  });
</script>
    """
  @property
  def paid(self):
    if not self.is_setup:
      self.setup()
    if hasattr(self, "payment_successful") and self.payment_successful:
      return True
    if not hasattr(self, 'result'):
      self.demand
    payment_status = stripe.PaymentIntent.retrieve(self.intent.id)
    if payment_status.amount_received == self.intent.amount:
      self.payment_successful = True
      return True
    return False
  def process(self):
    self.result = action_argument('result')
    self.paid
    prevent_going_back()
{% endhighlight %}

Create an interview [YAML] file (called, e.g., `teststripe.yml`) with
the following contents:

{% highlight yaml %}
modules:
  - .dastripe
---
features:
  javascript: https://js.stripe.com/v3/
---
objects:
  - payment: DAStripe.using(payor=client, currency='usd')
  - client: Individual
  - client.billing_address: Address
---
mandatory: True
code: |
  # Payor information may be required for some payment methods.
  client.name.first
  # client.billing_address.address
  # client.phone_number
  # client.email
  if not payment.paid:
    payment_screen
  favorite_fruit
  final_screen
---
question: |
  What is your name?
fields:
  - First: client.name.first
  - Last: client.name.last
---
question: |
  What is your phone number?
fields:
  - Phone: client.phone_number
---
question: |
  What is your e-mail address?
fields:
  - Phone: client.email
---
question: |
  What is your billing address?
fields:
  - Address: client.billing_address.address
    address autocomplete: True
  - Unit: client.billing_address.unit
    required: False
  - City: client.billing_address.city
  - State: client.billing_address.state
    code: states_list()
  - Zip: client.billing_address.zip
---
question: |
  How much do you want to pay?
fields:
  - Amount: payment.amount
    datatype: currency
---
event: payment.demand
question: |
  Payment
subquestion: |
  You need to pay up.  Enter your credit card information here.

  ${ payment.html }
script: |
  ${ payment.javascript }
---
event: payment.success
code: |
  payment.process()
---
question: |
  What is your favorite fruit?
fields:
  - Fruit: favorite_fruit
---
event: final_screen
question: Your favorite fruit
subquestion: |
  It is my considered opinion
  that your favorite fruit is
  ${ favorite_fruit }.
{% endhighlight %}

Test the interview with a [testing card number] and adapt it to your
particular use case.

The attributes of the `DAStripe` object (known as `payment` in this
example) that can be set are:

* `payment.currency`: this is the currency that the payment will use.
  Set this to `'usd'` for U.S. dollars.  See [supported accounts and
  settlement currencies] for information about which currencies are
  available.
* `payment.payor`: this contains information about the person who is
  paying.  You can set this to an [`Individual`] or [`Person`] with a
  `.billing_address` (an [`Address`]), a name, a `.phone_number`, and an
  `.email`.  This information will not be sought through dependency
  satisfaction; it will only be used if it exists.  Thus, if you want
  to send this information (which may be required for the payment to
  go through), make sure your interview logic gathers it.
* `payment.amount`: the amount of the payment to be made, in whatever
  currency you are using for the payment.
* `payment.button_label`: the label for the "Pay" button.  The default
  is "Pay."
* `payment.button_color`: the Bootstrap color for the "Pay" button.
  The default is `primary`.
* `payment.error_message`: the error message that the user will see at
  the top of the screen if the credit card is not accepted.  The
  default is "Please try another payment method."

The attribute `.paid` returns `True` if the payment has been made or
`False` if it has not.  It also triggers the payment process.  If
`payment.amount` is not known, it will be sought.

The user is asked for their credit card information on a "special
screen" tagged with `event: request.demand`.  The variable
`request.demand` is sought behind the scenes when the interview logic
evaluates `request.paid`.

The `request.demand` page needs to include `${ payment.html }` in the
`subquestion` and `${ payment.javascript }` in the `script`.  The
JavaScript produced by `${ payment.javascript }` assumes that the file
`https://js.stripe.com/v3/` has been loaded in the browser already;
this can be accomplished through a `features` block containing a
`javascript` reference.

The "Pay" button is labeled "Pay" by default, but this can be
customized with the `request.button_label` attribute.  This value is
passed through `word()`, so you can use the `words` translation system
to translate it.

If the payment is not successful, the user will see the error message
reported by [Stripe], followed by the value of
`request.error_message`, which is `'Please try another payment
method.'` by default.  The value of `request.error_message` is passed
through `word()`, so you can use the `words` translation system to
translate it.

If the payment is successful, the JavaScript on the page performs the
`request.success` "action" in the interview.  Your interview needs to
provide a `code` block that handles this action.  The action needs to
call `payment.process()`.  This will save the data returned by
[Stripe] and will also call the [Stripe] API to verify that payment
was actually made.  The `code` block for the "action" will run to the
end, so the next thing it will do is evaluate the normal interview
logic.  When `request.paid` is encountered, it will evaluate to `True`.

The [Stripe] API is only called once to verify that the payment was
actually made.  Subsequent evaluations of `request.paid` will return
`True` immediately without calling the API again.

Thus, the interview logic for the process of requiring a payment is
just two lines of code:

{% highlight python %}
if not payment.paid:
  payment_screen
{% endhighlight %}

Payment processing is a very complicated subject, so this recipe
should only be considered a starting point.  The advantage of this
design is that it keeps a lot of the complexity of payment processing
out of the interview [YAML] and hides it in the module.

If you want to have the billing address on the same screen where the
credit card number is entered, you could use custom HTML forms, or a
`fields` block in which the `Continue` button is hidden.

When you are satisfied that your payment process work correctly, you
can set your `stripe public key` and `stripe secret key` to your
"live" [Stripe] API keys on your production server.

# <a name="formio"></a>Integration with form.io, AWS Lambda, and the **docassemble** API

This recipe shows how you can set up [form.io] to send a webhook
request to an [AWS Lambda] function, which in turn calls the
**docassemble** [API] to start an interview session, inject data into
the interview answers of the session, and then send a notification to
someone to let them know that a session has been started.

On your server, create the following interview, calling it `fromformio.yml`.

{% highlight yaml %}
mandatory: True
code: |
  multi_user = True
---
code: |
  start_data = None
---
mandatory: |
  start_data is not None
code: |
  send_email(to='jpyle@docassemble.org', template=start_of_session)
---
template: start_of_session
subject: Session started
content: |
  A session has started.  [Go to it now](${ interview_url() }).
---
mandatory: True
question: |
  The start_data is:

  `${ repr(start_data) }`
{% endhighlight %}

Create an [AWS Lambda] function and trigger it with an HTTP REST API
that is authenticated with an API key.

![AWS Lambda]({{ site.baseurl }}/img/examples/formio03.png){: .maybe-full-width }

![AWS Lambda API key]({{ site.baseurl }}/img/examples/formio04.png){: .maybe-full-width }

Add a layer that provides the `requests` module.  Then write a
function like the following.

![lambda function code]({{ site.baseurl }}/img/examples/formio06.png){: .maybe-full-width }

{% highlight python %}
import json
import os
import requests

def lambda_handler(event, context):
    try:
        start_data = json.loads(event['body'])
    except:
        return { 'statusCode': 400, 'body': json.dumps('Could not read JSON from the HTTP body') }
    key = os.environ['daapikey']
    root = os.environ['baseurl']
    i = os.environ['interview']
    r = requests.get(root + '/api/session/new', params={'key': key, 'i': i})
    if r.status_code != 200:
        return { 'statusCode': 400, 'body': json.dumps('Error creating new session at ' + root + '/api/session/new')}
    session = r.json()['session']
    r = requests.post(root + '/api/session', data={'key': key,
                                                   'i': i,
                                                   'session': session,
                                                   'variables': json.dumps({'start_data': start_data, 'event_data': event}),
                                                   'question': '1'})
    if r.status_code != 200:
        return { 'statusCode': 400, 'body': json.dumps('Error writing data to new session')}
    return { 'statusCode': 204, 'body': ''}
{% endhighlight %}

Set the environment variables so that your provide the function with
an API key for the **docassemble** [API] (which you can set up in your
Profile), the URL of your server, and the name of the interview you
want to run (in this case, `fromformio.yml` is a Playground
interview).

![AWS Lambda]({{ site.baseurl }}/img/examples/formio07.png){: .maybe-full-width }

Go to [form.io] and create a form that looks like this:

![form.io form]({{ site.baseurl }}/img/examples/formio01.png){: .maybe-full-width }

Attach a "webhook" action that sends a POST request to your [AWS
Lambda] endpoint.  Add the API key for the HTTP REST API trigger as
the `x-api-key` header.

![form.io action]({{ site.baseurl }}/img/examples/formio02.png){: .maybe-full-width }

Under Forms, click the "Use" button next to the form that you created
and try submitting the form.  The e-mail recipient designated in your
YAML code should receive an e-mail containing the text:

> A session has started. Go to it now.

where "Go to it now" is a hyperlink to an interview session.  When the
e-mail recipient clicks the link, they will resume an interview
session in which the variable `start_data` contains the information
from the [form.io] form.

![interview session]({{ site.baseurl }}/img/examples/formio08.png){: .maybe-full-width }

# <a name="object_conversion"></a>Converting the result of object questions

When you gather objects using [`datatype: object_checkboxes`] or one
of the other object-based data types, you might not want the variable
you are setting to use object references.  You can use the
[`validation code`] feature to apply a transformation to the variable
you are defining.

{% include demo-side-by-side.html demo="object-checkboxes-copy" %}

The result is that the `fruit_preferences` objects are copies of the
original `fruit_data` object and have separate `instanceName`s.

# <a name="repeatable"></a>Repeatable session with defaults

If you want to restart an interview session and use the answers from
the just-finished session as default values for the new session, you
can accomplish this using the [`depends on`] feature.

{% include demo-side-by-side.html demo="repeatable" %}

When the variable `counter` is incremented by the `new_version`
[action], all of the variables set by [`question`] blocks that use
`depends on: counter` will be undefined, but the old values will be
remembered and offered as defaults when the [`question`] blocks are
encountered again.

# <a name="universal"></a>Universal document assembler

Here is an example of using the [catchall questions] feature to
provide an interview that can ask questions to define arbitrary
variables that are referenced in a document.

{% include demo-side-by-side.html demo="universal-document" %}

# <a name="adust_language_for_second_or_third_person"></a>Adjust Language for Second or Third Person

You may want to have a single interview that can be used either by a
person for themselves, or by a person who is assisting another person.
In the following example, there is an object named `client` that is of
the type [`Individual`].  The variable `user_is_client` indicates
whether the user is the client, or the user is assisting a third
party.

Here is the text of the question and subquestion written in second
person:

```
question: |
  Should your attorney be compensated for out-of-pocket expenses
  out of your property?
subquestion: |
  Your attorney may incur expenses in administering your property.
  If you allow your attorney to be compensated for out-of-pocket
  expenses out of your property, that may make the attorney's life
  easier.

  Do you want your attorney to be compensated for out-of-pocket
  expenses out of your property?
yesno: should_be_compensated
```

Here is how you might convert that text so that it will work properly
if the user is the client, or if the client is someone else:

```
initial: True
code: |
  if user_is_client:
    set_info(user=client)
---
question: |
  Should ${ client.possessive('attorney') } be compensated for
  out-of-pocket expenses out of ${ client.possessive('property') }?
subquestion: |
  ${ client.possessive('attorney', capitalize=True) }
  may incur expenses in administering
  ${ client.pronoun_possessive('property') }.
  If
  ${ client.subject() }
  ${ client.does_verb("allow") }
  ${ client.pronoun_possessive('attorney') }
  to be compensated for out-of-pocket expenses out of
  ${ client.pronoun_possessive('property') },
  that may make the attorney's life easier.

  ${ client.do_question('want', capitalize=True) }
  ${ client.pronoun_possessive('attorney') }
  to be compensated for out-of-pocket expenses out of
  ${ client.pronoun_possessive('property') }?
yesno: should_be_compensated
```

This one block can now do two different things, and is still
relatively readable.

## Possessives

The first mention of the client in the sentence should use the client's
name. If the first mention of the client in the sentence is possessive,
you should use `${ client.possessive('object') }` to generate either
"Client Name's object" or "your object".

## Capitalization

Any of the language functions can be modified with `capitalize=True` if
they are being used at the start of a sentence.

# <a name="read before signing"></a>Allow user to read a document before signing it

This interview uses [`depends on`] to force the reassembly of a
document after the user has viewed a draft version with a "sign here"
sticker in place of the signature.

{% include demo-side-by-side.html demo="signature-preview" %}

# <a name="multisignature"></a>Gathering multiple signatures on a document

This interview sends a document out for signature to an arbitrary
number of signers, and then e-mails the document to the signers
when all signatures have been provided.

{% include demo-side-by-side.html demo="demo-multi-sign" %}

This interview uses [`include`] to bring in the contents of
[`docassemble.demo:data/questions/sign.yml`].  This [YAML] file
disabled server-side encryption by setting [`multi_user`] to `True`,
and loads the `SigningProcess` class from the
[`docassemble.demo.sign`] module.  The object `sign`, and instance of
`SigningProcess`, controls the gathering and display of signatures.
Note the way signatures and the dates of signatures are included in
the DOCX template file, [declaration_of_favorite_fruit.docx]:

![Declaration of Favorite Fruit]({{ site.baseurl }}/img/examples/declaration-favorite-fruit.png){: .maybe-full-width }

The template uses methods on the `sign` object to include the
signature images and dates.  To include a signature of an [`Individual`]
or [`Person`] called `the_person`, you would call
`sign.signature_of(the_person)`.  To include the date when the person
signed, you would call `sign.signature_date_of(the_person)`.

Note also the way that a line is placed underneath the signature
image: on the line following the reference to
`sign.signature_of(user)`, there is an empty table with a top
border and no other borders.

The interview gathers the user's name, the user's e-mail address, and
the names and e-mail addresses of one or more witnesses.

When the interview logic calls `sign.out_for_signature()`, this
triggers the following process:

1. In a background process, e-mails are sent to the user and the
   witnesses with a hyperlink they can click on to sign the document.
2. The hyperlink was created by `interview_url_action()` using the
   [action] name `sign.request_signature` and an [action] argument
   called `code` that contains a special code that identifies who the
   signer is.
3. When the signer clicks the hyperlink, they join the interview
   session and the [action] is run, and the [action] calls
   `force_ask()` to set up a series of screens that signer should see.
   First the signer agrees to sign, then the signer signs, and then
   the signer sees a "thank you" screen on which the signer can
   download the document containing their signature.
4. When all of the signatures have been collected, e-mails are sent to
   the signers attaching the final signed document.

The `sign.signature_of(the_person)` method is smart; it will return the empty
string `''` if `the_person` has not signed yet, and it will return the
person's signature if `the_person` has signed.  Similarly,
`sign.signature_date_of(the_person)` returns a line of underscores if
the person has not signed yet, and otherwise returns a `DADateTime`
object containing the date when the person signed.  Specifically, when
the person has not signed yet, the methods return a [`DAEmpty`]
object.  This means you can safely write
`sign.signature_of(the_person).show(width='1in')` or
`sign.signature_date_of(the_person).format('yyyy-MM-dd')` and the
method will still return the empty string or a line of underscores.

In this example, only one document, `statement`, is assembled.  When
you initialize a `SigningProcess` object, you could specify more than
one document.  For example, instead of `documents='statement'`, you
could write `documents=['statement', 'certificate_of_service']`.  Then
the system would send out two documents for signature.

{% include demo-side-by-side.html demo="demo-multi-sign-2" %}

Note that `documents` refers not to the actual variables `statement`
and `certificate_of_service`, but to the variables as text:
`'statement'` and `'certificate_of_service'`.  This is important; if
you were to write `documents=statement` or `documents=[statement,
certificate_of_service]`, you would get an error.  It is necessary to
refer to the documents using text references because the document
itself contains references to `sign`, and if `sign` could not be
defined until `statement` was defined, that would be a Catch-22.

The `SigningProcess` object knows who the signers are because of the
calls to `sign.signature_of()` and `sign.signature_date_of()` that
were made while the document was being assembled.  Therefore, you
don't have to explicitly state who needs to sign the document; you can
use logic in your document to determine who the signers are.

Note that in the `attachment code` part of the final `question`, it
refers to `sign.list_of_documents(refresh=True)` instead of
`statement`.  This is important because the underlying document is
constantly changing as the signatures are added.  Calling
`sign.list_of_documents(refresh=True)` will re-assemble the document
and then return `[statement]` (the `statement` document inside a
Python list).  The `list_of_documents()` method simply returns a list of
[`DAFileCollection`] objects.

The signing process is customizable.  The [`sign.yml`] file, which is
included at the top of the interview [YAML] file above, contains
default [`template`] and [`question`] blocks that you can override in
your own [YAML].  For example, the default content for the initial
e-mail to a signer is:

{% highlight yaml %}
generic object: SigningProcess
template: x.initial_notification_email[i]
subject: |
  Your signature needed on
  ${ x.singular_or_plural('a document', 'documents') }:
  ${ x.documents_name() }
content: |
  ${ x.signer(i) },

  Your signature is requested on
  % if x.number_of_documents() == 1:
  a document called
  ${ x.documents_name() }.
  % else:
  the following
  ${ x.singular_or_plural('document', 'documents') }:

  % for document in x.list_of_documents():
  * ${ document.info['name'] }
  % endfor
  % endif

  To sign, [click here].

  If you are willing to sign this document, please do so
  in the next ${ nice_number(x.deadline_days) } days.
  If you do not sign by
  ${ today().plus(days=x.deadline_days) }, the above link
  will expire.

  [click here]: ${ x.url(i) }
{% endhighlight %}

You can overwrite this by including the following rule in your own
[YAML], which will take precedence over the above rule.

{% highlight yaml %}
template: sign.initial_notification_email[i]
subject: |
  Please sign the Declaration of Favorite Fruit for ${ user }.
content: |
  ${ sign.signer(i) },

  I would greatly appreciate it if you would sign the
  Declaration of Favorite Fruit for ${ user } by
  [clicking here](${ sign.url(i) }).

  If you are not willing to sign, please
  call me at 555-555-2929.
{% endhighlight %}

For more information about what templates are used, see the
[`sign.yml`] file.  Some of the blocks in this file define `action`s;
do not try to modify these unless you are sure you know what you are
doing.

The methods of the `SigningProcess` object that you might use are as
follows.

`sign.out_for_signature()` initiates the signing process.  It is safe
to run this more than once.  If the signing process has already been
started, the method will not do anything.

`sign.signer(i)` is usually invoked in a `template` in a context where
`i` is a code that uniquely identifies the signer.  It returns the
signer as an object.

`sign.url(i)` is also used inside of `template` blocks.  It returns
the link that a signer should click on in order to join the interview
and sign the document or documents.

`sign.list_of_documents()` returns the assembled documents as a list
of [`DAFileCollection`] objects.  If the optional keyword parameter
`refresh` is set to `True`, then the documents will be re-assembled
before they are returned.

`sign.number_of_documents()` returns the number of documents as an
integer.

`sign.singular_or_plural()` is useful when writing `template`s.  The
first argument is what should be returned if there is one document.
The second argument is what should be returned if there are multiple
documents.

`sign.documents_name()` will return a `comma_and_list()` of the names
of the documents.

`sign.has_signed(the_signer)` will return `True` if `the_signer` has
signed the document yet, and otherwise will return `False`.

`sign.all_signatures_in()` will return `True` if all of the signers
have signed, and otherwise will return `False`.

`sign.list_of_signers()` will return a `DAList()` of the signers.
`sign.number_of_signers()` will return the number of signers as an
integer.  `sign.signers_who_signed()` will return the subset who have
signed, and `sign.signers_who_did_not_sign()` will return the subset
who have not yet signed.

The methods `sign.signature_of(the_signer)` and
`sign.signature_date_of(the_signer)` are discussed above.  These are
typically used inside of documents.

There is also the method `sign.signature_datetime_of(the_signer)`,
which returns a `DADateTime` object representing the exact time the
signer's signature was recorded.  There is also the method
`sign.signature_ip_address_of(the_signer)`, which returns the IP
address the signer was using.  The IP address, along with the date and
time, are widely used ingredients of digital signatures.

`sign.sign_for(the_signer, the_signer.signature)` will insert a
signature manually, where `the_signer` is a person whose signature is
referenced in the document, using the `signature_of()` method, and
`the_signer.signature` is a variable defined by a [`signature`] block
(a `DAFile` object).  Note that if this method is called more than
once, each new time the date of the signature will be updated.  You
may want to avoid this by doing:

{% highlight python %}
if not sign.has_signed(the_signer):
  sign.sign_for(the_signer, the_signer.signature)
{% endhighlight %}

Then this code can safely be called more than once without changing
the date of the signature.

Calling `sign.refresh_documents()` will generate fresh copies of the
documents.  (It uses the [`reconsider()`] function.)

Note that in the [`sign.yml`] file, the [`signature`] block uses
`validation code` that calls `x.validate_signature(i)`.  This is
important because it performs the additional tasks necessary to record
the signature, such as recording the IP address.  You will probably
not need to call `validate_signature()` outside of this context; the
`sign_for()` method calls `validate_signature()` for you.

# <a name="phonenumber"></a>Validating international phone numbers

Here is a simple way to validate international phone numbers.

{% include demo-side-by-side.html demo="phone-number" %}

Here is a way to validate international phone numbers using a single screen.

{% include demo-side-by-side.html demo="phone-number-2" %}

# <a name="customdate"></a>Customizing the date input

If you don't like the way that web browsers implement date inputs, you
can customize the way dates are displayed.

{% include demo-side-by-side.html demo="customdate" %}

This interview uses a [JavaScript] file [`datereplace.js`].  The
[JavaScript] converts a regular date input element into a hidden
element and then adds name-less elements to the [DOM].  This approach
preserves default values.

# <a name="side processes"></a>Running side processes outside of the interview logic

Normally, the order of questions in a **docassemble** interview is
determined by the interview logic: questions are asked to obtain the
definitions of undefined variables, and the interview ends when all
the necessary variables have been defined.

Sometimes, however, you might want to send the user through a logical
process that is not driven by the need to definitions of undefined
variables.  For example, you might want to:

* Ask a series of questions again to make sure the user has a second
  chance to get the answers right;
* Ask the user specific follow-up questions after the user makes an
  edit to an answer.
* Give the user the option of going through a process one or more
  times.

The following interview is an example of the latter.  At the end of
the interview logic, the user has the option of pressing a button in
order to go through a repeatable multi-step process that contains
conditional logic.

{% include demo-side-by-side.html demo="courtfile" %}

This takes advantage of an important feature of [`force_ask()`].  If
you give [`force_ask()`] a variable and there is no question in the
interview [YAML] that can be asked in order to define that variable,
then [`force_ask()`] will ignore that variable.  The call to
[`force_ask()`] lists all of the questions that might be asked in the
process, and the [`if`] modifiers are used to indicate under what
conditions the questions should be asked.

# <a name="passing"></a>Passing variables from one interview session to another

Using [`create_session()`], [`set_session_variables()`], and
[`interview_url()`], you can start a user in one session, collect
information, and then initiate a new session, write variables into the
interview answers of that session, and direct the user to that session.

{% include demo-side-by-side.html demo="stage-one" %}

The interview that the user is directed to is the following.

{% include demo-side-by-side.html demo="stage-two" %}

Note that when the user starts the session in the second interview,
the interview already knows the object `user` and already knows the
value of `favorite_fruit`.

# <a name="basic"></a>Making generic questions customizable

If you have a lot of questions in your interviews that are very
similar, such as questions that ask for names and addresses, you might
want to create a YAML file that contains [`generic object`]
questions and then include that YAML file in all of your interviews.
This is a way to ensure consistency across your interviews without
having to maintain the same information in multiple places across your
YAML files.

Having a common set of [`generic object`] questions does not inhibit
your ability to customize [`question`] blocks when you need to; you
can always override the [`generic object`] question with a more
specific question if you would like to ask a question a different way
if you have a special case.

It is also possible to customize your [`generic object`] questions
without overriding.  This recipe demonstrates a method of designing
[`generic object`] questions that allows for the customization of
specific details of questions.

Here is an example of an interview that gathers names, e-mail
addresses, and addresses of three [`Individual`]s while relying
entirely on [`generic object`] questions to gather the information.

{% include demo-side-by-side.html demo="demo-with-basic-questions" %}

The interview starts by including [`demo-basic-questions.yml`].  This
is a parent YAML file for including other YAML files.  Its full
contents are:

{% highlight yaml %}
include:
  - demo-basic-questions-name.yml
  - demo-basic-questions-address.yml
{% endhighlight %}

The contents of [`demo-basic-questions-name.yml`] are as follows.

{% highlight yaml %}
generic object: Individual
question: |
  ${ x.ask_name_template.subject }
subquestion: |
  ${ x.ask_name_template.content }
fields:
  - First name: x.name.first
    required: x.first_name_required
    show if:
      code: x.name.uses_parts
    default: ${ x.name.default_first }
  - Middle name: x.name.middle
    required: x.middle_name_required
    show if:
      code: x.name.uses_parts and x.ask_middle_name
    default: ${ x.name.default_middle }
  - Last name: x.name.last
    required: x.last_name_required
    show if:
      code: x.name.uses_parts
    default: ${ x.name.default_last }
  - Name: x.name.text
    show if:
      code: not x.name.uses_parts
  - E-mail: x.email
    datatype: email
    required: x.email_required
    show if:
      code: x.ask_email_with_name
---
generic object: Individual
question: |
  ${ x.ask_email_template.subject }
subquestion: |
  ${ x.ask_email_template.content }
fields:
  - E-mail: x.email
    datatype: email
---
generic object: Individual
template: x.ask_name_template
subject: |
  % if get_info('user') is x:
  What is your name?
  % else:
  What is the name of ${ x.description }?
  % endif
content: ""
---
generic object: Individual
if: x.ask_email_with_name
template: x.ask_name_template
subject: |
  % if x is get_info('user'):
  What is your name and e-mail address?
  % else:
  What is the name and e-mail address of ${ x.description }?
  % endif
content: ""
---
generic object: Individual
template: x.ask_email_template
subject: |
  % if x is get_info('user'):
  What is your e-mail address?
  % else:
  What is the e-mail address of ${ x.description }?
  % endif
content: ""
---
generic object: Individual
code: |
  x.description = x.object_name()
---
generic object: Individual
code: |
  if user_logged_in() and user_info().first_name:
    x.name.default_first = user_info().first_name
  else:
    x.name.default_first = ''
---
generic object: Individual
code: |
  if user_logged_in() and user_info().last_name:
    x.name.default_last = user_info().last_name
  else:
    x.name.default_last = ''
---
generic object: Individual
code: |
  x.name.default_middle = ''
---
generic object: Individual
code: |
  x.first_name_required = True
---
generic object: Individual
code: |
  x.last_name_required = True
---
generic object: Individual
code: |
  x.email_required = True
---
generic object: Individual
code: |
  x.ask_middle_name = False
---
generic object: Individual
code: |
  x.middle_name_required = False
---
generic object: Individual
code: |
  x.ask_email_with_name = False
{% endhighlight %}

The contents of [`demo-basic-questions-address.yml`] are as follows.

{% highlight yaml %}
generic object: Individual
question: |
  ${ x.ask_address_template.subject }
subquestion: |
  ${ x.ask_address_template.content }
fields:
  - "Street address": x.address.address
    address autocomplete: True
  - 'Unit': x.address.unit
    required: x.address_unit_required
  - 'City': x.address.city
  - 'State': x.address.state
    code: states_list()
  - 'Zip code': x.address.zip
    required: x.address_zip_code_required
---
if: x.ask_about_homelessness
generic object: Individual
question: |
  ${ x.ask_address_template.subject }
subquestion: |
  ${ x.ask_address_template.content }
fields:
  - label: |
      % if get_info('user') is x:
      I am
      % else:
      ${ x } is
      % endif
      experiencing homelessness.
    field: x.address.homeless
    datatype: yesno
  - "Street address": x.address.address
    address autocomplete: True
    hide if: x.address.homeless
  - 'Unit': x.address.unit
    required: x.address_unit_required
    hide if: x.address.homeless
  - 'City': x.address.city
  - 'State': x.address.state
    code: states_list()
  - 'Zip code': x.address.zip
    required: x.address_zip_code_required
    hide if: x.address.homeless
---
generic object: Individual
template: x.ask_address_template
subject: |
  % if get_info('user') is x:
  Where do you live?
  % else:
  What is the address of ${ x }?
  % endif
content: ""
---
generic object: Individual
code: |
  x.address_zip_code_required = True
---
generic object: Individual
code: |
  x.address_unit_required = False
---
generic object: Individual
code: |
  x.ask_about_homelessness = False
{% endhighlight %}

Note that all of the blocks in these YAML files are [`generic object`]
blocks.  There are  [`question`] blocks that define questions to be
used.  These [`question`] blocks make reference to a lot of different
object attributes that function as "settings."  After the [`question`]
blocks, there are [`template`] blocks and [`code`] blocks that
set default values for these settings.

This means that in your own interviews, you have the option of
overriding any of those settings simply by including a block that
sets a value for one of the settings.  For example, the default value
of the `.ask_about_homelessness` attriute is `False`, but in the
example interview, this was overridden for the object `client`:

{% highlight yaml %}
code: |
  client.ask_about_homelessness = True
{% endhighlight %}

Note the strategies that are being used in the
[`demo-basic-questions-name.yml`] file and the
[`demo-basic-questions-address.yml`] file to provide a variety of
options for the ways that questions are asked:

* Using [`template`]s to specify the `question` and `subquestion`
  text, using the `subject` part and the `content` part of the
  template.  Alternatively, you could use separate templates for the
  `question` and `subquestion`, so that your interviews could override
  the `question` part without overriding the `subquestion` part, and
  vice-versa.
* Specifying multiple [`question`] blocks and using the [`if`]
  modifier to choose which one is applicable, depending on the values
  of "settings."
* Using the `code` variant of [`show if`] to select or deselect fields
  in a list of fields, depending on the values of settings.

When making use of these strategies, make sure you understand [how
**docassemble** finds questions for variables].

# <a name="preview"></a>Showing a partial preview of document assembly

This example uses the `[TARGET]`
[feature]({{ site.baseurl }}/docs/background.html#target)
to show a document assembly preview in the `right` portion of the
screen that continually updates as the user enters information into
fields.

{% include demo-side-by-side.html demo="preview" %}

# <a name="exceldb"></a>Using a spreadsheet as a database for looking up information

If you have a table of information and you want to be able to look
things up in that table of information during your interview, one of
the ways you can accomplish this is by keeping the information in a
spreadsheet in the Source folder of your package.  Python can be used
to read the spreadsheet and look up information in it.

The [`fruit_database` module] uses the [`pandas`] module to read an
XLSX spreadsheet file into memory.  The `get_fruit_names()` function
returns a list of fruits (from the "Name" column) and the
`fruit_info()` function returns a dictionary of information about a
given fruit.`

{% include demo-side-by-side.html demo="fruits-database" %}

Note that the interview does not simply import the
`fruit_info_by_name` dictionary into the interview answers.  Although
technically you can import dictionaries, lists, and other Python data
types into your interview, doing so is generally not a good idea
because those values will then become part of the interview answers
that are stored in the database for every step of the interview.  This
wastes hard drive space and it also wastes time re-loading the data
out of your module every time the screen loads.  It is a best practice
to use helper functions like `get_fruit_names()` and `fruit_info()` to
bring in information on an as-needed basis.

If your database is particularly large, reading it into memory may not
be a good idea.  You might want to rewrite the functions so that they
read information out of the file on an as-needed basis.  You also
might want to adapt the functions to read data from a Google Sheet or
Airtable rather than from an Excel spreadsheet that is part of your package.

[how **docassemble** finds questions for variables]: {{ site.baseurl }}/docs/logic.html#variablesearching
[`show if`]: {{ site.baseurl }}/docs/fields.html#show if
[`demo-basic-questions.yml`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/demo-basic-questions.yml
[`demo-basic-questions-name.yml`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/demo-basic-questions-name.yml
[`demo-basic-questions-address.yml`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/demo-basic-questions-address.yml
[catchall questions]: {{ site.baseurl }}/docs/fields.html#catchall
[action]: {{ site.baseurl }}/docs/functions.html#actions
[`depends on`]: {{ site.baseurl }}/docs/logic.html#depends on
[`datatype: object_checkboxes`]: {{ site.baseurl }}/docs/fields.html#object_checkboxes
[`validation code`]: {{ site.baseurl }}/docs/fields.html#validation code
[AWS Lambda]: https://aws.amazon.com/lambda/
[API]: {{ site.baseurl }}/docs/api.html
[form.io]: https://form.io
[installing a package]: {{ site.baseurl }}/docs/packages.html#installing
[PyPI]: https://pypi.python.org/pypi
[Stripe]: https://stripe.com/
[testing card number]: https://stripe.com/docs/testing#cards
[supported accounts and settlement currencies]: https://stripe.com/docs/payouts#supported-accounts-and-settlement-currencies
[Configuration]: {{ site.baseurl }}/docs/config.html
[`exhibit_insert.docx`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/templates/exhibit_insert.docx
[`datereplace.js`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/static/datereplace.js
[`pdf_concatenate()`]: {{ site.baseurl }}/docs/functions.html#pdf_concatenate
[JSON]: https://en.wikipedia.org/wiki/JSON
[`action_button_html()`]: {{ site.baseurl }}/docs/functions.html#action_button_html
[`flash()`]: {{ site.baseurl }}/docs/functions.html#flash
[`action_call()`]: {{ site.baseurl }}/docs/functions.html#js_action_call
[`val()`]: {{ site.baseurl }}/docs/functions.html#js_val
[`set_save_status()`]: {{ site.baseurl }}/docs/functions.html#set_save_status
[`action_argument()`]: {{ site.baseurl }}/docs/functions.html#action_argument
[`json_response()`]: {{ site.baseurl }}/docs/functions.html#json_response
[`id`]: {{ site.baseurl }}/docs/modifiers.html#id
[`if`]: {{ site.baseurl }}/docs/modifiers.html#if
[CSS custom class]: {{ site.baseurl}}/docs/initial.html#css customization
[Running Javascript at page load time]: {{ site.baseurl }}/docs/functions.html#js_daPageLoad
[custom front ends]: {{ site.baseurl }}/docs/frontend.html
[DOM]: https://en.wikipedia.org/wiki/Document_Object_Model
[`encode_name()`]: {{ site.baseurl }}/docs/functions.html#encode_name
[`log()`]: {{ site.baseurl }}/docs/functions.html#log
[`code`]: {{ site.baseurl }}/docs/code.html#code
[`initial`]: {{ site.baseurl }}/docs/logic.html#initial
[`question`]: {{ site.baseurl }}/docs/questions.html#question
[`script` modifier]: {{ site.baseurl }}/docs/modifiers.html#script
[Ajax]: https://en.wikipedia.org/wiki/Ajax_(programming)
[`get_interview_variables()`]: {{ site.baseurl }}/docs/functions.html#js_get_interview_variables
[JavaScript]: https://en.wikipedia.org/wiki/JavaScript
[`check in`]: {{ site.baseurl }}/docs/background.html#check in
[`DARedis`]: {{ site.baseurl }}/docs/objects.html#DARedis
[Redis]: https://redis.io/
[Celery]: http://www.celeryproject.org/
[background task]: {{ site.baseurl }}/docs/background.html#background
[background tasks]: {{ site.baseurl }}/docs/background.html#background
[core document properties]: https://python-docx.readthedocs.io/en/latest/dev/analysis/features/coreprops.html
[pickled]: https://docs.python.org/3/library/pickle.html
[pickling]: https://docs.python.org/3/library/pickle.html
[docx]: https://python-docx.readthedocs.io/
[`docx template file`]: {{ site.baseurl }}/docs/documents.html#docx template file
[YAML]: https://en.wikipedia.org/wiki/YAML
[`signature-diversion.yml`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/signature-diversion.yml
[collapse feature]: https://getbootstrap.com/docs/4.0/components/collapse/
[Bootstrap]: https://getbootstrap.com/
[`disable others`]: {{ site.baseurl }}/docs/fields.html#disable others
[`object` datatype]: {{ site.baseurl }}/docs/fields.html#object
[`interview_url()`]: {{ site.baseurl }}/docs/functions.html#interview_url
[`code`]: {{ site.baseurl }}/docs/code.html
[`features`]: {{ site.baseurl }}/docs/initial.html#javascript
[Python]: https://en.wikipedia.org/wiki/Python_%28programming_language%29
[mail merge example]: #mail merge
[generic-document.docx]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/templates/generic-document.docx
[`generic object` modifier]: {{ site.baseurl }}/docs/modifiers.html#generic object
[`generic object`]: {{ site.baseurl }}/docs/modifiers.html#generic object
[`force_ask()`]: {{ site.baseurl }}/docs/force_ask.html#force_ask
[`include`]: {{ site.baseurl }}/docs/initial.html#include
[`docassemble.demo:data/questions/sign.yml`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/sign.yml
[declaration_of_favorite_fruit.docx]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/templates/declaration_of_favorite_fruit.docx
[`multi_user`]: {{ site.baseurl }}/docs/special.html#multi_user
[`docassemble.demo.sign`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/sign.py
[`DAEmpty`]: {{ site.baseurl }}/docs/objects.html#DAEmpty
[`sign.yml`]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/data/questions/sign.yml
[`DAFileCollection`]: {{ site.baseurl }}/docs/objects.html#DAFileCollection
[`signature`]: {{ site.baseurl }}/docs/fields.html#signature
[`reconsider()`]: {{ site.baseurl }}/docs/functions.html#reconsider
[`template`]: {{ site.baseurl }}/docs/initial.html#template
[`create_session()`]: {{ site.baseurl }}/docs/functions.html#create_session
[`set_session_variables()`]: {{ site.baseurl }}/docs/functions.html#set_session_variables
[`Individual`]: {{ site.baseurl }}/docs/objects.html#Individual
[`Person`]: {{ site.baseurl }}/docs/objects.html#Person
[`Address`]: {{ site.baseurl }}/docs/objects.html#Address
[`fruit_database` module]: https://github.com/jhpyle/docassemble/blob/master/docassemble_demo/docassemble/demo/fruit_database.py
[`pandas`]: https://pandas.pydata.org/
