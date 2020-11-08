let navbar = 
  let open Tyxml in 
  [%html {|
    <div class="header"> 
      <div class="content">
        <nav>
          <ul>
            <li><a href="/sesame/api">API</a></li>
          </ul>
        </nav>
        <div>
          <h1>
            <a href="/sesame">Simple Sesame Static Site</a>
          </h1>
        </div>
      </div>
    </div>
  |}] [@@ocamlformat "disable"]
