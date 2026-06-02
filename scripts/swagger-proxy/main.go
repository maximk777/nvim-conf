package main

import (
	"flag"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
)

const swaggerHTML = `<!DOCTYPE html>
<html>
<head>
  <title>Swagger UI</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: "/spec",
      dom_id: "#swagger-ui",
      presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
      layout: "BaseLayout",
    });
  </script>
</body>
</html>`

func main() {
	specFile := flag.String("spec", "", "path to OpenAPI spec file (yaml/json)")
	apiPort := flag.String("port", "8080", "target API port on localhost")
	listen := flag.String("listen", ":9090", "address to listen on")
	flag.Parse()

	if *specFile == "" {
		fmt.Fprintln(os.Stderr, "usage: swagger-proxy --spec <file> --port <api-port>")
		os.Exit(1)
	}

	// Swagger UI page
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			w.Header().Set("Content-Type", "text/html")
			fmt.Fprint(w, swaggerHTML)
			return
		}
		// Proxy everything else to API
		target, _ := url.Parse(fmt.Sprintf("http://localhost:%s", *apiPort))
		proxy := httputil.NewSingleHostReverseProxy(target)
		proxy.ServeHTTP(w, r)
	})

	// Serve the spec file
	http.HandleFunc("/spec", func(w http.ResponseWriter, r *http.Request) {
		data, err := os.ReadFile(*specFile)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if len(data) > 0 && data[0] == '{' {
			w.Header().Set("Content-Type", "application/json")
		} else {
			w.Header().Set("Content-Type", "text/yaml")
		}
		w.Write(data)
	})

	fmt.Printf("Swagger UI: http://localhost%s\n", *listen)
	fmt.Printf("Proxying API to: http://localhost:%s\n", *apiPort)
	if err := http.ListenAndServe(*listen, nil); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
