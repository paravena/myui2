MyUI2
===============================
This project is second phase from the one I have begun working two years ago <a href="http://pabloaravena.info">MYUI</a>. Now UI controls are implemented using CoffeeScript and JQuery as main tools and for gluing the code I'm using RequireJS.

Road Map
-------------------------
Soon I will finish the migration from old Prototype to CoffeeScript and JQuery. Following tasks are:

* Optimize and improve event handling
* Replace CSS files with CSS <a href="http://sass-lang.org">Sass</a>
* Include CSS Sass files in RequireJS optimize process
* Make look & feel closer to <a href="http://twitter.github.com/bootstrap/">bootstrap</a>

Steps to build the project
--------------------------------------

* Download <a href="http://nodejs.org">node</a>, then install some plugins, like coffee-script and sass.

<code>
npm install -g coffee-script
</code>
<br>
<code>
npm install -g node-sass
</code>
* execute the following commands:
<br>
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
* This is a first sample, you can review it <a href="http://jsfiddle.net/paravena/Cysu8/embedded/result,js,html/">here</a>

* Second sample showing nested header columns, you can review it <a href="http://jsfiddle.net/paravena/3raSc/4/embedded/result,js,html/">here</a>


