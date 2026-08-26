package main

import (
	"embed"
	"flag"
	"io/fs"
	"log"
	"net/http"
)

//go:embed static
var staticFiles embed.FS

type Server struct {
	store *Store
	auth  *AuthStore
}

func main() {
	addr := flag.String("addr", ":8090", "listen address")
	dataPath := flag.String("data", "data.json", "path to the JSON data file")
	flag.Parse()

	s := &Server{
		store: NewStore(*dataPath),
		auth:  NewAuthStore(),
	}

	mux := http.NewServeMux()

	staticContent, err := fs.Sub(staticFiles, "static")
	if err != nil {
		log.Fatal(err)
	}
	mux.Handle("/", http.FileServer(http.FS(staticContent)))

	mux.HandleFunc("/Account/Login", s.handleAccountLogin)
	mux.HandleFunc("/ellenorzo-student/prod/oauthredirect", s.handleOauthRedirect)
	mux.HandleFunc("/connect/token", s.handleToken)

	mux.HandleFunc("/ellenorzo/v3/sajat/TanuloAdatlap", s.requireAuth(s.handleGetStudent))
	mux.HandleFunc("/ellenorzo/v3/sajat/OsztalyCsoportok", s.requireAuth(s.handleGetClassGroups))
	mux.HandleFunc("/ellenorzo/v3/sajat/FaliujsagElemek", s.requireAuth(s.handleGetNoticeBoard))
	mux.HandleFunc("/ellenorzo/v3/sajat/Feljegyzesek", s.requireAuth(s.handleGetInfoBoard))
	mux.HandleFunc("/ellenorzo/v3/sajat/Ertekelesek", s.requireAuth(s.handleGetGrades))
	mux.HandleFunc("/ellenorzo/v3/sajat/Ertekelesek/Atlagok/OsztalyAtlagok", s.requireAuth(s.handleGetClassGroupAverages))
	mux.HandleFunc("/ellenorzo/v3/sajat/OrarendElemek", s.requireAuth(s.handleGetTimeTable))
	mux.HandleFunc("/ellenorzo/v3/sajat/Mulasztasok", s.requireAuth(s.handleGetOmissions))
	mux.HandleFunc("/ellenorzo/v3/sajat/HaziFeladatok", s.requireAuth(s.handleGetHomework))
	mux.HandleFunc("/ellenorzo/v3/sajat/BejelentettSzamonkeresek", s.requireAuth(s.handleGetTests))
	mux.HandleFunc("/dktapi/intezmenyek/munkaterek/tanulok", s.requireAuth(s.handleGetDktSubjects))

	s.registerAdminRoutes(mux)

	log.Printf("mock kreta server listening on %s (data: %s)", *addr, *dataPath)
	log.Fatal(http.ListenAndServe(*addr, logRequests(mux)))
}

func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s from %s", r.Method, r.URL.String(), r.RemoteAddr)
		next.ServeHTTP(w, r)
	})
}
