WOMBLE - Introduction
=====================
"Make good use of bad rubbish"

[Latest info](http://wiki.github.com/quile/Womble/)

This is a very early commit of a very 
nasty port from Perl of some very old code.

> Don't use this unless you're very brave and/or
> want to help!

This code is under heavy development as of right now,
May 13, 2010.  It is being ported at a fairly rapid rate
from a Perl framework that is stable.  This port can
not be considered stable in any way at all.  However,
hopefully this will change soon.

What is WM?
-----------

WM is based on the web framework and ORM previously
in use at Idealist.org.  The original framework was
developed in-house but heavily influenced by WebObjects
and EOF.  Porting it to Objective-J seemed fitting
and convenient; it also fills a gap in providing
an ORM and web framework written in Objective-J;
something which is currently lacking.

Status
------

The API is in a state of flux.  The code itself 
was partially machine-ported, so it's pretty 
crazy-looking (on top of being based on old, 
crazy-looking Perl).

Currently only the ORM and related functions have
been ported to objj.  Some of the tests have
been copied from perl and recoded verbatim; they're
pretty basic but will show some of the basic
functionality.  Next up in terms of porting will be
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
were still using (and actively encouraging) total rubbish
toolkits like HTML::Mason.

So over the next year or so, the seeds of this code were
sown, in Perl.  Eventually after many years of "code-as-needed"
work, the framework filled itself out.  It diverged in many
ways from its WO/EOF roots, and in greatly inferior in most
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
but will be soon, as it is being EOL'ed within the next
few months and being replaced by a more current Python-based
system.  This obj-j port of the framework is entirely my work;
none of this code is in production, or has been used in any
way whatsoever by my employer. However, I am very thankful
to them for their generous support.



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
I know this is shitty and messy; I don't need anyone else to tell
me that.  The growth of the original framework was very ad-hoc,
and was often driven by the Quick And Dirty Way.  I'm trying to
clean things up but it's still very patchy indeed.
I would love constructive criticism and welcome any help that
anyone would want to throw my way!  It needs a lot of work; clean-up,
optimisation, etc. etc.


-kd may 2010
