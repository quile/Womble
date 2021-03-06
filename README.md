WOMBLE - Introduction
=====================
Wombling: "Making good use of bad rubbish"

[Latest info](http://wiki.github.com/quile/Womble/)

> Feel free to help out!  There's a lot of work to be done...

This code is under active development as of right now,
January 19th, 2011.  It is being ported at a fairly rapid rate
from a Perl framework that is stable.  This port can
not be considered stable in any way at all.  However,
hopefully this will change soon.

Status
------
* Most of the core functionality of the ORM is working, although
  only for SQLite right now.  I need to port the MySQL driver.
* I am working pretty hard to get the basic component rendering
  parts of the framework up and running.  Once the guts are
  working (hopefully soon) I'll be able to hook it into
  Jack/Node/JSGI easily.
* Even when the web rendering stuff is working, it will not
  be particularly optimised.  There is quite a bit of old
  baggage in the code (some of which I am removing during
  the port) which will slow it down needlessly.  There's
  also a fair amount of unoptimised code, mainly due to the
  nature of the port.  Fixing that will come later.
* I'm slowly but surely removing code that was needed in the Perl
  version, but is obviated by something the Cocoa-esque
  Cappuccino/Objective-J frameworks.  A good example of this
  is that we can now use Cocoa-style bundles to load app resources,
  so we can do away with a lot of the complicated search/resolution
  paths that were required in the perl version.


What is WM?
-----------

WM is based on the web framework and ORM previously
in use at my employer.  The original framework was
developed in-house but heavily influenced by WebObjects
and EOF.  Porting it to Objective-J seemed fitting
and convenient; it also fills a gap in providing
an ORM and web framework written in Objective-J;
something which is currently lacking.

Why?
----

Because I want to use Objective-J, and I tend to work on server-side
projects.  Because I want to build my own projects in Objective-J
and deploy them easily on Google App Engine.  Because it's fun.
There's not necessarily anything revolutionary about this project
and it's not going to break down walls or convert Python programmers
to a good language.


The Port
--------

The API is in a state of flux.  The code itself
was partially machine-ported, so it's pretty
crazy-looking (on top of being based on old,
crazy-looking Perl).

Currently most of the ORM and related functions have
been ported to objj.  Some of the tests have
been copied from perl and recoded verbatim; they're
pretty basic but will show some of the basic
functionality.  I'm currently working hard
to port the component-based web framework.  Anyone
familiar with WebObjects, Seaside or Tapestry will
be at home with it; hopefully as I learn more about
the Javascript runtime, I'll be able to take advantage
of it to make the web development cycle more productive
and fun.


Background
==========
In 2000, WebObjects and EOF were state-of-the-art tools
for building advanced web applications.  Apple was in
a state of flux, and had signed a pact with the devil
to port WO/EOF to Java, and EOL the obj-c (& webscript)
version of these great tools.  WebObjects was not free;
it was $700 or so, and if I remember right there were some
fancy deployment licensing issues.  When I started
working for a tiny non-profit with no real budget and
an existing site in Perl/CGI, I did my best to structure
new development on models I was familiar with --
from WO/EOF.  This was 10 years ago and there weren't very many
useful tools around at the time in Perl; there was certainly
no ORM even close to the power of EOF (there still isn't
but there are some that will do the job).  There was
no decent component-based web framework, and people
were still using (and actively encouraging) total shite
toolkits like HTML::Mason.

So over the next year or so, the seeds of this code were
sown, in Perl.  Eventually after many years of "code-as-needed"
work, the framework filled itself out.  It diverged in many
ways from its WO/EOF roots, and is greatly inferior in most
ways.  There are numerous soft-spots and bugs; those are
avoided and worked around in our application code because
we know where they are; We have very poor test coverage and
what tests we do have were mostly written years ago and
are not up-to-date in terms of testing methodology.

A small non-profit generally doesn't have the luxury of
building large teams of coders, using fancy programming
methodologies and spending money and time on things
unless they're absolutely necessary.  This has forced us to
cut a lot of corners, but the good side-effect of
coding-to-necessity is that we actually launch code; we
can't afford not to.

The perl version of this framework is not (yet) open source,
but will be soon, as it has been EOL'ed replaced by a 
more current Python-based system.  This obj-j port of 
the framework is entirely my work; none of this code has 
been used in any way whatsoever by my employer.



DISCLAIMER
==========

This is rough.  A lot of it is half-arsed.  It's currently
a half-arsed port of a half-arsed implementation of some
cool tools.  I'd love to clean it up and make it less-half-arsed
but I am doing this on my own time and I can't make any promises!


HELP
====
Any/all help would be greatly appreciated; I realise it's
a pretty big ask.  But if anyone out there is brave enough
to give it a try, I'd be happy to help out.
I know this is messy; I don't need anyone else to tell
me that.  The growth of the original framework was very ad-hoc,
and was often driven by the Quick And Dirty Way.  I'm trying to
clean things up but it's still very patchy indeed.
I would love constructive criticism and welcome any help that
anyone would want to throw my way!  It needs a lot of work; clean-up,
optimisation, etc. etc.


-kd may 2010
* Updated Nov 2, 2010
