module.exports = function(grunt) {
    grunt.initConfig({
        pkg : grunt.file.readJSON('package.json'),
        coffee : {
            options: {
                bare: true
            },
            compile : {
                files : {
                    'dist/myui.js' : ['src/**/Util.coffee',
                        'src/**/Util.coffee',
                        'src/**/i18n.coffee',
                        'src/**/Date.coffee',
                        'src/**/ToolTip.coffee',
                        'src/**/Checkbox.coffee',
                        'src/**/RadioButton.coffee',
                        'src/**/TextField.coffee',
                        'src/**/BrowseInput.coffee',
                        'src/**/Autocompleter.coffee',
                        'src/**/ComboBox.coffee',
                        'src/**/DatePicker.coffee',
                        'src/**/KeyTable.coffee',
                        'src/**/TableGrid.coffee',
                        'src/myui.coffee']
                }
            }
        },
        sass: {
            dist: {
                options: {
                    style: 'compressed'
                },
                files: {
                    'dist/<%= pkg.name %>.min.css': 'src/css/myui/myui.scss'
                }
            }
        },
        copy : {
            cssImages: {
                files : [
                    {
                        cwd : 'src/css/myui/images/',
                        src : '*',
                        dest : 'dist/images/',
                        expand : true
                    },
                    {
                        cwd : 'src/css/myui/images/',
                        src : '*',
                        dest : 'public/assets/css/images',
                        expand : true
                    }
                ]
            },
            libs : {
                files : [
                    {
                        cwd : 'dist',
                        src : 'myui.min.js',
                        dest : 'public/assets/js',
                        expand : true
                    },
                    {
                        cwd : 'dist',
                        src : 'myui.min.css',
                        dest : 'public/assets/css',
                        expand : true
                    }
                ]
            }
        },
        uglify : {
            options: {
                banner: '/* <%= pkg.name %>, version 1.0 \n' +
                ' * \n' +
                ' * Dual licensed under the MIT and GPL licenses. \n' +
                ' * \n' +
                ' * Copyright <%= grunt.template.today("yyyy-mm-dd") %> <%= pkg.author %>, all rights reserved. \n' +
                ' * <%= pkg.website %> \n' +
                ' * \n' +
                ' * Permission is hereby granted, free of charge, to any person obtaining a copy \n' +
                ' * of this software and associated documentation files (the "Software"), to deal \n' +
                ' * in the Software without restriction, including without limitation the rights \n' +
                ' * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \n' +
                ' * copies of the Software, and to permit persons to whom the Software is \n' +
                ' * furnished to do so, subject to the following conditions: \n' +
                ' * \n' +
                ' * The above copyright notice and this permission notice shall be included in \n' +
                ' * all copies or substantial portions of the Software. \n' +
                ' * \n' +
                ' * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \n' +
                ' * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \n' +
                ' * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE \n' +
                ' * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \n' +
                ' * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \n' +
                ' * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN \n' +
                ' * THE SOFTWARE. \n' +
                ' */\n'
            },
            build: {
                src: 'dist/<%= pkg.name %>.js',
                dest: 'dist/<%= pkg.name %>.min.js'
            }
        }
    });
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-sass');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.registerTask('default', ['coffee','uglify', 'sass', 'copy']);
    //grunt.registerTask('default', ['coffee','sass', 'copy']);
};