---
layout: docs
title: Migration from Python 2.7 to Python 3
short_title: Python 2.7 to 3
---

**docassemble** started out as an application based on Python 2.7.
However, Python 2.7 [is no longer maintained] as of January 1, 2020.
As the [pip] command reports:

{% highlight text %} 
DEPRECATION: Python 2.7 will reach the end of its life on January
1st, 2020.  Please upgrade your Python as Python 2.7 won't be
maintained after that date. A future version of pip will drop support
for Python 2.7.
{% endhighlight %}

Between [version 0.4.0] and [version 0.5.70], **docassemble** was
compatible with both Python 3.6 and Python 2.7.  Running Python 3.6
required setting the [Docker] environment variable `DAPYTHONVERSION`
to `3`.

Starting with [version 0.5.71], **docassemble** ended support for
Python 2.7 and upgraded to Python 3.6. Starting with [version 1.2.0],
**docassemble** only supports Python 3.8. In [version 1.4.0] of the
Docker container, **docassemble** started using Python 3.10, but the
Python application still supports Python 3.8.

If you are currently running a **docassemble** instance on [Docker]
using Python 2.7, you can upgrade by doing `docker stop`, `docker rm`,
`docker pull`, and then `docker run`.

There are a few things you should be aware of when upgrading:

* Interview answers created using Python 3.x will not be readable by
  Python 2.7.  This is because the way the [pickle] library works
  changed in a backwards-incompatible way between Python 2.7 and
  Python 3.
* Interview answers created using Python 2.7 **will** be readable by
  Python 3.x, so long as your interviews use standard **docassemble**
  features.  Date objects based on `datetime.datetime` will migrate.
  However, if you used objects from third-party libraries, you should
  test to see whether interview answers created in Python 2.7 are
  readable in Python 3.x.  There are no known issues yet, but there
  might be issues.
* This applies not just to interview answers, but also to any objects
  that are [pickled], such as machine learning data and objects stored in
  Redis or SQL.
* If you have written Python code in your interviews, or you have
  written Python modules, the code that you wrote that worked in
  Python 2.7 might not work in Python 3.x.  The way text is encoded
  and decoded changed, the `unicode()` function was removed, the
  `iteritems()` and `itervalues()` methods were removed, the `long`
  data type was removed, the `basestring` class was removed, the
  `xrange()` function was removed, the `map()`, `reduce()`, and
  `apply()` functions were removed, the `file` class was removed, and
  much more.
  
If you do not have any active users, you could simply do a `docker
stop`, `docker rm`, `docker pull`, and `docker run`, and then test out
your interviews and fix any errors that appear.

If you have active users, however, an immediate upgrade might result
in downtime if you find that your interview doesn't work in Python
3.x.  And if interview answers or other data created by your Python
2.7 interviews cannot be un[pickled] in Python 3.x, your users who
have active sessions at the time you upgrade the server may lose their
data.  The following procedure will avoid these problems:

1. Continue to operate your production server with Python 2.7.
2. Run two development servers: one that runs Python 2.7 (the default)
   and one that runs Python 3.x.
   Both should be running **docassemble** version 0.4.0 or above, and
   both should use some form of [data storage].
3. Using your two development servers, rewrite your interview code so
   that it is compatible both with Python 2.7 and Python 3.x.  See
   [writing Python 2-3 compatible code] for tips.  For example, if you
   used the `unicode()` function, replace it with the [`text_type()`]
   function.  Keep upgrading your code on your production server,
   using your normal process, after verifying that your changes to the
   code do not break functionality on 2.7.
4. If your code uses any special Python dependencies, read their
   documentation to see if they are compatible with Python 3.  If they
   are not, replace them with versions that are Python 3 compatible or
   remove them from your code.
5. Once you have tested your interviews to make sure they work in both
   Python 2.7 and Python 3.x, test whether data [pickled] by Python
   2.7 will be readable in Python 3.x.
   
   1. Log into your Python 2.7 development server and create a number of
      test sessions in your interviews.  Try to get the interview answers
      as "full" as possible, particularly if your interview answers
      contain objects from third party libraries.  If you have
      multiple interviews, create a session in each one.
   2. If you use machine learning, create some machine learning data.
   3. If you use Redis object storage or SQL object storage, store
      some objects.
   4. Take a screenshot of the My Interviews page.  You will check
      later that all of the sessions successfully migrate.
   4. Now, you need to move the SQL and Redis data from the Python 2.7
      development server ("server A") to a Python 3.x development
      server ("server B").  You can use your existing Python 3.x
      development server for this purpose, but if you care about the
      data that exists on it, make sure to back up its SQL and Redis
      data.
   5. To move the SQL and Redis data between server A and server B, do
      a `docker stop` on both server A and server B.
   6. Then, locate the locate the PostgreSQL and Redis backup files on
      both machines.  If you are using [S3] or [Azure Blob Storage], the
      PostgreSQL backup is a file called `docassemble` in the
      `postgres` folder, while the Redis backup is in the top-level
      file called `redis.rdb`.  If you are using [persistent volumes],
      use [`docker volume inspect`] to find the path on the host
      system where the backup volume is stored, and look in that
      directory.  The PostgreSQL backup is a file called `docassemble` in the
      `postgres` subdirectory, while the Redis backup is in the backup
      directory in a file called `redis.rdb`.
   7. Copy the `docassemble` and `redis.rdb` files from Server A to
      Server B, replacing the existing files (which you might want to
      back up).
   8. Start server B, your Python 3.x server, with `docker start`.
   9. When the server starts, log in and visit the My Interviews
      page.
   10. Verify that all of the interviews are still there.  Then try
       resuming each session and see if you get any errors.
   11. If you get any errors, report them on [Slack] or [GitHub].
       Internally, **docassemble** uses a function called
       [`recursive_fix_pickle()`] for converting Python 2.7
       pickled objects into Python 3.x objects.  There may be a way to
       adapt this function so that it can make an exception for
       whatever object types are causing problems in your interview.

6. Once all the tests pass, you can upgrade your production server
   in-place by installing the latest versions of your interviews, then
   doing `docker stop`, `docker rm`, `docker pull`, and `docker run`.

[`recursive_fix_pickle()`]: {{ site.github.repository_url }}/blob/master/docassemble_webapp/docassemble/webapp/fixpickle.py
[Slack]: {{ site.slackurl }}
[GitHub]: https://github.com/jhpyle/docassemble/issues
[`docker volume inspect`]: https://docs.docker.com/engine/reference/commandline/volume_inspect/
[data storage]: {{ site.baseurl }}/docs/docker.html#data storage
[persistent volumes]: {{ site.baseurl }}/docs/docker.html#persistent
[S3]: {{ site.baseurl }}/docs/docker.html#persistent s3
[Azure blob storage]: {{ site.baseurl }}/docs/docker.html#persistent azure
[pickle]: https://docs.python.org/3/library/pickle.html
[pickled]: https://docs.python.org/3/library/pickle.html
[`pickle`]: https://docs.python.org/3/library/pickle.html
[writing Python 2-3 compatible code]: https://python-future.org/compatible_idioms.html
[version 0.4.0]: https://github.com/jhpyle/docassemble/releases/tag/v0.4.0
[version 0.5.70]: https://github.com/jhpyle/docassemble/releases/tag/v0.5.70
[version 1.2.0]: https://github.com/jhpyle/docassemble/releases/tag/v1.2.0
[version 1.4.0]: https://github.com/jhpyle/docassemble/releases/tag/v1.4.0
[is no longer maintained]: https://www.python.org/dev/peps/pep-0373/
[pip]: https://pip.pypa.io/en/stable/
[`text_type()`]: {{ site.baseurl }}/docs/functions.html#text_type
[Docker]: {{ site.baseurl }}/docs/docker.html

