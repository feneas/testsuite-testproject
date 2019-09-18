package main

import (
  "net/http"
  "log"
  "os"
  "fmt"
)

func main() {
  http.HandleFunc("/send", func(w http.ResponseWriter, r *http.Request) {
    log.Printf("%s %s\n", r.Method, r.URL.String())

    _, err := http.Get(r.URL.RawQuery)
    if err != nil {
      fmt.Fprintf(w, "%s\n", err.Error())
    } else {
      fmt.Fprintf(w, "ok\n")
    }
  })

  http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
    log.Printf("%s %s\n", r.Method, r.URL.String())

    fmt.Fprintf(w, "pong\n")
  })

  listening := ":8080"
  if len(os.Args) > 1 {
    listening = os.Args[1]
  }
  log.Printf("Listening on %s..\n", listening)
  log.Fatal(http.ListenAndServe(listening, nil))
}
