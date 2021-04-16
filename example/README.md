An OCurrent Pipeline
--------------------

This example shows the flexibility of combining Sesame with [OCurrent](https://github.com/ocurrent/ocurrent). It is a fake reimplementation of the ocaml.org website but building the site from structured data and calls to the Github API (for this you will need a token from Github with at least repo read permissions stored in a file called `.token`).

## Up and running

Getting the site built is as easy as running `dune exec -- ./main.exe`, this will serve two things on two different ports: 

 - `localhost:8080` -- using [`Dream`](https://github.com/aantron/dream) this will statically serve the build folder `ocaml.org`. It also injects some *websocket* magic for [hot-reloading](#hot-reloading).
 - `localhost:8081` -- this is the OCurrent pipeline diagram where you can see how all of the parts fit together and manually rebuild sections if you wish.

### Interesting Pages

 - `index.html` uses the Github release API to get the latest information about `ocaml/ocaml` releases.
 - `changes.html` uses the Github file content API to get the `ocaml/ocaml` changelog, parses it to add PR links and a table of contents.

 ## Hot Reloading

Yep that's right, this example comes with hot-reloading, but how does it work? There are two key components: 

 - [`irmin-watcher`](https://github.com/patricoferris/irmin-watcher/tree/use-fsevents-and-cf): a file watcher (a slightly modified one to work on macOS) which is part of `Current_sesame`. When describing collections you can provide a `~watcher` which registers the filepath with the build `job_id`. Using `Irmin_watcher` whenever a change occurs in the `data` directory, it looks up the `job_id` and if it finds one, calles `rebuild`. 
 - Rebuilding the files is only part of the problem, we also need to dynamically reload the webpage too. To do this `Current_sesame` ships with a small development server which injects a small JS file into every `.html` page. This registers a `websocket` which listens for a call to reload.