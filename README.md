#MyUI2

This project is second phase from the one I have begun working two years ago <a href="http://pabloaravena.info">MYUI</a>. Now UI controls are implemented using CoffeeScript and JQuery as main tools and for gluing the code I'm using RequireJS.

##Road Map

Soon I will finish the migration from old Prototype to CoffeeScript and JQuery. Following tasks are:

* Optimize and improve event handling
* Replace CSS files with CSS <a href="http://sass-lang.org">Sass</a>
* Make look & feel closer to <a href="http://twitter.github.com/bootstrap/">bootstrap</a>

##Steps to build the project

* Firstly Make sure you have installed Ruby language in your computer, which will be available by default if you have Mac
<br>
* After this install sass gem, as follows:
<br>
<code>
gem install sass
</code>
<br>
* Now install <a href="http://nodejs.org">NodeJS</a>:.
<br>
<br>
* Then execute command npm install, which will install the modules defined in package.json file
<br>
<br>
<code>
npm install
</code>
<br>
<br>
* Install the following modules globally using npm command (sometime you need to prepend sudo command):
<br>
<br>
<code>
npm install -g coffee-script
</code>
<br>
<br>
<code>
npm install -g grunt-cli
</code>
<br>
<br>
* After this you will be able to build the project just by running "grunt" command:
<br>
<br>
<code>
grunt
</code>
<br>
<br>
* Now you can see a live sample of this on https://paravena.github.io/myui2
<br>
<br>

