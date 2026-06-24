// Minimal HTTP service used as the subject of the supply-chain pipeline:
// it is built, SBOM'd, scanned, signed, and attested. No third-party deps,
// so the dependency/OS attack surface (and CVE noise) stays at zero.
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

// version is injected at build time via -ldflags "-X main.version=...".
var version = "dev"

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprintf(w, "supply-chain-demo %s\n", version)
	})

	addr := ":8080"
	if p := os.Getenv("PORT"); p != "" {
		addr = ":" + p
	}

	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("listening on %s (version %s)", addr, version)
	log.Fatal(srv.ListenAndServe())
}
