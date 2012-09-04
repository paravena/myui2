MYUI2
===============================
This project is second phase from the one I have begun working two years ago <a href="http://pabloaravena.info">MYUI</a>. Now UI controls are implemented using CoffeeScript and JQuery as main tools and for gluing the code I'm using RequireJS.

Route Map
-------------------------
Soon I will finish the migration from old Prototype to CoffeeScript and JQuery. Following tasks are:

* Optimize and improve event handling
* Replace CSS files with CSS <a href="lesscss.org">Less</a>
* Include CSS Less files in RequireJS optimize process
* Make look & feel closer to <a href="http://twitter.github.com/bootstrap/">bootstrap</a>

Steps to build the project
--------------------------------------

* Download node 
* execute following command:
<br>
<code>
node r.js -o build.scripts.js
</code>
<br>
<code>
node r.js -o build.css.js
</code>


Samples
--------
This is a first sample you can review <a href="http://jsfiddle.net/paravena/Cysu8/embedded/result,js,html/">here</a>


