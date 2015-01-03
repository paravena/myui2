MyUI2
===============================
This project is second phase from the one I have begun working two years ago <a href="http://pabloaravena.info">MYUI</a>. Now UI controls are implemented using CoffeeScript and JQuery as main tools and for gluing the code I'm using RequireJS.

Road Map
-------------------------
Soon I will finish the migration from old Prototype to CoffeeScript and JQuery. Following tasks are:

* Optimize and improve event handling
* Replace CSS files with CSS <a href="http://sass-lang.org">Sass</a>
* Make look & feel closer to <a href="http://twitter.github.com/bootstrap/">bootstrap</a>

Steps to build the project
--------------------------------------

* Firstly install <a href="http://nodejs.org">node</a>, then install some nodejs modules:.
<br>
- Begin installing coffee script
<br>
<code>
npm install -g coffee-script
</code>
<br>
- Install sass
<br>
<code>
npm install -g node-sass
</code>
Note : This is not clear yet, it happens that I have installed Ruby and Sass on my system maybe those are also necessary, will see after
<br>
- Now you need to install grunt, the building tool
<br>
<code>
npm install -g grunt-cli
</code>
<br>
<code>
npm install -g grunt-init
</code>
* After installing this global node modules, go to myui2 folder and continue installing local nodejs modules:
<br>
<br>
- Install local grunt module
<br>
<code>
npm install grunt
</code>
<br>
- And finally other modules listed in package.json file
<br>
<code>
npm install
</code>
<br>
* After this you will be able to build the project just by running "grunt" command:
<br>
<code>
grunt
</code>
* And you can open one of the samples in samples folder, as you can see in the picture.

