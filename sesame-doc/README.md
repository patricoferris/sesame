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

