package main

import (
	"encoding/json"
	"net/http"
)

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}

func (s *Server) handleGetStudent(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetStudent())
}

func (s *Server) handleGetClassGroups(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetClassGroups())
}

func (s *Server) handleGetNoticeBoard(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetNotices())
}

func (s *Server) handleGetInfoBoard(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetInfoBoard())
}

func (s *Server) handleGetGrades(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetGrades())
}

func (s *Server) handleGetClassGroupAverages(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetAverages())
}

func (s *Server) handleGetTimeTable(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetLessons())
}

func (s *Server) handleGetOmissions(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetOmissions())
}

func (s *Server) handleGetHomework(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetHomework())
}

func (s *Server) handleGetTests(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetTests())
}

func (s *Server) handleGetDktSubjects(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, s.store.GetDktSubjects())
}
