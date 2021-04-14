An OCurrent Pipeline
--------------------

This small example shows the flexibility of combining Sesame with [OCurrent](https://github.com/ocurrent/ocurrent). It is a fake reimplementation of the ocaml.org website but building the site from structured data and calls to the Github API (for this you will need a token from Github with at least repo read permissions stored in a file called `.token`). 

This example happens to save all of the files to static HTML, but there's nothing stopping you from collecting everything at the end and putting a dynamic server there (such as [Dream](https://github.com/aantron/dream)).

To run it you can do 

```
dune exec -- ./main.exe
```

from one terminal. This starts the pipeline for building the site. Then from a second terminal: 

```
cohttp-server-lwt -p 8081 ocaml.org
```

You can see the live site at `localhost:8081` and the pipeline that builds it (which you can re-trigger) at `localhost:8080`.