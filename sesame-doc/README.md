Sesame-doc 
----------

Sesame-doc is a simple command line tool for building simple tutorials and documentation wikis using markdown and the Sesame static site generator. It is largely file layout based with goal of having no configuration files, just command-line options. 

A documentation site can be thought as a set of `sections` which are themselves a set of `pages`. 

```
 - index.md (* Home page *)
   + 1-section
     + index.md (* Landing page for section and metadata about it's pages *)
       * my-nice-tutorial-tm
          + index.md (* Tutorial/document page specified in this file *) 
```

That's it -- there's not much customisability on the layout of the Filesystem. Just a single tree that is 3 levels deep starting at a homepage, a set of sections with each containing pages. 

---

Ideally you only interact with the CLI. If you want to generate a new section: 

```sh
$ sesame-doc new section --content-dir=./content
```

Or for a new page: 

```sh
$ sesame-doc new page --content-dir=./content
```

Both take you through a little questionnaire to get the bare-minimum information need to generate these parts of your site. Also note the `title` to `dirname` function is very simple, so now exotic titles please :) 

To build your site: 

```sh
$ sesame-doc build --content-dir=./content --dist-dir=./dist 
```

Sesame-doc also comes with a server you can use to speed up the development process. To run the server: 

```sh
$ sesame-doc dev --content-dir=./content --dist-dir=./dist 
```
